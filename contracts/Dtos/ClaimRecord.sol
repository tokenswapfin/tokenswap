// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/*
用户领取每日挖矿奖励
*/
struct ClaimRecord {
    address userAddr; // 用户地址
    uint256 reward; // 用户奖励金额
    uint256 period; // 奖励属于哪个周期
    uint256 createAt; // 创建时间
}
