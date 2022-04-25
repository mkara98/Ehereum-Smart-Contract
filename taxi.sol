pragma solidity >=0.7.0 <0.8.0;

contract TaxiContract{
    
    //Start State Veriables
    
    //Owner
    
    address public owner;
    
    
    //Participants
    
    struct Participants{
        
        address payable participantsAdress;
        uint balance;
        bool approveCar;
        bool approveSell;
        bool approveDriver;
        uint dividendMoney;
    }
    
    
    mapping (address => Participants)  participantsMap;
    mapping (address => uint)  balances;
    uint public dividendTime;
    
    Participants[] public participantsArray;
    uint public totalParticipant = 0;
    
    
    //Manager
    
    address public managerAddress;
    uint public payCarTime;
    
    //Taxi Driver
    
    struct TaxiDriver{
        address payable driverAddress;
        uint salary;
    }
    TaxiDriver taxiDriver;
    address payable public tempDriverAddress;
    uint public tempDriverSalary;
    address public taxiDriverAddress = taxiDriver.driverAddress;
    
    uint public driverReleaseSalary;
    uint public releaseSalaryTime;
    
    //Car Dealer
    address payable public  carDealerAddress;
   
    
    //Contract Balance
    uint public contractBalance = 0;
    
    //Owned Car;
    uint ownedCar;
    
    //Proposed Car
     struct proposedCar{
        uint carId;
        uint price;
        uint offerValidTime;
        uint approvalState;
    }
    
    proposedCar public _proposedCar;
    proposedCar public _repurchaseProposedCar;
    
    
    
    //Proposed Repurchase
     struct proposedRepurchase{
        uint price;
        string offerValidTime;
        uint approvalState;
        
    }
    
    uint fixedExpenses = 10 ether;
    uint public participationFee = 10 ether;
    
    
    bool isParticipant = false;
    
    uint public ApprovalDriverState = 0;
   
    
    //Finish State Variable
    
    modifier onlyManager(){
        require(msg.sender == managerAddress, "Only manager can call this function");
        _;
    }
    
    modifier onlyCarDealer(){
        require(msg.sender == carDealerAddress, "Only car dealer can call this function");
        _;
    }
    
    modifier onlyDriver(){
        require(msg.sender == taxiDriver.driverAddress, "Only driver can call this function");
        _;
    }
    
    function onlyParticipants()public{
       
        for(uint i=0; i< participantsArray.length; i++){
            if(msg.sender == participantsArray[i].participantsAdress){
                isParticipant = true;
            }
        }
        
    }
    
    constructor(address _managerAddress){
        
        owner = msg.sender;
        managerAddress = _managerAddress;
        balances[owner] = owner.balance;
        balances[managerAddress] = managerAddress.balance;
    }
    
    fallback() external  {
        uint x;
        x = x + 1;
  }
    
    
    function join() public payable{
        require(msg.value == participationFee,"Participation fee must be 10 ether");
        require(totalParticipant < 9, "Total participation number can not be greater than 9");
        Participants memory newParticipant;
        address payable userAddress = msg.sender;
        newParticipant.participantsAdress = userAddress;
        balances[msg.sender] = 0;
        participantsMap[userAddress].approveCar = false;
        participantsMap[userAddress].approveSell = false;
        participantsMap[userAddress].approveDriver = false;
        participantsMap[userAddress].dividendMoney = 0;
        participantsArray.push(newParticipant);
        totalParticipant += 1;
        contractBalance += msg.value;
    }
    
    
    function SetCarDealer(address payable _carDealerAddress) onlyManager public{
        carDealerAddress = _carDealerAddress;
        
    }
    
    function CarProposeToBusiness(uint _carId, uint _price, uint _offerValidTime, uint _approvalState) onlyCarDealer public {
        
        _proposedCar.carId = _carId;
        _proposedCar.price = _price * 1000000000000000000;
        _proposedCar.offerValidTime = block.timestamp + (_offerValidTime * 1 days);
        _proposedCar.approvalState = _approvalState;
        for(uint i=0; i < participantsArray.length; i++){
                participantsMap[participantsArray[i].participantsAdress].approveCar = false;
         }
        
    }
    
    function ApprovePurchaseCar() public{
        onlyParticipants();
        require(isParticipant == true, "Only participants can call this function");
        require(participantsMap[msg.sender].approveCar == false, "Participant already approve purchase car");
        _proposedCar.approvalState += 1;
        participantsMap[msg.sender].approveCar = true;
        isParticipant = false;
        
    }
    
    function PurchaseCar() onlyManager public payable{
        require(totalParticipant -  _proposedCar.approvalState <  _proposedCar.approvalState, "Proposed car is not approved by more than half of participants");
        require(block.timestamp < _proposedCar.offerValidTime, "Offer valid time has passed");
        uint amount = _proposedCar.price;
        contractBalance -= amount;
        ownedCar = _proposedCar.carId;
        carDealerAddress.transfer(amount);
        
    }
    
    function RepurchaseCarPropose(uint _carId, uint _price, uint _offerValidTime, uint _approvalState) onlyCarDealer public {
        require(ownedCar == _carId);
        _repurchaseProposedCar.carId = _carId;
        _repurchaseProposedCar.price = _price * 1000000000000000000;
        _repurchaseProposedCar.offerValidTime = block.timestamp + (_offerValidTime * 1 days);
        _repurchaseProposedCar.approvalState = _approvalState;
         for(uint i=0; i < participantsArray.length; i++){
                participantsMap[participantsArray[i].participantsAdress].approveSell = false;
         }
    }
    
    function ApproveSellProposal() public{
        onlyParticipants();
        require(isParticipant == true, "Only participants can call this function");
        require(participantsMap[msg.sender].approveSell == false, "Participant already approve repurcahse car");
        _repurchaseProposedCar.approvalState += 1;
        participantsMap[msg.sender].approveSell = true;
        isParticipant = false;
    }
    
    function Repurchasecar() onlyCarDealer public payable{
        require(totalParticipant - _repurchaseProposedCar.approvalState < _repurchaseProposedCar.approvalState,"Repurchased car is not approved by more than half of participants");
        require(block.timestamp < _repurchaseProposedCar.offerValidTime, "Offer valid time has passed");
        require(msg.value ==  _repurchaseProposedCar.price, "Repurchased car price must equal entered value");
        contractBalance += _repurchaseProposedCar.price;
        
    }
    
    
    function ProposeDriver(address payable _newDriverAddress, uint _salary) onlyManager  public{
        tempDriverAddress = _newDriverAddress;
        tempDriverSalary = _salary;
         for(uint i=0; i < participantsArray.length; i++){
                participantsMap[participantsArray[i].participantsAdress].approveDriver = false;
         }
        
    }
    
    function ApproveDriver() public{
        onlyParticipants();
        require(isParticipant == true, "Only participants can call this function");
        require(participantsMap[msg.sender].approveDriver == false,"Participant already approve driver" );
        
        ApprovalDriverState += 1;
        
        participantsMap[msg.sender].approveDriver = true;
        isParticipant = false;
        
    }
    
    function SetDriver() onlyManager public{
        require(totalParticipant - ApprovalDriverState < ApprovalDriverState,"Driver is not approved by more than half of participants");
        taxiDriver.driverAddress = tempDriverAddress;
        taxiDriver.salary = tempDriverSalary * 1000000000000000000 ;
        
    }
    
    function FireDriver() onlyManager public{
        
        taxiDriver.driverAddress.transfer(taxiDriver.salary);
        taxiDriver.driverAddress = 0x0000000000000000000000000000000000000000;
        
    }
    
    function PayTaxiCharge() public payable{
        
        contractBalance += msg.value;
        
    }
    function ReleaseSalary() onlyManager  public{
        require(block.timestamp > releaseSalaryTime + 30 days, "This function can not be called before 1 months");
        driverReleaseSalary += taxiDriver.salary;
        contractBalance -= taxiDriver.salary;
        releaseSalaryTime = block.timestamp;
        
    }
    
    function GetSalary() onlyDriver public{
        require(driverReleaseSalary > 0, "Driver has no money");
        taxiDriver.driverAddress.transfer(driverReleaseSalary);
        driverReleaseSalary = 0;
        
    }
    
    function PayCarExpenses() onlyManager public{
         require(block.timestamp > payCarTime + 180 days, "This function can not be called before 6 months");
         carDealerAddress.transfer(fixedExpenses);
         payCarTime = block.timestamp;
         contractBalance -= fixedExpenses;
        
    }
    
    function PayDividend() onlyManager public{
         require(block.timestamp > dividendTime + 180 days, "This function can not be called before 6 months");
         if(payCarTime + 180 days < block.timestamp){
            carDealerAddress.transfer(fixedExpenses);
            payCarTime = block.timestamp;
            contractBalance -= fixedExpenses;
         }
          if(releaseSalaryTime + 30 days < block.timestamp){
            driverReleaseSalary += taxiDriver.salary;
            contractBalance -= taxiDriver.salary;
            releaseSalaryTime = block.timestamp;
         }
         uint willDividendMoney = contractBalance / totalParticipant;
         for(uint i=0; i < participantsArray.length; i++){
             participantsMap[participantsArray[i].participantsAdress].dividendMoney += willDividendMoney; 
             contractBalance -= willDividendMoney;
         }
         dividendTime = block.timestamp;
    }
    
    function GetDividend() public{
        onlyParticipants();
        require(isParticipant == true, "Only participants can call this function");
        require(participantsMap[msg.sender].dividendMoney > 0, "Participant has no money");
        uint currentMoney = participantsMap[msg.sender].dividendMoney;
        participantsMap[msg.sender].dividendMoney = 0;
        msg.sender.transfer(currentMoney);
        isParticipant = false;
    }
    
}