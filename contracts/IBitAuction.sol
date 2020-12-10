// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// 拍卖池主接口
interface IBitAuction {
    /// @notice 查询拍卖池信息接口
    /// @return name 拍卖池名称(bytes32来存储string，最大支持32个字符)
    /// @return poolType 拍卖池类型
    /// @return creator 拍卖池创建人
    /// @return fromToken 拍卖的Token
    /// @return fromTokenQty 拍卖币种的数量
    /// @return onlyBat 是否仅持有平台的用户可以参与
    /// @return toToken 拍卖池计价Token
    /// @return swapRatio 拍卖池兑换比例
    /// @return createAt 拍卖池创建时间
    /// @return duration 拍卖持续时间
    /// @return url1 项目介绍url-第一段
    /// @return url2 项目介绍url-第二段
    function getPoolInfo(uint256 poolId)
        external
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
        );

    /// @notice 查询拍卖池扩展信息接口
    /// @return uintExt1 扩展返回uint字段1
    ///           [1. FixedPool.swapedQty 已兑换数量(fromToken)]
    ///           [2. DutchSystemPool.toTokenTotalQty 已注入的toToken数量(toToken)]
    ///           [3. EnglishSystemPool.maxToTokenQty 最高出价数量(toToken)]
    /// @return uintExt2 扩展返回uint字段2
    ///           [1. FixedPool 暂时无用途]
    ///           [2. DutchSystemPool 暂时无用途]
    ///           [3. EnglishSystemPool.startRatio 拍卖底价]
    /// @return uintExt3 扩展返回uint字段3 预留扩展
    /// @return uintExt4 扩展返回uint字段4 预留扩展
    function getPoolExtInfo(uint256 poolId)
        external
        view
        returns (
            uint256 uintExt1,
            uint256 uintExt2,
            uint256 uintExt3,
            uint256 uintExt4
        );

    //获得用户的可领取挖矿金额
    //@param userAddr 用户的地址
    //@param daysAgo 获取用户相对于
    //@return rewardAmount 奖励金额
    //@return canClaimAt 可以在什么时间领取
    //@return period 第几个奖励周期
    //@return bool 是否已领取
    function getUserRewardQty(address userAddr, uint256 daysAgo)
        external
        view
        returns (
            bool exist,
            uint256 rewardAmount,
            uint256 period,
            uint256 canClaimAt,
            bool claimed
        );

    /// @notice 创建拍卖池
    /// @param name 拍卖池名称 string
    /// @param fromToken  拍卖的Token合约地址 address
    /// @param fromTokenQty  拍卖的Token合约地址 address
    /// @param onlyBat  是否仅持有平台的地址有参与资格 bool
    /// @param toToken  拍卖的计价币种Token合约地址[如果是0x代表eth] address
    /// @param swapRatio  兑换比例 [英格兰式拍卖底价--起拍价使用拍卖底价] uint256
    /// @param durationSeconds  兑换持续时间（以秒为单位）
    /// @param url1 项目介绍url-第一段
    /// @param url2 项目介绍url-第二段
    /// @dev solidity无法直接返回struct数组，因此按字段拆分为不同的数组返回;
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
    ) external returns (bool);

    /// @notice 参与拍卖
    /// @param poolId 拍卖池Id uint
    /// @param toTokenQty  拿出多少数量的toToken 进行兑换
    /// @dev 1. 固定价格拍卖
    ///      2. 竞价（英格兰拍卖），价格通过 toTokenQty/fromTokenQty得出
    ///      3. 动态价格拍卖（荷兰式拍卖
    function join(uint256 poolId, uint256 toTokenQty)
        external
        payable
        returns (bool);

    /// @notice 领取过期的拍卖池中剩余的fromToken
    function claimRemainToken(uint256 poolId) external returns (bool);

    /// @notice 查询合约状态
    /// @return daliyMiningQty 每日挖矿释放数量
    /// @return autionFeeRate  拍卖费率
    /// @return stakingPercent  拍卖手续费多大比例用于staking分红
    /// @return createAutionFee  创建拍卖收取的平台币数量
    /// @return poolCount 累计创建多少拍卖池
    /// @return autionFeeSum  累计多少拍卖费
    /// @return tokenRelease  累计挖矿释放平台币总数(已领取)
    /// @return autionEtherSum  累计完成多少ETH拍卖
    /// @return feeAddr  手续费地址
    /// @return miningPeriod  挖矿周期（0代表未开启挖矿）
    /// @return enable  是否启用合约
    function getStatus()
        external
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
        );

    /// @notice 更新设置
    /// @param daliyMiningQty 每日挖矿释放数量
    /// @param autionFeeRate  拍卖费率
    /// @param stakingPercent  拍卖手续费多大比例用于staking分红
    /// @param createAutionFee  创建拍卖收取的平台币数量
    /// @param feeAddr  存放手续费的地址
    /// @param miningPeriod  挖矿周期
    /// @param enable  是否启用合约
    function updateSetting(
        uint256 daliyMiningQty,
        uint256 autionFeeRate,
        uint256 stakingPercent,
        uint256 createAutionFee,
        address payable feeAddr,
        uint256 miningPeriod,
        bool enable
    ) external returns (bool);

    /// @notice 领取挖矿奖励
    function claimMiningReward() external returns (bool);

    /// @notice 转移token到新版合约中（1、旧合约如果出现BUG，此方法可以安全转移出所有Token 2、目前合约升级为硬升级，非可升级行软升级，需要迁移）
    function moveMainTokenToNewVersion(
        address token,
        address payable newVersionContract
    ) external returns (bool);
}
