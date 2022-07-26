// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Structs.sol";
import "./AccessPass.sol";

/// @custom:security-contact cagataycali@icloud.com
contract Flex is Structs, ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public price = 0 ether; // polygon price
    uint256 public purchaseFee = 1;
    // Change this with your deployed flex node.
    string public baseURL = "https://flex.link/api/metadata/";
    string baseContractURL = "https://flex.link/api/flex-metadata/";

    constructor() ERC721("Flex", "FLEX") {}

    // Store slugs for lookup the NFT.
    // {'cagatay': 1}
    mapping(string => uint256) public slugs;
    // Store NFT's
    // {1: {tokenId: 1, slug: 'cagatay', ...}}
    mapping(uint256 => Structs.NFT) public nfts;
    mapping(uint256 => AccessPass) public accessPasses;

    function contractURI() public view returns (string memory) {
        return baseContractURL;
    }

    function isSlugClaimed(string calldata _slug) public view returns (bool) {
        return slugs[Structs.toLower(_slug)] != 0;
    }

    function isPrivate(string calldata slug) public view returns (bool) {
        // Check the slug exists
        require(isSlugClaimed(slug), "Slug is not claimed");
        uint256 itemId = slugs[slug];
        return nfts[itemId].settings.isPublic == false;
    }

    function walletOfOwner(address _owner) public view returns (NFT[] memory) {
        // Get the owner's balance,
        uint256 ownerTokenCount = balanceOf(_owner);
        NFT[] memory nftArray = new NFT[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            // Lookup the NFT by owner's tokenId,
            nftArray[i] = nfts[tokenOfOwnerByIndex(_owner, i)];
        }
        return nftArray;
    }

    function isAllowed(string calldata slug, address sender)
        public
        view
        returns (bool)
    {
        require(isSlugClaimed(slug), "Slug is not claimed");
        uint256 tokenId = slugs[slug];
        // Check the sender is owner?
        address owner = ownerOf(tokenId);
        if (owner == sender) {
            return true;
        }
        // Check the sender has access pass
        return accessPasses[tokenId].balanceOf(sender) > 0;
    }

    // Owner of contract can decide the minting price,
    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    // Owner of contract can decide the purchase fee,
    function setPurchaseFee(uint256 _purchaseFee) public onlyOwner {
        purchaseFee = _purchaseFee;
    }

    // Owner of contract can decide the base URL,
    function setBaseURL(string memory _baseURL) public onlyOwner {
        baseURL = _baseURL;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURL;
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        delete slugs[nfts[tokenId].slug];
        delete nfts[tokenId];
        delete accessPasses[tokenId];
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return string(abi.encodePacked(baseURL, Strings.toString(tokenId)));
    }

    // ERC721Enumerable overrides,
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Business functions

    /**
        Mint a new NFT.
        * Important: the NFT is private as default.
    */
    function mint(address sender, string calldata slug) public payable {
        require(!isSlugClaimed(slug), "Slug is already claimed");
        // If the msg.sender is owner, mint is free, otherwise it costs.
        // owner === 0x171....
        require(
            msg.sender == owner() || msg.value >= price,
            "Insufficent funds"
        );
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(sender, tokenId);
        // Add the slug to the slugs mapping. (reverse lookup)
        slugs[Structs.toLower(slug)] = tokenId;
        // Add the NFT to the nfts mapping.
        nfts[tokenId] = Structs.createNFT(tokenId, slug);
        // Call factory here,
        accessPasses[tokenId] = new AccessPass(
            string(abi.encodePacked(slug, " | Flex Access Pass")),
            string(abi.encodePacked(slug, "pass")),
            slug
        );
    }

    /**
        Change the NFT's content.
        * Important: the NFT is private as default.
    */
    function updateNFT(
        string calldata slug,
        string calldata content,
        bool isPublic,
        bool isSellable,
        bool isLimited,
        uint256 limit,
        uint256 accessPrice
    ) public {
        uint256 tokenId = slugs[Structs.toLower(slug)];
        // If the message sender is contract owner, check the sender is owner of NFT.
        require(
            msg.sender == owner() || ownerOf(tokenId) == msg.sender,
            "You are not allowed to update this NFT"
        );
        // Content is not empty, access price is not smaller than zero
        require((bytes(content).length > 0 && bytes(content).length < 64) || accessPrice >= 0 || limit >= 0, "Update failed");
        // NFT content
        nfts[tokenId].content = content;
        // NFT settings
        nfts[tokenId].settings = Settings({
            isPublic: isPublic,
            isLimited: isLimited,
            limit: limit,
            isSellable: isSellable,
            accessPrice: accessPrice
        });
    }

    function giveAccess(string calldata slug, address to) public {
        require(isSlugClaimed(slug), "Slug is not claimed");
        uint256 tokenId = slugs[slug];
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not allowed to give access to anybody"
        );
        require(
            accessPasses[tokenId].balanceOf(to) == 0,
            "Reciever already have access pass"
        );
        accessPasses[tokenId].safeMint(to);
    }

    function purchaseAccess(string calldata slug) public payable {
        require(isSlugClaimed(slug), "Slug is not claimed");
        uint256 tokenId = slugs[slug];
        require(
            accessPasses[tokenId].balanceOf(msg.sender) == 0,
            "You already have access pass"
        );
        // If the access pass limited supply, check the supply is not full.
        if (nfts[tokenId].settings.isLimited) {
            require(
                accessPasses[tokenId].totalSupply() <
                    nfts[tokenId].settings.limit,
                "Access pass is limited and the limit is reached"
            );
        }
        // This NFT is not payable.
        require(nfts[tokenId].settings.isSellable, "NFT is not pay to access");

        // Withdraw the access price from the NFT owner
        // Calculate price with fee,
        // Fee is %10 of the access price.
        uint256 fee = (nfts[tokenId].settings.accessPrice * purchaseFee) / 100;
        require(
            msg.value >= nfts[tokenId].settings.accessPrice + fee,
            "Insufficent funds"
        );
        // Withdraw the access price from the NFT owner
        payable(ownerOf(tokenId)).transfer(nfts[tokenId].settings.accessPrice);
        accessPasses[tokenId].safeMint(msg.sender);
        nfts[tokenId].totalEarnings += nfts[tokenId].settings.accessPrice;
    }

    // Withdraw the owner's earnings.
    function withdraw(address payable to) public onlyOwner {
        to.transfer(address(this).balance);
    }
}
