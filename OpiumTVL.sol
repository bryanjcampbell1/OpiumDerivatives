pragma solidity ^0.5.16;

import "@chainlink/contracts/src/v0.5/ChainlinkClient.sol";

import "./Interface/IOracleId.sol";
import "./OracleAggregator.sol";


contract DefiPulseTotalLockedValueOracle is IOracleId, ChainlinkClient {

    string public project = 'Opium Network'; 
    address public owner;
    uint256 public timeStamp;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    OracleAggregator public oracleAggregator;

    uint256 public totalLockedValue;
    
    constructor() public {
        
        oracle = 0x29CE4C76e6aaA0670751290AC167eeF4B1c6F3E3; // oracle address
        jobId = "e28b5722116f4d8c946a02460450db7b"; //job id
        fee = 1 * 10 ** 18; // 1 LINK
        setPublicChainlinkToken();
        owner = msg.sender;
        emit MetadataSet("{\"author\":\"Bryan.Campbell\",\"description\":\"OpiumNetworkTVLOracle\",\"asset\":\"OpiumTVL\",\"type\":\"onchain\",\"source\":\"chainlink\",\"logic\":\"none\"}");
        
    }


    function fetchData(uint256 timestamp) external payable {

        timeStamp = timestamp;

        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfillTotalLockedValue.selector);
        req.add("project", project);
        sendChainlinkRequestTo(oracle, req, fee);

    }
    
    function fulfillTotalLockedValue(bytes32 _requestId, uint256 _tvl) public recordChainlinkFulfillment(_requestId) {
        emit RequestTVLFullfilled(_requestId, _tvl);
        totalLockedValue = _tvl;
        oracleAggregator.__callback(timeStamp, _tvl);
    }
    event RequestTVLFullfilled(
        bytes32 indexed requestId,
        uint256 indexed totalLockedValue
      );


    //helper chainlink functions
    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
          return 0x0;
        }
        assembly { // solhint-disable-line no-inline-assembly
          result := mload(add(source, 32))
        }
    }

    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    )
    public
    onlyOwner
    {
        cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
    }

  
  // withdrawLink allows the owner to withdraw any extra LINK on the contract
    function withdrawLink()
    public
    onlyOwner
    {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    


    //empty but necessary for Interface

    function recursivelyFetchData(uint256 timestamp, uint256 period, uint256 times) external payable {
    }

    function calculateFetchPrice() external returns (uint256) {
    }
}





