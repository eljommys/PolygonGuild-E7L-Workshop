// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721l/contracts/ERC721Linkable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TicketsE7L is ERC721Linkable {
    event NewParticipant(
        address indexed participant,
        uint256 tokenId,
        uint256 ticketId
    );

    IERC721 immutable MRC; // = IERC721(0xeF453154766505FEB9dBF0a58E6990fd6eB66969);
    ERC20 immutable USDC; // = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

    address public owner;
    string public baseURI;

    mapping(uint256 => bool) private registered;
    uint256 public price;
    bool public paused = true;

    uint256 public maxSupply;
    uint256 public supply;

    modifier onlyHolder() {
        require(MRC.balanceOf(msg.sender) > 0, "Not holder");
        _;
    }

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
        uint256 price_,
        uint256 maxSupply_,
        IERC721 MRC_,
        ERC20 USDC_
    ) ERC721Linkable("DrumertoParty", "DRM", address(MRC_)) {
        require(
            MRC_.supportsInterface(type(IERC721).interfaceId) == true,
            "Invalid MRC contract"
        );

        baseURI = baseURI_;
        owner = tx.origin;

        MRC = MRC_;
        USDC = USDC_;

        price = price_ * (10 ** USDC.decimals());
        maxSupply = maxSupply_;
    }

    function mint(uint256 tokenId) public onlyHolder {
        require(MRC.ownerOf(tokenId) == msg.sender, "Not owner");
        require(registered[tokenId] == false, "Token already registered");
        require(supply < maxSupply, "Total supply reached");

        registered[tokenId] = true;
        ++supply;

        USDC.transferFrom(msg.sender, owner, price);

        _safeMint(msg.sender, supply);

        approve(address(this), supply);
        this.linkToken(supply, tokenId);

        emit NewParticipant(msg.sender, tokenId, supply);
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

    function changePrice(uint256 price_) public onlyOwner {
        price = price_ * (10 ** USDC.decimals());
    }

    function transferOwnership(address owner_) public onlyOwner {
        owner = owner_;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success == true, "Transaction failed");
    }

    function isRegistered(uint256 tokenId) public view returns (bool) {
        return registered[tokenId];
    }

    receive() external payable {}
}
