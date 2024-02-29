//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import { Test, console2 } from "forge-std/Test.sol";

contract BaseDeploy is Test {
	address public deployer = vm.envAddress("LOCAL_DEPLOYER");
	address public user = makeAddr("user");

	
	/* 
    初始化：建立好一个测试环境
     */
	function setUp() public virtual {
		vm.startPrank(deployer);
		
		vm.stopPrank();
	}
}
