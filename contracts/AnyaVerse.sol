// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

// Import this file to use console.log
import "hardhat/console.sol";

import { ISuperfluid, ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import { IInstantDistributionAgreementV1 } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";


contract AnyaVerse is ERC721URIStorageUpgradeable, AccessControlUpgradeable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    /// @dev Initialization data.
    /// @param host Superfluid host contract for calling agreements.
    /// @param ida Instant Distribution Agreement contract.
    struct InitData {
        ISuperfluid host;
        IInstantDistributionAgreementV1 ida;
    }

    InitData public idaV1;

    ISuperToken public anyaToken;                   // Token to be distributed to unit holders by distribute() function

    uint32 public INDEX_ID = 0;                     // The IDA Index. Since this contract will only use one index, we'll hardcode it to "0".
    
    // Access role for minters
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyRoleOrAdminRole(bytes32 _role){
        require(hasRole(_role, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "AccessControl: missing required role or super admin role");
        _;
    }

    function initialize(ISuperfluid _host, ISuperToken _anyaToken) external initializer{
        __ERC721_init("AnyaVerse", "AV");
        // Ensure _spreaderToken is indeed a super token
        require(address(_host) == _anyaToken.getHost(),"!superToken");
        _setRoleAdmin(MINTER_ROLE, MINTER_ROLE);
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        anyaToken = _anyaToken;
        // Initializing the host and agreement type in the idaV1 object so the object can have them on hand for enacting IDA functions
        // Read more on initialization: https://docs.superfluid.finance/superfluid/developers/solidity-examples/solidity-libraries/idav1-library#importing-and-initialization
        idaV1 = InitData(
            _host,
            IInstantDistributionAgreementV1(
                address(_host.getAgreementClass(keccak256("org.superfluid-finance.agreements.InstantDistributionAgreement.v1")))
            )
        );
        // Creates the IDA Index through which tokens will be distributed
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
            idaV1.ida.createIndex.selector,
                anyaToken,
                INDEX_ID,
                new bytes(0)
            ),
            new bytes(0)
        );       
    }

    function mint(address _receiver, string calldata _tokenURI) external onlyRoleOrAdminRole(MINTER_ROLE){
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(_receiver, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        // Updates the subscribtion unit of receiver
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.updateSubscription.selector,
                anyaToken,
                INDEX_ID,
                _receiver,
                balanceOf(_receiver),
                new bytes(0)
            ),
            new bytes(0)
        );
    }

    /// @notice Takes the entire balance of the designated spreaderToken in the contract and distributes it out to unit holders w/ IDA
    function distribute() external onlyRole(DEFAULT_ADMIN_ROLE) {

        require(_tokenIds.current() > 0, "No token holders");
        
        uint256 anyaTokenBalance = anyaToken.balanceOf(address(this));

        (uint256 actualDistributionAmount,) = idaV1.ida.calculateDistribution(
            anyaToken,
            address(this),
            INDEX_ID,
            anyaTokenBalance
        );
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.distribute.selector,
                anyaToken,
                INDEX_ID,
                actualDistributionAmount,
                new bytes(0)
            ),
            new bytes(0)
        );
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
        // Updates the subscribtion unit of receiver
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.updateSubscription.selector,
                anyaToken,
                INDEX_ID,
                to,
                balanceOf(to),
                new bytes(0)
            ),
            new bytes(0)
        );
        // Updates the subscribtion unit of sender
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.updateSubscription.selector,
                anyaToken,
                INDEX_ID,
                from,
                balanceOf(from),
                new bytes(0)
            ),
            new bytes(0)
        );
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
        // Updates the subscribtion unit of receiver
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.updateSubscription.selector,
                anyaToken,
                INDEX_ID,
                to,
                balanceOf(to),
                new bytes(0)
            ),
            new bytes(0)
        );
        // Updates the subscribtion unit of sender
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.updateSubscription.selector,
                anyaToken,
                INDEX_ID,
                from,
                balanceOf(from),
                new bytes(0)
            ),
            new bytes(0)
        );
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
        // Updates the subscribtion unit of receiver
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.updateSubscription.selector,
                anyaToken,
                INDEX_ID,
                to,
                balanceOf(to),
                new bytes(0)
            ),
            new bytes(0)
        );
        // Updates the subscribtion unit of sender
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.updateSubscription.selector,
                anyaToken,
                INDEX_ID,
                from,
                balanceOf(from),
                new bytes(0)
            ),
            new bytes(0)
        );
    }

    function burn(uint256 _tokenId) external{
        require(ownerOf(_tokenId) == _msgSender(), "ERC721: burn caller is not owner");
        _burn(_tokenId);
        // Delete the subscribtion of sender
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.deleteSubscription.selector,
                anyaToken,
                address(this),
                INDEX_ID,
                _msgSender(),
                new bytes(0)
            ),
            new bytes(0)
        );
    }

    function balance() external view returns(uint){
        return anyaToken.balanceOf(address(this));
    }

    function approveSubscription() external {
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.approveSubscription.selector,
                anyaToken,
                address(this),
                INDEX_ID,
                new bytes(0)
            ),
            new bytes(0)
        );
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
