// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AggregatorInterfaceUSDC {
  int256 value = 99984897;

  address public aggregator;

  constructor() {
    aggregator = address(new Aggregator());
  }

  function latestAnswer() public view virtual returns (int256) {
    return value;
  }

  function latestRoundData()
    public
    view
    virtual
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    return (
		99984897,
      value,
		block.timestamp,
		block.timestamp,
		99984897
    );
  }

  function setLatestAnswer(int256 _tcap) public {
    value = _tcap;
  }

  function decimals() external pure returns(uint256) {
    return 8;
  }

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 timestamp
  );
  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}


contract Aggregator {
    function minAnswer() external pure returns (int192) {
        return 1;
    }

    function maxAnswer() external pure returns (int192) {
        return type(int192).max;
    }
}
