// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Structs {
    function equals(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return
                keccak256(abi.encodePacked(a)) ==
                keccak256(abi.encodePacked(b));
        }
    }

    // Lowercase a string 
    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    struct Settings {
        bool isPublic;
        bool isSellable;
        bool isLimited;
        uint256 limit;
        uint256 accessPrice;
    }

    struct NFT {
        uint256 tokenId; // 1,2,3,4
        string slug; // cagatay flex.link/cagatay
        string content; // encryptyed content isPublic === false
        uint256 totalEarnings;
        Settings settings;
    }

    function createNFT(uint256 tokenId, string calldata slug) public pure returns (NFT memory) {
        // Lowercase the slug
        string memory lowercaseSlug = toLower(slug);
        return NFT({
            tokenId: tokenId,
            slug: lowercaseSlug,
            content: "",
            totalEarnings: 0,
            settings: Settings({
                isPublic: false,
                isSellable: false,
                isLimited: false,
                limit: 0,
                accessPrice: 0 ether
            })
        });
    }
}