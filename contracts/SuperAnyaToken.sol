// SPDX-License-Identifier: UNLICENSED
import { SuperToken } from "@superfluid-finance/ethereum-contracts/contracts/superfluid/SuperToken.sol";
import { ISuperfluid } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SuperAnyaToken is SuperToken {
    constructor (ISuperfluid _host) SuperToken(_host){}

    function mint(uint256 amount) external {
        _mint(msg.sender, msg.sender, amount, false /* requireReceptionAck */, new bytes(0), new bytes(0));
    }
}