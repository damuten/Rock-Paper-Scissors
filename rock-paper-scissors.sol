pragma solidity ^0.8.0;

contract RockPaperScissors {
    address public player1;
    address public player2;
    uint public betAmount;
    uint public revealDeadline;
    bytes32 public player1MoveHash;
    bytes32 public player2MoveHash;
    string public player1Move;
    string public player2Move;

    enum GameStatus { Created, MovesRevealed, Completed }
    GameStatus public status = GameStatus.Created;

    constructor() {
        // Initialize the contract with a minimum bet amount and reveal deadline
        betAmount = 100000000000000; // 0.0001 ether
        revealDeadline = block.timestamp + 2 minutes;
    }

    function register() public payable {
        require(status == GameStatus.Created, "Game is not in registration phase");
        require(msg.value >= betAmount, "Insufficient bet amount");

        if (player1 == address(0)) {
            player1 = msg.sender;
        } else if (player2 == address(0)) {
            player2 = msg.sender;
        }

        if (player1 != address(0) && player2 != address(0)) {
            status = GameStatus.MovesRevealed;
        }
    }

    function play(bytes32 moveHash) public {
        require(status == GameStatus.MovesRevealed, "Game is not in move phase");
        require(msg.sender == player1 || msg.sender == player2, "Not a registered player");

        if (msg.sender == player1) {
            player1MoveHash = moveHash;
        } else if (msg.sender == player2) {
            player2MoveHash = moveHash;
        }
    }

    function reveal(string memory clearMove, string memory password) public {
        require(status == GameStatus.MovesRevealed, "Game is not in reveal phase");
        require(msg.sender == player1 || msg.sender == player2, "Not a registered player");

        bytes32 expectedHash = keccak256(abi.encodePacked(clearMove, password));

        if (msg.sender == player1) {
            require(player1MoveHash == expectedHash, "Invalid move hash");
            player1Move = clearMove;
        } else if (msg.sender == player2) {
            require(player2MoveHash == expectedHash, "Invalid move hash");
            player2Move = clearMove;
        }

        if (bytes(player1Move).length > 0 && bytes(player2Move).length > 0) {
            determineWinner();
            status = GameStatus.Completed;
        }
    }

    function determineWinner() internal {
        require(bytes(player1Move).length > 0 && bytes(player2Move).length > 0, "Moves not yet revealed");

        if (keccak256(abi.encodePacked(player1Move)) == keccak256(abi.encodePacked(player2Move))) {
            // It's a draw, refund the bets
            payable(player1).transfer(betAmount);
            payable(player2).transfer(betAmount);
        } else if (
            (keccak256(abi.encodePacked(player1Move)) == keccak256(abi.encodePacked("rock")) && keccak256(abi.encodePacked(player2Move)) == keccak256(abi.encodePacked("scissors"))) ||
            (keccak256(abi.encodePacked(player1Move)) == keccak256(abi.encodePacked("paper")) && keccak256(abi.encodePacked(player2Move)) == keccak256(abi.encodePacked("rock"))) ||
            (keccak256(abi.encodePacked(player1Move)) == keccak256(abi.encodePacked("scissors")) && keccak256(abi.encodePacked(player2Move)) == keccak256(abi.encodePacked("paper")))
        ) {
            // Player 1 wins
            payable(player1).transfer(2 * betAmount);
        } else {
            // Player 2 wins
            payable(player2).transfer(2 * betAmount);
        }
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function whoAmI() public view returns (uint) {
        if (msg.sender == player1) {
            return 1;
        } else if (msg.sender == player2) {
            return 2;
        } else {
            return 0;
        }
    }

    function bothPlayed() public view returns (bool) {
        return status == GameStatus.MovesRevealed;
    }

    function bothRevealed() public view returns (bool) {
        return status == GameStatus.Completed;
    }

    function revealTimeLeft() public view returns (uint) {
        if (block.timestamp < revealDeadline) {
            return revealDeadline - block.timestamp;
        } else {
            return 0;
        }
    }
}
