//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../node_modules/hardhat/console.sol";
import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketPlace is ERC721URIStorage {
    
    // owner, onwer the market place, every time user goes to listing nft, thet have to pay some fee
    address payable owner ;

    using Counters for Counters.Counter ; 
    Counters.Counter private _tokenIds ; 
    Counters.Counter private _itemsSold  ; 

    // list price will to the owner
    uint256 listPrice = 0.01 ether ; 

    // Playbale measn this address is eligible to receive eth 
    constructor() ERC721("NFTMarketPlace", "NTFM") {
        owner = payable(msg.sender) ; 
    }

    struct ListedToken {
        uint256 tokenId; 
        address payable owner ; 
        address payable seller  ;
        uint256 price ; 
        bool currentlyListed ; 
    }

    // maps tokenId into all the field of the matedata(in teh struct)
    mapping(uint256 => ListedToken) private idToListToken ; 

    // Helper funtions 
    function updateListPrice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "Only sender can update the listing price");
        listPrice = _listPrice ; 
    }


    // view = read only
    function getListPrice() public view returns (uint256) {
        return listPrice ; 
    }


    // memory : temporary memory creat within the function
    // thisd return all the infomation of the token based on the lste created token id
    function getLatestIdToListedToken() public view returns (ListedToken memory) {
        uint256 currentTokenId = _tokenIds.current();
        return idToListToken[currentTokenId] ;
    }

    // return token based on token id 
    function getListedForTokenId(uint256 tokenId) public view returns(ListedToken memory){
        return idToListToken[tokenId];
    }  

    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current() ; 
    }

    function createToken(string memory tokenURI, uint256 price) public payable returns(uint) {
        require(msg.value == listPrice, "Pls send enough ether to list");
        require(price > 0 , "Make sure the price isn negative");

        _tokenIds.increment();
        uint256 currentTokenId = _tokenIds.current() ; 
        _safeMint(msg.sender, currentTokenId);
        // safe mint : allow creator to retrive the token if some problems happen with the contract
        
        // this goes and makes sense with the map fucntion i believe
        _setTokenURI(currentTokenId, tokenURI);

        createListedToken(currentTokenId, price) ;

        return currentTokenId ;
    }

    function createListedToken(uint256 tokenId, uint256 price ) private {
        idToListToken[tokenId]  = ListedToken(
            tokenId, 
            payable(address(this)),
            payable(msg.sender),
            price,
            true  
        );
        _transfer(msg.sender, address(this), tokenId);
    }

    function getAllNFTs() public view returns(ListedToken[] memory) {
        uint nftCount = _tokenIds.current() ;
        ListedToken[] memory tokens = new ListedToken[](nftCount) ; 

        uint currentIndex = 0 ; 

        for (uint i = 0 ; i < nftCount ; i++) {
            uint currentId = i + 1 ; 
            ListedToken storage currentItem = idToListToken[currentId] ;
            tokens[currentIndex] = currentItem ;
            currentIndex += 1 ; 
        }
        return tokens ;
    }

    function getMyNFTs() public view returns(ListedToken[] memory) {
        uint myNftCount = _tokenIds.current();
        uint itemCount  = 0 ; 
        uint currentIndex = 0 ; 
    }
}