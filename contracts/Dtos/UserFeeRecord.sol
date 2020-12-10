// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
/*
用户参与拍卖手续费贡献记录
*/
struct UserFeeRecord {
    uint256 poolId;
    address userAddr; // 用户地址
    uint256 amount; // 用户参与金额
    uint256 fee; // 用户手续费贡献金额
    uint256 createAt; // 创建时间
}
