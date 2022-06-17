//SPDX-License-Identifier: 0BSD
// Copyright Knot, inc.
// Author tomo@knot.inc
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract PoW is
    Initializable,
    ERC721Upgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    event MintPoW(uint256 tokenId, address to);

    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");

    // __baseURI（ NFT として登録する画像の場所）
    string private _baseURIForPoW;
    // Last Used id (重複していない id を振るために必要)
    uint256 private _lastId;
    // sale status（真偽値で nft 発行の可否を制御する）
    bool public saleIsActive;

    // actualTokenURI for each tokenId（ nft から Proof を取得）
    mapping(uint256 => string) private _actualTokenURI;

    // proofId to tokenId（ Proof から nft を取得）
    mapping(string => uint256) private _proofIdToTokenId;

    // nft でよくあるカウンター（定型文）
    CountersUpgradeable.Counter private counter;

    /**
     * @dev Gets the token uri（ baseUrl と token id を結合した URL を返す）
     * @return string representing the token uri
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _strConcat(_baseURIForPoW, _actualTokenURI[tokenId]);
    }

    /**
     * @dev Gets the tokenId
     * @return tokenId from proofId
     */
    function tokenID(string memory proofId) public view returns (uint256) {
        return _proofIdToTokenId[proofId];
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param proofId The id of proof generated on the centralized server // オフチェーンで生成されたもの
     * @return A boolean that indicates if the operation was successful.
     */
    function mintToken(address to, string memory proofId)
        public
        nonReentrant
        returns (bool)
    {
        require(hasRole(MINT_ROLE, msg.sender), "Not authorized"); // 権限確認
        require(saleIsActive, "Sale not active"); // nft 発行可否確認
        _lastId += 1; // id は increment
        return _mintToken(_lastId, to, proofId);
    }

    /**
     * @dev Function to set baseURI
     * @param baseURI baseURI e.g. "https://foo.com/pow/"
     */
    function setBaseURI(string memory baseURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");
        _baseURIForPoW = baseURI;
    }

    // nft 発行の可否を切り替える
    /**
     * @dev Set sale activity. Pause mint in case of hack
     * @param _saleIsActive sale activity
     */
    function setSaleIsActive(bool _saleIsActive) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");
        saleIsActive = _saleIsActive;
    }

    // nft の総供給量を返す
    function totalSupply() public view returns (uint256) {
        return counter.current();
    }

    function initialize(
        string memory _name, // コントラクトの名前
        string memory _symbol, // シンボル
        string memory __baseURI // NFT として登録する画像の場所
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __AccessControl_init();
        __ReentrancyGuard_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINT_ROLE, msg.sender);
        _baseURIForPoW = __baseURI;
        saleIsActive = true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Function to mint tokens
     * @param tokenId The token id to mint.
     * @param to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function _mintToken(
        uint256 tokenId,
        address to,
        string memory proofId // Proof の id（どこで呼ばれているか確認）
    ) internal returns (bool) {
        _safeMint(to, tokenId);
        _actualTokenURI[tokenId] = proofId;
        _proofIdToTokenId[proofId] = tokenId;
        counter.increment();
        emit MintPoW(tokenId, to);
        return true;
    }

    /**
     * @dev Function to concat strings（文字列を連結する関数 __baseURI + _actualTokenURI ）
     * Taken from https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
     */
    function _strConcat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory _concatenatedString)
    {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory abcde = new string(_ba.length + _bb.length);
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        uint256 i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        return string(babcde);
    }
}
