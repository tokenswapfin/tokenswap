// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract Console {
    event LogUint(string, uint256);

    function log(string calldata s, uint256 x) internal {
        emit LogUint(s, x);
    }

    event LogInt(string, int256);

    function log(string calldata s, int256 x) internal {
        emit LogInt(s, x);
    }

    event LogBytes(string, bytes);

    function log(string calldata s, bytes calldata x) internal {
        emit LogBytes(s, x);
    }

    event LogBytes32(string, bytes32);

    function log(string calldata s, bytes32 x) internal {
        emit LogBytes32(s, x);
    }

    event LogAddress(string, address);

    function log(string calldata s, address x) internal {
        emit LogAddress(s, x);
    }

    event LogBool(string, bool);

    function log(string calldata s, bool x) internal {
        emit LogBool(s, x);
    }
}
