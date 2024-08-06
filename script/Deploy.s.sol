// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import "script/deployers/TCAPV2Deployer.s.sol";

contract Deploy is Script, TCAPV2Deployer {
    using stdJson for string;

    function run() public {
        address proxyAdmin = address(1);
        address admin = address(2);
        address oracle = address(3);
        deployTCAPV2Transparent(proxyAdmin, admin, oracle);
    }
}
