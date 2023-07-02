//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    NetworkConfig private s_config;
    struct NetworkConfig {
        uint256 raffleFee;
        uint interval;
        address vrfCoordinator;
        bytes32 keyHash;
        uint64 subId;
        uint32 callbackGasLimit;
    }

    constructor() {
        if (block.chainid == 111555111) {
            s_config = getSepoliaNetworkConfig();
        } else {
            s_config = getOrCreateAnvilNetworkConfig();
        }
    }

    function getSepoliaNetworkConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        NetworkConfig memory config = NetworkConfig({
            raffleFee: 0.1 ether,
            interval: 60,
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subId: 3308,
            callbackGasLimit: 500000
        });

        return config;
    }

    function getOrCreateAnvilNetworkConfig()
        public
        view
        returns (NetworkConfig memory)
    {
        //deploy a vrfCoordinator
        NetworkConfig memory config;
        config.vrfCoordinator = 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255;
        return config;
    }

    function getNetworkConfig() public view returns (NetworkConfig memory) {
        return s_config;
    }
}
