// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ENS} from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import {IExtendedResolver} from "@ensdomains/ens-contracts/contracts/resolvers/profiles/IExtendedResolver.sol";
import {IAddressResolver} from "@ensdomains/ens-contracts/contracts/resolvers/profiles/IAddressResolver.sol";
import {NameCoder} from "@ensdomains/ens-contracts/contracts/utils/NameCoder.sol";

contract BaseChonksResolver is ERC165, IExtendedResolver {
    ENS constant ENS_REGISTRY = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    // https://basescan.org/address/0x07152bfde079b5319e5308C43fB1Dbc9C76cb4F9
    address constant CHONKS_PROXY = 0x55266d75D1a14E4572138116aF39863Ed6596E7F;
    address constant CHONKS_NFT = 0x07152bfde079b5319e5308C43fB1Dbc9C76cb4F9;
    address constant BASE_ERC_6551_REGISTRY =
        0x000000006551c19487814612e58FE06813775758;

    uint256 constant CHAIN_ID_BASE = 8453;
    uint256 constant COIN_TYPE_BASE = 0x80000000 | CHAIN_ID_BASE;

    error UnsupportedResolverProfile(bytes4);
    error UnreachableName(bytes);

    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return
            type(IExtendedResolver).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function resolve(
        bytes calldata name,
        bytes calldata data
    ) external view returns (bytes memory) {
        if (bytes4(data) == IAddressResolver.addr.selector) {
            (, uint256 coinType) = abi.decode(data[4:], (bytes32, uint256));
            bytes memory a;
            uint256 token = _parseName(name);
            if (coinType == COIN_TYPE_BASE) {
                address addr;
                if (token == 0) {
                    addr = CHONKS_NFT;
                } else {
                    addr = generateERC6551Address(
                        BASE_ERC_6551_REGISTRY,
                        CHONKS_PROXY,
                        0,
                        CHAIN_ID_BASE,
                        CHONKS_NFT,
                        token
                    );
                }
                a = abi.encodePacked(addr);
            }
            return abi.encode(a);
        } else {
            revert UnsupportedResolverProfile(bytes4(data));
        }
    }

    function _parseName(
        bytes calldata name
    ) internal view returns (uint256 token) {
        (, uint256 pos) = NameCoder.readLabel(name, 0);
        bool valid;
        if (pos < 66) {
            (valid, token) = Strings.tryParseUint(string(name[1:pos]));
        }
        if (!valid) {
            pos = 0;
            token = 0;
        }
        bytes32 node = NameCoder.namehash(name, pos);
        if (ENS_REGISTRY.resolver(node) != address(this)) {
            revert UnreachableName(name);
        }
    }

    function generateERC6551Address(
        address registry,
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) internal pure returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                // 0xff                           (1 byte)
                                // registry (address)             (20 bytes)
                                // salt (bytes32)                 (32 bytes)
                                // Bytecode Hash (bytes32)        (32 bytes)
                                bytes1(0xff),
                                registry,
                                salt,
                                keccak256(
                                    abi.encodePacked(
                                        // ERC-1167 Constructor + Header  (20 bytes)
                                        // implementation (address)       (20 bytes)
                                        // ERC-1167 Footer                (15 bytes)
                                        // salt (uint256)                 (32 bytes)
                                        // chainId (uint256)              (32 bytes)
                                        // tokenContract (address)        (32 bytes)
                                        // tokenId (uint256)              (32 bytes)
                                        bytes20(
                                            0x3d60ad80600a3d3981f3363d3D373D3D3D363D73
                                        ),
                                        implementation,
                                        bytes15(
                                            0x5af43d82803e903d91602b57fd5bf3
                                        ),
                                        salt,
                                        chainId,
                                        uint256(uint160(tokenContract)),
                                        tokenId
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }
}
