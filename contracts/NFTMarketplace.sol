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

        // while create token , send the nft to the new onwe(which is the cotnract itself(address.this), now the contract have the right to execute the sell ntfs function)
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
        uint totalItemCount = _tokenIds.current();
        uint itemCount  = 0 ; 
        uint currentIndex = 0 ; 

        // get the count of the ntfs you have 
        for (uint i = 0 ; i < totalItemCount ; i++)  {
            if (idToListToken[i+1].owner == msg.sender || idToListToken[i+1].seller == msg.sender) {
               itemCount += 1 ; 
            }
        }

        // after getting thw count, create and array have count elems 
        ListedToken[] memory items = new ListedToken[](itemCount) ; 
        for (uint i = 0 ; i < totalItemCount ; i++) {
            if (idToListToken[i+1].owner == msg.sender || idToListToken[i+1].seller == msg.sender) {
                uint currentId = i +1 ;
                ListedToken storage currentItem = idToListToken[currentId] ; 
                items[currentIndex] = currentItem ; 
                currentIndex += 1 ; 
            }
            
        }
        return items; 
    }

    function executeSale (uint tokenId) public payable {
        uint price = idToListToken[tokenId].price ; 
        require( msg.value == price , "Please enter the price in order to purchase the NFT");

        address seller = idToListToken[tokenId].seller ; 

        idToListToken[tokenId].currentlyListed = true ;
        idToListToken[tokenId].seller = payable(msg.sender) ; 

        _itemsSold.increment();
        _transfer(address(this), msg.sender, tokenId);

        // the nft bering trasnfer from contract to sender, the contract apprived sale the nft on behalf of the actual onwer

        // after send that to the new buyer (msg.sender), the contract no logner the owner, we nedd to create the fucntion to approve for the new owner futures sales,. 
        approve(address(this), tokenId);

        // transfer the list price to owner of merket place
        payable(owner).transfer(listPrice) ; 

        // give the sller the money
        payable(seller).transfer(msg.value) ; 
    }
}