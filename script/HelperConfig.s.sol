// SPDX-License-Identifier:MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";

abstract contract ;

contract HelperConfig is Script {
    struct NetworkConfig{
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    }

    NetworkConfig activeNetworkConfig;

    constructor () {
        activeNetworkConfig
    }

    function getSepoliaNetworkConfig() internal view {
        return NetworkConfig({entranceFee: 0.0001 ether,
        interval: 30,
        vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
        gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
        subscriptionId: 0,
        callbackGasLimit: 500,000})
    }
 }
