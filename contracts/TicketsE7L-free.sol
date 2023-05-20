// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721l/contracts/ERC721Linkable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TicketsE7L is ERC721Linkable {
    IERC721 immutable MRC; // = IERC721(0xeF453154766505FEB9dBF0a58E6990fd6eB66969);

    address public owner;
    string public baseURI;

    bool public paused = true;

    uint256 public maxSupply;
    uint256 public supply;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notPaused() {
        require(paused == false, "Is paused");
        _;
    }

    constructor(
        string memory baseURI_,
        uint256 maxSupply_,
        IERC721 MRC_
    ) ERC721Linkable("DrumertoParty", "DRM", address(MRC_)) {
        require(
            MRC_.supportsInterface(type(IERC721).interfaceId) == true,
            "Invalid MRC contract"
        );

        baseURI = baseURI_;
        owner = tx.origin;

        MRC = MRC_;

        maxSupply = maxSupply_;
    }

    function mint(uint256 tokenId) public {
        require(MRC.ownerOf(tokenId) == msg.sender, "Not owner");
        require(supply < maxSupply, "Total supply reached");

        ++supply;

        _safeMint(msg.sender, supply);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);
        return
            string(
                abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json")
            );
    }

    function changeURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function playPause() public onlyOwner {
        paused = !paused;
    }

    function transferOwnership(address owner_) public onlyOwner {
        owner = owner_;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success == true, "Transaction failed");
    }

    receive() external payable {}
}
