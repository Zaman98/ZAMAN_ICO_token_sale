    //SPDX-License-Identifier: GPL-3.0
     
    pragma solidity >=0.5.0 <0.9.0;
    
    import "/ZAMAN_token.sol";
    
    contract CryptosICO is Cryptos{
    address public admin;
    address payable public deposit;
    uint tokenPrice = 0.0001 ether;
    uint public hardcap = 300 ether;
    uint public raisedAmount;
    uint public saleStart = block.timestamp;
    uint public saleEnd = block.timestamp + 604800; //ico ends in a week;
    uint public tokenTradeStart = saleEnd + 604800; //ico ends in a week;
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.001 ether;

    enum State {beforeStart, running, afterEnd, halted}
    State public icoState;


    constructor(address payable _deposit){
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }

    function startICO() public {
        require(msg.sender == admin);
        icoState = State.running;
    }

    event Invest(address investor, uint value, uint tokens);

    function invest() public payable returns(bool success){
        require(block.timestamp < saleEnd, "the ICO has ended");
        require(msg.value >= minInvestment && msg.value <= maxInvestment, "please send the amount within the range.");
        require(icoState == State.running, "the ICO is not running");
        require(address(this).balance <= hardcap, "the sale target has been achieved");
    
        uint NoOfTokensToGive = msg.value / tokenPrice;
        uint refund = msg.value % 0.001 ether;
        balances[msg.sender] += NoOfTokensToGive;
        balances[founder] -= NoOfTokensToGive;
        payable(msg.sender).transfer(refund);
        raisedAmount += msg.value;
        deposit.transfer(msg.value - refund);
        emit Invest(msg.sender, (msg.value - refund), NoOfTokensToGive);

        return true;
    }

    receive() payable external{
        invest();
    }

    function endICO() public {
        require(msg.sender == admin);
        icoState = State.afterEnd;
    }

    function haltICO() public {
        require(msg.sender == admin);
        icoState = State.halted;
    }

    function resumeICO() public {
        require(msg.sender == admin);
        require(icoState == State.halted);
        icoState = State.running;
    }

    function changeDepositAddress(address payable _newDeposit) public{
        require(msg.sender == admin);
        deposit = _newDeposit;
    }

    function getCurrentState() public returns(State){
        return icoState;
    }

    function transfer(address to, uint tokens) public override returns(bool success){
        require(block.timestamp > tokenTradeStart, "the trading of this token has not started yet");
        Cryptos.transfer(to, tokens);
        return true;
    }

     function transferFrom(address from, address to, uint tokens) public override returns (bool success){
          require(block.timestamp > tokenTradeStart, "the trading of this token has not started yet");
          Cryptos.transferFrom(from, to, tokens);
          return true;
     }
    
    function burn() public returns(bool){
        require(icoState == State.afterEnd);
        balances[founder] = 0;
        return true;
    }
}
