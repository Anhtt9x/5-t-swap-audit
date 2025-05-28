//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {TswapPool} from "../../src/TSwapPool.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

contract Handler is Test {
    TSwapPool pool;
    ERC20Mock weth;
    ERC20Mock poolToken;

    int256 startingY;
    int256 startingX;
     // 1000 tokens
    int256 expectedDeltaY;
    int256 expectedDeltaX;

    int256 actualDeltaY;
    int256 actualDeltaX;

    address liquidityProvider = makeAddr("lq");

    constructor(TSwapPool _pool) {
        pool = _pool;
        weth = ERC20Mock(_pool.weth());
        poolToken = ERC20Mock(_pool.poolToken());
    }

    function swapPoolTokenForWethBaseOnOutputWeth(uint256 outputWeth) public {
        outputWeth = bound(outputWeth, 0, type(uint64).max);
        if (outputWeth >= weth.balanceOf(address(pool))) {
            // Swap logic here
            return;
        }

        uint256 poolTokenAmount = 
    }

    function deposit(uint256 wethAmount) public {
        wethAmount = bound(wethAmount, 0, type(uint64).max);

        startingY = int256(weth.balanceOf(address(this)));
        startingX = int256(poolToken.balanceOf(address(this)));
        expectedDeltaY = int256(wethAmount);
        expectedDeltaX = int256(pool.getPoolTokensToDepositBasedOnWeth(
            wethAmount
        ));

        vm.startPrank(liquidityProvider);
        weth.mint(liquidityProvider, wethAmount);
        poolToken.mint(
            liquidityProvider,
            expectedDeltaX
        );
        weth.approve(address(pool), type(uint256).max);
        poolToken.approve(address(pool), type(uint256).max);

        pool.deposit(
            wethAmount,
            0,
            expectedDeltaX,
            uint64(block.timestamp + 1 days)
        );
        vm.stopPrank();

        uint256 endingY = weth.balanceOf(address(this));
        uint256 endingX = poolToken.balanceOf(address(this));

        actualDeltaY = int256(startingY) - int256(endingY);
        actualDeltaX = int256(startingX) - int256(endingX);
        assertEq(actualDeltaY, expectedDeltaY, "Delta Y mismatch");
    }
}