// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

import { ILightClient, LightClientUpdate } from "./interfaces/IDendrETH.sol";
import { SSZ } from "../Telepathy/libraries/SimpleSerialize.sol";
import { BlockHashAdapter } from "../BlockHashAdapter.sol";

contract DendrETHAdapter is BlockHashAdapter {
    uint256 public immutable SOURCE_CHAIN_ID;
    address public immutable DENDRETH;

    error InvalidUpdate();
    error BlockHeaderNotAvailable(uint256 slot);
    error InvalidSlot();
    error InvalidBlockNumberProof();
    error InvalidBlockHashProof();

    constructor(uint256 sourceChainId, address dendreth) {
        SOURCE_CHAIN_ID = sourceChainId;
        DENDRETH = dendreth;
    }

    /// @notice Stores the block header for a given block only if it exists
    //          in the DendrETH Light Client for the SOURCE_CHAIN_ID.
    function storeBlockHeader(
        uint32 _chainId,
        uint64 _slot,
        bytes32[] calldata _slotProof,
        bytes32 _finalizedBlockHeader,
        uint256 _blockNumber,
        bytes32[] calldata _blockNumberProof,
        bytes32 _blockHash,
        bytes32[] calldata _blockHashProof
    ) external {
        if (!SSZ.verifySlot(_slot, _slotProof, _finalizedBlockHeader)) {
            revert InvalidSlot();
        }

        if (!SSZ.verifyBlockNumber(_blockNumber, _blockNumberProof, _finalizedBlockHeader)) {
            revert InvalidBlockNumberProof();
        }

        if (!SSZ.verifyBlockHash(_blockHash, _blockHashProof, _finalizedBlockHeader)) {
            revert InvalidBlockHashProof();
        }

        ILightClient lightClient = ILightClient(DENDRETH);

        uint256 currentIndex = lightClient.currentIndex();
        uint256 i = currentIndex;
        bool found = false;

        do {
            if (_finalizedBlockHeader == lightClient.finalizedHeaders(i)) {
                found = true;
                break;
            }
            if (i == 0) {
                i = 32;
            }
            i--;
        } while (i != currentIndex);

        if (!found) {
            revert BlockHeaderNotAvailable(_slot);
        }

        _storeHash(SOURCE_CHAIN_ID, _blockNumber, _blockHash);
    }

    /// @notice Updates DendrETH Light client and stores the given block
    //          for the update
    function storeBlockHeader(
        uint32 _chainId,
        uint64 _slot,
        bytes32[] calldata _slotProof,
        uint256 _blockNumber,
        bytes32[] calldata _blockNumberProof,
        bytes32 _blockHash,
        bytes32[] calldata _blockHashProof,
        LightClientUpdate calldata update
    ) external {
        ILightClient lightClient = ILightClient(DENDRETH);

        bytes32 finalizedHeaderRoot = lightClient.finalizedHeaderRoot();

        if (!SSZ.verifySlot(_slot, _slotProof, finalizedHeaderRoot)) {
            revert InvalidUpdate();
        }

        if (!SSZ.verifyBlockNumber(_blockNumber, _blockNumberProof, finalizedHeaderRoot)) {
            revert InvalidBlockNumberProof();
        }

        if (!SSZ.verifyBlockHash(_blockHash, _blockHashProof, finalizedHeaderRoot)) {
            revert InvalidBlockHashProof();
        }

        _storeHash(SOURCE_CHAIN_ID, _blockNumber, _blockHash);

        lightClient.light_client_update(update);
    }
}
