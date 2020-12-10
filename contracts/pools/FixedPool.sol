// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./IPool.sol";
import "../token/IERC20.sol";
import "../math/SafeMath.sol";
import "../utils/Context.sol";
import "./GeneratePoolInfo.sol";

/*
 固定价格拍卖池 
 @dev 固定价格适合ERC20 Token
*/
contract FixedPool is Context, IPool {
    using SafeMath for uint256;
    GeneratePoolInfo _poolInfo;
    address payable _feeAddress;

    AuctionRecord[] private _records;

    //参与记录
    struct AuctionRecord {
        address participator; // 参与者地址
        uint256 swapQty; // 兑换的fromToken数量
        uint256 toTokenQty; // 用于兑换的toToken的数量
        uint256 swapFee; // 兑换手续费（仅收取拍卖者收到的toToken）
        uint256 joinAt; // 参与时间
    }

    constructor(
        bytes32 name,
        uint256 poolType,
        address payable creator,
        address payable feeAddress,
        address fromToken,
        uint256 fromTokenQty,
        bool onlyBat,
        address toToken,
        uint256 swapRatio,
        uint256 swapDecimals,
        uint256 duration,
        bytes32 url1,
        bytes32 url2
    ) public {
        _feeAddress = feeAddress;
        _poolInfo = GeneratePoolInfo(
            name,
            poolType,
            creator,
            fromToken,
            fromTokenQty,
            onlyBat,
            toToken,
            swapRatio,
            swapDecimals,
            0,
            block.timestamp,
            duration,
            url1,
            url2,
            0,
            0,
            0,
            0
        );
    }

    //查询拍卖池信息接口
    function getPoolInfo()
        external
        override
        view
        returns (
            bytes32 name,
            uint256 poolType,
            address creator,
            address fromToken,
            uint256 fromTokenQty,
            bool onlyBat,
            address toToken,
            uint256 swapRatio,
            uint256 createAt,
            uint256 duration,
            bytes32 url1,
            bytes32 url2
        )
    {
        return (
            _poolInfo.name,
            _poolInfo.poolType,
            _poolInfo.creator,
            _poolInfo.fromToken,
            _poolInfo.fromTokenQty,
            _poolInfo.onlyBat,
            _poolInfo.toToken,
            _poolInfo.swapRatio,
            _poolInfo.createAt,
            _poolInfo.duration,
            _poolInfo.url1,
            _poolInfo.url2
        );
    }

    /// @notice 查询拍卖池拍卖Token信息
    /// @return fromToken 拍卖的Token
    /// @return fromTokenQty 拍卖币种的数量
    /// @return swapRatio 拍卖池兑换比例
    function getPoolTokenInfo()
        external
        override
        view
        returns (
            address fromToken,
            uint256 fromTokenQty,
            uint256 swapRatio,
            address toToken
        )
    {
        return (
            _poolInfo.fromToken,
            _poolInfo.fromTokenQty,
            _poolInfo.swapRatio,
            _poolInfo.toToken
        );
    }

    //查询拍卖池扩展信息接口
    function getPoolExtInfo()
        external
        override
        view
        returns (
            uint256 uintExt1,
            uint256 uintExt2,
            uint256 uintExt3,
            uint256 uintExt4
        )
    {
        return (
            _poolInfo.uintExt1,
            _poolInfo.uintExt2,
            _poolInfo.uintExt3,
            _poolInfo.uintExt4
        );
    }

    //需要一个参与记录的查询接口
    // cursor 表示用户参与的排位
    function getJoinRecord(address participator, int256 cursor)
        external
        view
        returns (
            uint256 joinIndex,
            uint256 swapQty,
            uint256 toTokenQty,
            uint256 swapFee,
            uint256 joinAt
        )
    {
        for (uint256 index = 0; index < _records.length; index++) {
            if (int256(index) <= cursor) continue;
            AuctionRecord memory record = _records[index];
            if (participator == record.participator) {
                return (
                    index,
                    record.swapQty,
                    record.toTokenQty,
                    record.swapFee,
                    record.joinAt
                );
            }
        }

        return (0, 0, 0, 0, 0);
    }

    //是否只支持平台币持有者
    function isOnlyAllowBatHolder() external override view returns (bool) {
        return _poolInfo.onlyBat;
    }

    event LogU(string s, uint256 v);

    //参与拍卖接口
    function join(
        address participator,
        uint256 autionFeeRate,
        uint256 toTokenQty
    )
        external
        override
        payable
        returns (bool joinSucceed, uint256 chargeFeeOfToToken)
    {
        // 不能超出拍卖池的有效期
        require(
            block.timestamp <=
                _poolInfo.createAt.add(_poolInfo.duration.mul(1 seconds)),
            "expired pool"
        );
        uint256 fromTokenDecimals = IERC20(_poolInfo.fromToken).decimals();
        // 可以兑换的fromToken数量
        uint256 shouldSwapQty = toTokenQty
            .mul(_poolInfo.swapRatio)
            .mul(10**fromTokenDecimals)
            .div(10**(_poolInfo.swapDecimals.add(18)));
        require(shouldSwapQty > 0, "shouldSwapQty should gt 0");
        //判断是否足够兑换,uintExt1代表已经兑换掉的fromTokenQty
        _poolInfo.fromTokenQty.sub(_poolInfo.uintExt1).sub(
            shouldSwapQty,
            "insufficient fromToken Qty"
        );
        //增加已经兑换掉的fromTokenQty
        _poolInfo.uintExt1 = _poolInfo.uintExt1.add(shouldSwapQty);
        //写入参与记录
        uint256 swapFee;
        //计算参与手续费,并把扣除手续费后的toToken转给拍卖者
        if (address(0x0) == _poolInfo.toToken) {
            uint256 etherAmount = msg.value;
            //如果是Ether
            swapFee = etherAmount.mul(autionFeeRate).div(10000);
            _poolInfo.creator.transfer(etherAmount.sub(swapFee));
            _feeAddress.transfer(swapFee);
        } else {
            //如果是ERC20
            swapFee = toTokenQty.mul(autionFeeRate).div(10000);
            IERC20(_poolInfo.toToken).transferFrom(
                _msgSender(),
                _poolInfo.creator,
                toTokenQty.sub(swapFee)
            );
            IERC20(_poolInfo.toToken).transferFrom(
                _msgSender(),
                _feeAddress,
                swapFee
            );
        }
        AuctionRecord memory record = AuctionRecord(
            participator,
            shouldSwapQty,
            toTokenQty,
            swapFee,
            block.timestamp
        );

        //判断转入的ETH数量
        _records.push(record);
        //把兑换成功的token转给参与者
        //仍然需要transferFrom来执行
        //_msgSender代表主合约
        IERC20(_poolInfo.fromToken).transferFrom(
            _msgSender(),
            participator,
            shouldSwapQty
        );

        return (true, swapFee);
    }

    function getRemainQty() external override view returns (uint256) {
        return _getRemainQty();
    }

    function _getRemainQty() internal view returns (uint256) {
        return _poolInfo.fromTokenQty.sub(_poolInfo.uintExt1);
    }

    function claimRemainToken() external override returns (bool) {
        bool expired = _poolInfo.createAt.add(
            _poolInfo.duration.mul(1 seconds)
        ) < block.timestamp;
        // uintExt1 代表 [1. FixedPool.swapedQty 已兑换数量(fromToken)]

        require(expired, "pool is live");
        require(_poolInfo.fromTokenQty > _poolInfo.uintExt1, "pool was filled");
        require(_poolInfo.uintExt2 == 0, "Areadly claimRemainToken");

        uint256 remainQty = _getRemainQty();
        IERC20(_poolInfo.fromToken).transferFrom(
            _msgSender(), //#从主合约中转出
            _poolInfo.creator,
            remainQty
        );
        //FixedPool的uintExt2 代表 已经取出的未被拍卖掉的token
        _poolInfo.uintExt2 = remainQty;
    }
}
