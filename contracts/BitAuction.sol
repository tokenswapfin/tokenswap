// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./token/IERC20.sol";
import "./token/IERC721.sol";
import "./token/IERC777.sol";
import "./token/IERC1155.sol";
import "./pools/IPool.sol";
import "./IBitAuction.sol";
import "./utils/Context.sol";
import "./pools/FixedPool.sol";
import "./Dtos/UserFeeRecord.sol";
import "./Dtos/ClaimRecord.sol";

contract BitAuction is Context, IBitAuction {
    using SafeMath for uint256;
    address private _owner; // 主合约创建者
    IERC20 _mainToken; // 平台币ERC20 Token地址
    address payable _feeAddress; // 拍卖手续费进入哪个地址
    uint256 private _daliyMiningQty; // 每日挖矿释放数量
    uint256 private _autionFeeRate; // 拍卖费率(实际费率 * 10000 为了保持uint256计算兼容,意味着费率最低可以设置到万分之一)
    uint256 private _stakingPercent; // staking释放手续费的比例
    uint256 private _createAutionFee; // 创建拍卖池的费用（平台币）
    uint256 private _swapDecimals; // 兑换比例支持的最大小数位
    uint256 private _createAt; // 主合约创建时间
    uint256 private _miningPeriod; // 参与即挖矿的奖励周期 --暂时按照固定24小时的周期
    bool private _enable; // 是否启用拍卖合约，不允许创建Pool和参与

    UserFeeRecord[] private _userFeeRecords; //用户产生的费用记录
    ClaimRecord[] private _claimRecords; //用户领取挖矿奖励记录
    IPool[] private _pools; //所有的拍卖池数组

    constructor(IERC20 token, address payable feeAddr) public {
        _feeAddress = feeAddr;
        _mainToken = token;
        _owner = _msgSender();
        _createAt = block.timestamp;
        _swapDecimals = 10; //不可随意调整，调整需要注意swapRatio填入的数字位数
    }

    function getPoolInfo(uint256 poolId)
        external
        override
        view
        returns (
            bytes32, //name
            uint256, //poolType
            address, //creator
            address, //fromToken
            uint256, //fromTokenQty
            bool, //onlyBat
            address, //toToken
            uint256, //swapRatio
            uint256, //createAt
            uint256, //duration
            bytes32, //url1
            bytes32 //url2
        )
    {
        require(poolId < _pools.length, "invlid poolId");

        IPool pool = _pools[poolId];

        return pool.getPoolInfo();
    }

    function getPoolExtInfo(uint256 poolId)
        external
        override
        view
        returns (
            uint256, //uintExt1
            uint256, //uintExt2
            uint256, //uintExt3
            uint256 //uintExt4
        )
    {
        require(poolId < _pools.length, "invlid poolId");

        IPool pool = _pools[poolId];

        return pool.getPoolExtInfo();
    }

    function createPool(
        bytes32 name,
        uint256 poolType,
        address fromToken,
        uint256 fromTokenQty,
        bool onlyBat,
        address toToken,
        uint256 swapRatio,
        uint256 durationSeconds,
        bytes32 url1,
        bytes32 url2
    ) external override returns (bool) {
        // 判断fromToken是否是合法的Erc20
        require(IERC20(fromToken).balanceOf(_msgSender()) > 0, "invalid erc20");
        checkIfMaintaining();
        // 发起拍卖Pool，需要把拍卖的Token转到Pool上
        require(
            IERC20(fromToken).transferFrom(
                _msgSender(),
                address(this),
                fromTokenQty
            ),
            "transfer token failed"
        );

        /*拍卖池类型
            Fixed 1 固定价格拍卖
            DutchSystem 2 荷兰式拍卖；动态价格拍卖  
            EnglishSystem 3 英格兰拍卖；价格高者得，可以通过设置底价，设置时，最终拍卖价格低于底价则流拍
            enum PoolType {  Fixed, DutchSystem ,EnglishSystem }
            可升级合约不可用使用枚举类型
        */

        if (poolType == uint256(1)) {
            FixedPool fixedPool = new FixedPool(
                name,
                poolType,
                _msgSender(),
                _feeAddress,
                fromToken,
                fromTokenQty,
                onlyBat,
                toToken,
                swapRatio,
                _swapDecimals,
                durationSeconds,
                url1,
                url2
            );

            _pools.push(fixedPool);

            return true;
        }
        return false;
    }

    //参与拍卖
    function join(uint256 poolId, uint256 toTokenQty)
        external
        override
        payable
        returns (bool)
    {
        require(poolId < _pools.length, "invlid poolId");
        checkIfMaintaining();
        IPool pool = _pools[poolId];
        if (pool.isOnlyAllowBatHolder()) _onlyBatHolder();
        (address fromToken, , uint256 swapRatio, address toToken) = pool
            .getPoolTokenInfo();

        uint256 realToTokenQty = toTokenQty;

        if (toToken == address(0x0)) {
            realToTokenQty = msg.value;
        }

        uint256 fromTokenDecimals = IERC20(fromToken).decimals();
        uint256 shouldSwapQty = toTokenQty
            .mul(swapRatio)
            .mul(10**fromTokenDecimals)
            .div(10**(_swapDecimals.add(18)));

        require(realToTokenQty > 0, "insufficient pay amount");

        IERC20(fromToken).approve(address(pool), shouldSwapQty);

        (bool joinResult, uint256 swapFee) = pool.join{value: msg.value}(
            _msgSender(),
            _autionFeeRate,
            toTokenQty
        );

        if (joinResult == true) {
            //记录交易费用
            UserFeeRecord memory record = UserFeeRecord(
                poolId,
                _msgSender(),
                realToTokenQty,
                swapFee,
                block.timestamp
            );
            _userFeeRecords.push(record);
        }
        return joinResult;
    }

    function claimRemainToken(uint256 poolId) external override returns (bool) {
        //从pool中领取
        require(poolId < _pools.length, "invlid poolId");
        checkIfMaintaining();
        IPool pool = _pools[poolId];
        (address fromToken, , , ) = pool.getPoolTokenInfo();

        uint256 remainQty = pool.getRemainQty();

        if (remainQty > 0) {
            IERC20(fromToken).approve(address(pool), remainQty);
        }

        bool claimSucceed = pool.claimRemainToken();
        return claimSucceed;
    }

    function getStatus()
        external
        override
        view
        returns (
            uint256 daliyMiningQty,
            uint256 autionFeeRate,
            uint256 stakingPercent,
            uint256 createAutionFee,
            uint256 poolCount,
            uint256 autionFeeSum,
            uint256 tokenRelease,
            uint256 autionEtherSum,
            address feeAddr,
            uint256 miningPeriod,
            bool enable
        )
    {
        for (uint256 index = 0; index < _userFeeRecords.length; index++) {
            UserFeeRecord memory feeRecord = _userFeeRecords[index];
            autionFeeSum = autionFeeSum.add(feeRecord.fee);
            autionEtherSum = tokenRelease.add(feeRecord.amount);
        }

        for (uint256 i = 0; i < _claimRecords.length; i++) {
            ClaimRecord memory claimRecord = _claimRecords[i];
            tokenRelease.add(claimRecord.reward);
        }
        return (
            _daliyMiningQty,
            _autionFeeRate,
            _stakingPercent,
            _createAutionFee,
            _pools.length,
            autionFeeSum,
            tokenRelease,
            autionEtherSum,
            _feeAddress,
            _miningPeriod,
            _enable
        );
    }

    function updateSetting(
        uint256 daliyMiningQty,
        uint256 autionFeeRate,
        uint256 stakingPercent,
        uint256 createAutionFee,
        address payable feeAddr,
        uint256 miningPeriod,
        bool enable
    ) external override returns (bool) {
        require(msg.sender == _owner, "no permission");
        _daliyMiningQty = daliyMiningQty;
        _autionFeeRate = autionFeeRate;
        _stakingPercent = stakingPercent;
        _createAutionFee = createAutionFee;
        _feeAddress = feeAddr;
        _miningPeriod = miningPeriod * 1 hours;
        _enable = enable;
    }

    function getUserRewardQty(address userAddr, uint256 periodAgo)
        external
        override
        view
        returns (
            bool exist,
            uint256 rewardAmount,
            uint256 period,
            uint256 canClaimAt,
            bool claimed
        )
    {
        return _getUserRewardQty(userAddr, periodAgo);
    }

    //获得用户的可领取挖矿金额
    //@param userAddr 用户的地址
    //@param daysAgo 获取用户相对于
    //@return rewardAmount 奖励金额
    //@return period 第几个奖励周期
    //@return bool 是否已领取

    function _getUserRewardQty(address userAddr, uint256 periodAgo)
        internal
        view
        returns (
            bool exist,
            uint256 rewardAmount,
            uint256 period,
            uint256 canClaimAt,
            bool claimed
        )
    {
        if (_miningPeriod == 0) return (false, 0, 0, 0, false);
        //根据当前的block.timestamp找出用户的挖矿所得金额(昨日)
        uint256 timespan = block.timestamp.sub(_createAt);
        uint256 pastPeriod = periodAgo.mul(_miningPeriod); //向前跳多久（根据跳过的周期计算）

        uint256 crtStart = _createAt
            .add(uint256(timespan.div(_miningPeriod)).mul(_miningPeriod))
            .sub(pastPeriod);
        uint256 crtEnd = _createAt
            .add(uint256(timespan.div(_miningPeriod)).mul(_miningPeriod))
            .add(_miningPeriod)
            .sub(pastPeriod);
        if (crtStart < _createAt) return (false, 0, 0, 0, claimed);
        uint256 thePeriod = uint256(crtStart.sub(_createAt).div(_miningPeriod)); //查询的是第几个周期
        uint256 totalFee; // 前一天手续费合计
        uint256 userFee; // 当前用户贡献手续费合计
        //倒序循环，统计前一天
        for (
            int256 index = int256(_userFeeRecords.length - 1);
            index >= int256(0);
            index--
        ) {
            UserFeeRecord memory record = _userFeeRecords[uint256(index)];
            if (record.createAt > crtEnd) continue;
            if (record.createAt < crtStart) break;
            totalFee = totalFee.add(record.fee);
            if (record.userAddr == userAddr) userFee = userFee.add(record.fee);
        }
        claimed = false;
        //发放之前要检查之前是否发放过
        if (_claimRecords.length > 0) {
            for (
                int256 index = int256(_claimRecords.length - 1);
                index >= int256(0);
                index--
            ) {
                ClaimRecord memory existRecord = _claimRecords[uint256(index)];
                //超过一个周期以前的可以忽略掉，避免过量循环
                if (existRecord.createAt < block.timestamp.sub(_miningPeriod))
                    break;
                if (
                    existRecord.userAddr == userAddr &&
                    existRecord.period == thePeriod
                ) {
                    claimed = true;
                    break;
                }
            }
        }
        if (userFee > 0) {
            uint256 userRewardQty = userFee
                .mul(10**18)
                .div(totalFee)
                .mul(_daliyMiningQty)
                .div(10**18);

            return (
                true,
                userRewardQty,
                thePeriod,
                _createAt.add(thePeriod.add(1).mul(_miningPeriod)),
                claimed
            );
        } else
            return (
                false,
                0,
                thePeriod,
                _createAt.add(thePeriod.add(1).mul(_miningPeriod)),
                claimed
            );
    }

    function claimMiningReward() external override returns (bool) {
        checkIfMaintaining();
        address userAddr = _msgSender();
        //获得用户的可领取金额(前一天的)
        (
            ,
            uint256 rewardQty,
            uint256 period,
            ,
            bool claimed
        ) = _getUserRewardQty(userAddr, 1);
        if (claimed == true) revert("claimed");
        require(rewardQty > 0, "reward amount lt 0");
        require(
            IERC20(_mainToken).balanceOf(address(this)) >= rewardQty,
            "insufficient reward token"
        );

        //转账平台币到用户的地址
        IERC20(_mainToken).transfer(userAddr, rewardQty);

        //记录claimRecord
        ClaimRecord memory record = ClaimRecord(
            userAddr,
            rewardQty,
            period,
            block.timestamp
        );

        _claimRecords.push(record);
    }

    //检查是否是Bat平台币的持有者
    function _onlyBatHolder() internal view returns (bool) {
        uint256 mainTokenBalance = IERC20(_mainToken).balanceOf(_msgSender());
        require(mainTokenBalance > 0, "only bat holder");
    }

    function checkIfMaintaining() internal view {
        require(_enable, "maintaining");
    }

    function moveMainTokenToNewVersion(
        address token,
        address payable newVersionContract
    ) external override returns (bool) {
        require(msg.sender == _owner, "no permission");

        if (token == address(0x0)) {
            uint256 etherBalance = address(this).balance;
            if (etherBalance > 0) newVersionContract.transfer(etherBalance);
        } else {
            uint256 erc20Balance = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(newVersionContract, erc20Balance);
        }
    }

    receive() external payable {}
}
