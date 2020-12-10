// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
/*
拍卖池信息
*/
struct GeneratePoolInfo {
    bytes32 name; // 拍卖池名称
    uint256 poolType;
    address payable creator; // 创建人
    address fromToken; // 拍卖的token
    uint256 fromTokenQty; //拍卖 token 总量
    bool onlyBat; // 仅持有平台币的有资格参与
    address toToken; // 拍卖的计价token [如果是0x代表eth]
    uint256 swapRatio; // 兑换比例  toToswaken:fromToken
    uint256 swapDecimals; // 兑换比例支持的小数位数
    uint256 toTokenQty; // 拍卖收入币种已收到数量
    uint256 createAt; // 拍卖的结束时间
    uint256 duration; // 持续时间,秒
    bytes32 url1; //项目介绍url--第一段
    bytes32 url2; //项目介绍url--第二段
    uint256 uintExt1; // uintExt1 扩展返回uint字段1
    //           [1. FixedPool.swapedQty 已兑换数量(fromToken)]
    //           [2. DutchSystemPool.toTokenTotalQty 已注入的toToken数量(toToken)]
    //           [3. EnglishSystemPool.maxToTokenQty 最高出价数量(toToken)]
    uint256 uintExt2; //uintExt2 扩展返回uint字段2
    //           [1. FixedPool 代表已被取回的未拍卖掉的token数量]
    //           [2. DutchSystemPool 暂时无用途]
    //           [3. EnglishSystemPool.startRatio 拍卖底价]
    uint256 uintExt3; // 扩展返回uint字段3 预留扩展
    uint256 uintExt4; // 扩展返回uint字段4 预留扩展
}
