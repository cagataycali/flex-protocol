// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AccessPass is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    address parent;
    string public slug;
    // Change this with your deployed flex node.
    string baseURL = "https://flex.link/api/pass/";
    string baseContractURL = "https://flex.link/api/pass-metadata/";
    uint256 price = 0 ether;

    constructor(string memory _name, string memory _symbol, string memory _slug) ERC721(_name, _symbol) {
        parent = msg.sender;
        slug = _slug;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURL;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseContractURL, slug));
    }

    // Owner of contract can decide the base URL,
    function setBaseURL(string memory _baseURL) public {
        require(msg.sender == parent, "Only factory can change the base url");
        baseURL = _baseURL;
    }

    function safeMint(address to) public {
        require(msg.sender == parent, "Only the factory can mint tokens");
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    // Set price if only owner
    function setPrice(uint256 _price) public {
        require(msg.sender == parent, "Only the factory can mint tokens");
        price = _price;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return string(abi.encodePacked(baseURL, slug, '/', Strings.toString(tokenId)));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}