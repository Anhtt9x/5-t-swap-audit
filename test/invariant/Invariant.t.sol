//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {PoolFactory} from "src/PoolFactory.sol";
import {TSwapPool} from "src/TSwapPool.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantTest is StdInvariant, Test {

    ERC20Mock poolToken;
    ERC20Mock weth;

    PoolFactory factory;
    TSwapPool pool;
    Handler handler;

    int256 constant STARTING_X = 100e18; // 1000 tokens
    int256 constant STARTING_Y = 100e18; // 1000 WETH
    

    function setUp() public {
        // Set up the initial state of the contract or environment
        // This can include deploying contracts, setting variables, etc.
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        poolToken.mint(address(this), uint256(STARTING_X));
        weth.mint(address(this), uint256(STARTING_Y));

        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        pool.deposit(
            uint256(STARTING_X),
            uint256(STARTING_Y),
            uint256(STARTING_X),
            uint64(block.timestamp)
        );

        handler = new Handler(pool);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = Handler.deposit.selector;
        selectors[1] = Handler.swapPoolTokenForWethBaseOnOutputWeth.selector;
        targetSelector(FuzzSelector({
            addr: address(handler),
            selectors: selectors
        }));

        targetContract(address(handler));

    }

    function statefulFuzz_constantProductFormulaStaysTheSame() public view {
        assertEq(handler.actualDeltaX(), handler.expectedDeltaX());
    }
}