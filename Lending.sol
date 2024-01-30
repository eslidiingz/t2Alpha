// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Lending is ERC20, ERC20Pausable, AccessControl, ReentrancyGuard {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    mapping(address => bool) public whiteList;
    mapping(address => uint) public borrowedAmount;

    uint public interestRate = 10;

    event Borrow(address indexed borrower, uint amount);
    event Repay(address indexed borrower, uint amount);

    constructor() ERC20("TetherToken", "USTD") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _mint(address(this), 10000000 * 10 ** decimals());
    }

    function borrow(uint _amount) public nonReentrant whenNotPaused {
        require(_amount > 0, "Amount of borrow must be greater than zero.");
        require(borrowedAmount[msg.sender] == 0, "Please, Repay beore borrow again.");
        borrowedAmount[msg.sender] += _amount;
        _transfer(address(this), msg.sender, _amount);
        emit Borrow(msg.sender, _amount);
    }

    function repay() public whenNotPaused {
        uint totalToPay = borrowedAmount[msg.sender] + calculateInterest(msg.sender);

        require(balanceOf(msg.sender) >= totalToPay, "Your balance not enough");
        _transfer(msg.sender, address(this), totalToPay);
        emit Repay(msg.sender, totalToPay);
    }

    function calculateInterest(address _borrower) public view returns (uint256) {
        return borrowedAmount[_borrower] * interestRate / 100;
    }

    function setInterest(uint _newInterest) public whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        interestRate = _newInterest;
    }

    function adminTransfer(address _to, uint _amount) public whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        _transfer(address(this), _to, _amount);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }
}
