// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/*
 拍卖池接口 
*/
interface IPool {
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
    function getPoolInfo()
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

    /// @notice 查询拍卖池拍卖Token信息
    /// @return fromToken 拍卖的Token
    /// @return fromTokenQty 拍卖币种的数量
    /// @return swapRatio 拍卖池兑换比例
    /// @return toToken 拍卖计价币种地址
    function getPoolTokenInfo()
        external
        view
        returns (
            address fromToken,
            uint256 fromTokenQty,
            uint256 swapRatio,
            address toToken
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
    function getPoolExtInfo()
        external
        view
        returns (
            uint256 uintExt1,
            uint256 uintExt2,
            uint256 uintExt3,
            uint256 uintExt4
        );

    //是否仅允许平台币Holder
    function isOnlyAllowBatHolder() external view returns (bool);

    /// @notice 参与拍卖
    /// @param participator  拍卖参与人
    /// @param autionFeeRate  拍卖手续费费率
    /// @param toTokenQty  拿出多少数量的toToken 进行兑换
    /// @return joinSucceed 是否成功参与拍卖
    /// @return chargeFeeOfToToken 参与拍卖创建者被收取的ToToken拍卖费
    ///         （Fixed和荷兰式拍卖（虽然最后才会得到拍卖价格）会马上收取，英格兰和参与时不会收取手续费（费用返回0），在最后成功时，收取成功竞拍者费用）
    /// @dev 1. 固定价格拍卖
    ///      2. 竞价（英格兰拍卖），价格通过 toTokenQty/fromTokenQty得出
    ///      3. 动态价格拍卖（荷兰式拍卖)
    function join(
        address participator,
        uint256 autionFeeRate,
        uint256 toTokenQty
    ) external payable returns (bool joinSucceed, uint256 chargeFeeOfToToken);

    /// @notice 查询剩余的fromToken数量接口
    /// @return remainQty 扩展返回uint字段2
    ///           [1. FixedPool fromToken - swapedToken]
    ///           [2. DutchSystemPool 0]
    ///           [3. EnglishSystemPool.startRatio fromTokenQty]
    function getRemainQty() external view returns (uint256 remainQty);

    /// @notice 取回未拍卖掉的Token
    function claimRemainToken() external returns (bool);
}
