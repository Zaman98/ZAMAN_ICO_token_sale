//SPDX-License-Identifier: GPL-3.0
     
    pragma solidity >=0.5.0 <0.9.0;

    interface ERC20Interface {
        function totalSupply() external view returns (uint);
        function balanceOf(address tokenOwner) external view returns (uint balance);
        function transfer(address to, uint tokens) external returns (bool success);
        
        function allowance(address tokenOwner, address spender) external view returns (uint remaining);
        function approve(address spender, uint tokens) external returns (bool success);
        function transferFrom(address from, address to, uint tokens) external returns (bool success);
        
        event Transfer(address indexed from, address indexed to, uint tokens);
        event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    }
     
     
    contract Cryptos is ERC20Interface{
        string public name = "Zaman";
        string public symbol = "ZAMAN";
        uint public decimals = 0; //18 is very common
        uint public override totalSupply;
        
        address public founder;
        mapping(address => uint) public balances;
        // balances[0x1111...] = 100;
        
        mapping(address => mapping(address => uint)) allowed;
        // allowed[0x111][0x222] = 100;
        
        
        constructor(){
            totalSupply = 1000000;
            founder = msg.sender;
            balances[founder] = totalSupply;
        }
        
        
        function balanceOf(address tokenOwner) public view override returns (uint balance){
            return balances[tokenOwner];
        }
        
        
        function transfer(address to, uint tokens) public virtual override returns(bool success){
            require(balances[msg.sender] >= tokens);
            
            balances[to] += tokens;
            balances[msg.sender] -= tokens;
            emit Transfer(msg.sender, to, tokens);
            
            return true;
        }
        
        
        function allowance(address tokenOwner, address spender) view public override returns(uint){
            return allowed[tokenOwner][spender];
        }
        
        
        function approve(address spender, uint tokens) public override returns (bool success){
            require(balances[msg.sender] >= tokens);
            require(tokens > 0);
            
            allowed[msg.sender][spender] = tokens;
            
            emit Approval(msg.sender, spender, tokens);
            return true;
        }
        
        
        function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success){
             require(allowed[from][msg.sender] >= tokens);
             require(balances[from] >= tokens);
             
             balances[from] -= tokens;
             allowed[from][msg.sender] -= tokens;
             balances[to] += tokens;
     
             emit Transfer(from, to, tokens);
             
             return true;
         }
    }

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
// deployed contract address: 0x59f11210cA3D31ec6a8FEc7E35F6267fC8EC5Dad
