//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {TSwapPool} from "src/TSwapPool.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";

contract Handler is Test {
    TSwapPool pool;
    ERC20Mock weth;
    ERC20Mock poolToken;

    int256 startingY;
    int256 startingX;
     // 1000 tokens
    int256 expectedDeltaY;
    int256 public expectedDeltaX;

    int256 actualDeltaY;
    int256 public actualDeltaX;

    address liquidityProvider = makeAddr("lq");
    address swapper = makeAddr("swapper");

    constructor(TSwapPool _pool) {
        pool = _pool;
        weth = ERC20Mock(_pool.getWeth());
        poolToken = ERC20Mock(_pool.getPoolToken());
    }

    function swapPoolTokenForWethBaseOnOutputWeth(uint256 outputWeth) public {
        outputWeth = bound(outputWeth, pool.getMinimumWethDepositAmount(), type(uint64).max);
        if (outputWeth >= weth.balanceOf(address(pool))) {
            // Swap logic here
            return;
        }

        uint256 poolTokenAmount = pool.getInputAmountBasedOnOutput(
            outputWeth,
            poolToken.balanceOf(address(pool)),
            weth.balanceOf(address(pool))
        );

        if (poolTokenAmount > type(uint64).max) {
            // Swap logic here
            return;
        }

        startingY = int256(weth.balanceOf(address(pool)));
        startingX = int256(poolToken.balanceOf(address(pool)));
        expectedDeltaY = int256(outputWeth);
        expectedDeltaX = int256(poolTokenAmount);

        if (poolToken.balanceOf(swapper) < poolTokenAmount) {
            // Swap logic here
            poolToken.mint(swapper, poolTokenAmount - poolToken.balanceOf(swapper) + 1);
        }

        vm.startPrank(swapper);
        poolToken.approve(address(pool), type(uint256).max);
        pool.swapExactOutput(
            poolToken,
            weth,
            outputWeth,
            uint64(block.timestamp));
        vm.stopPrank();
        uint256 endingY = weth.balanceOf(address(pool));
        uint256 endingX = poolToken.balanceOf(address(pool));
        actualDeltaY = int256(endingY) - int256(startingY);
        actualDeltaX = int256(endingX) - int256(startingX);

    }

    function deposit(uint256 wethAmount) public {
        uint256 minWeth = pool.getMinimumWethDepositAmount();
        wethAmount = bound(wethAmount, minWeth, type(uint64).max);

        startingY = int256(weth.balanceOf(address(pool)));
        startingX = int256(poolToken.balanceOf(address(pool)));
        expectedDeltaY = int256(wethAmount);
        expectedDeltaX = int256(pool.getPoolTokensToDepositBasedOnWeth(
            wethAmount
        ));

        vm.startPrank(liquidityProvider);
        weth.mint(liquidityProvider, wethAmount);
        poolToken.mint(
            liquidityProvider,
            uint256(expectedDeltaX)
        );
        weth.approve(address(pool), type(uint256).max);
        poolToken.approve(address(pool), type(uint256).max);

        pool.deposit(
            wethAmount,
            0,
            uint256(expectedDeltaX),
            uint64(block.timestamp + 1 days)
        );
        vm.stopPrank();

        uint256 endingY = weth.balanceOf(address(pool));
        uint256 endingX = poolToken.balanceOf(address(pool));

        actualDeltaY = int256(endingY) - int256(startingY);
        actualDeltaX = int256(endingX) - int256(startingX);
        assertEq(actualDeltaY, expectedDeltaY, "Delta Y mismatch");
    }
}