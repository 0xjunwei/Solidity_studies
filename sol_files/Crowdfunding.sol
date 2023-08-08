//SPDX-License-Identifier: MIT
// Solidity Version
pragma solidity ^0.8.0;

// contract declaration
contract Crowdfunding {
    // prevent user or owner from withdrawing from the same txn block
    modifier nonReentrant() {
        require(!locked, "Reentrant call detected");
        locked = true;
        _;
        locked = false;
    }

    // As a object struct
    struct Project {
        // have a unsigned integer called id
        uint256 id;
        // String called title
        string title;
        // String
        string description;
        // Eth token amount needed for the project
        // 1 eth = 1000000000 GWEI, 9 zeroes
        // 1 eth = 1000000000000000000 WEI , 18 zeroes
        // eth-converter.com a website that you could use to check
        uint256 goalAmount;
        uint256 currentAmount;
        uint256 duration;
        uint256 startTime;
        // Eth Address to send to, payable property so the creator of the project can withdraw the funds
        address payable creator;
        // boolean
        bool completed;
        // Array of addresses of contributors
        address[] contributors;
    }

    // Public variable can be called from outside the smart contract
    // private can only be accessible within the smart contract or specific functions
    bool private locked;
    address private owner;
    uint256 public totalProjects;

    // mapping of uint256 to Project struct calling the mapping projects
    mapping(uint256 => Project) public projects;
    // mapping the address to uint256, keeping track of how much is pledged
    mapping(address => uint256) public contributions;
    // mapping uint256 to boolean, to keep track if certain projects have been completed
    mapping(uint256 => bool) completedProjects;

    // events are emitted to tell you certain txn have occurred.
    // frontend will lookout for events for updates with regards to txn
    event NewProjectCreated(
        uint256 projectId,
        string title,
        string description,
        uint256 goalAmount,
        uint256 duration,
        address creator
    );
    // Show information about the txn
    // Show contribution to project
    event NewContributionReceived(
        uint256 projectId,
        address contributor,
        uint256 amount
    );
    // tells you when project has been completed.
    event ProjectCompleted(uint256 projectId, uint256 totalAmount);
    // Set the owner of the smart contract to be the caller.
    // a type of function, it is used when a smart contract is deployed, it is the first one to be called
    constructor() {
        owner = msg.sender;
    }

    // constructor(string memory _title, string memory _description) to pass more variables
    // { inside body u store the the global variable above ^ }

    function createProject(
        // when using a string as args, the memory is a indicator of how you wish to use the string
        // do you want it to be disposed or stored permanently
        // memory to dispose, storage to store
        // _ infront is a naming convention
        string memory _title,
        string memory _description,
        uint256 _goalAmount,
        uint256 _duration
    ) public {
        // Require a condition
        require(_duration > 0, "Duration must be greater than zero");
        // total projects would be increased by 1
        totalProjects++;
        projects[totalProjects] = Project(
            totalProjects,
            _title,
            _description,
            _goalAmount,
            0,
            // Duration is by seconds so we must multiply it by 1 day
            _duration * 1 days,
            block.timestamp,
            payable(msg.sender),
            false,
            // initialize a new address for the contract
            new address[](0)
        );
        // emitting / triggering the event for new project created so frontend can see
        emit NewProjectCreated(
            totalProjects,
            _title,
            _description,
            _goalAmount,
            durationConverter(_duration),
            msg.sender
        );
    }
    // internal function only accessible from the smart contract or other contracts interacting with this one
    // pure means that we wont be viewing any of the variables in the global var list
    function durationConverter(uint256 _duration)
        internal
        pure
        returns (uint256)
    {
        uint256 duration = (((_duration * 24) * 60) * 60);
        return duration;
    }
    // 
    function contributeToProject(uint256 _projectId) public payable {
        // conditions to make sure project id not 0 must be 1 and above
        require(
            _projectId > 0 && _projectId <= totalProjects,
            "Invalid project ID"
        );
        // conditions to make sure proj not completed
        require(
            !projects[_projectId].completed,
            "Project is already completed"
        );
        // contribution must be more than 0
        require(msg.value > 0, "Contribution amount must be greater than zero");
        // ensure that project duration has not elapsed
        require(
            block.timestamp <=
                projects[_projectId].startTime + projects[_projectId].duration,
            "Project has ended"
        );
        // storing the data into the objects
        contributions[msg.sender] += msg.value;
        projects[_projectId].contributors.push(msg.sender);
        projects[_projectId].currentAmount += msg.value;
        checkIfProjectCompleted(_projectId);
        // generate a event that contribution received
        emit NewContributionReceived(_projectId, msg.sender, msg.value);
    }
    // private function just called within the project, internal can inherit this contract / associate still can call internal
    function checkIfProjectCompleted(uint256 _projectId)
        private
        // returns a boolean, if current amount exceeds the amt goal
        returns (bool)
    {
        if (
            projects[_projectId].currentAmount >=
            projects[_projectId].goalAmount
        ) {
            // emit project completed event is completed and change status
            if (!completedProjects[_projectId]) {
                projects[_projectId].completed = true;
                emit ProjectCompleted(
                    _projectId,
                    projects[_projectId].currentAmount
                );
                completedProjects[_projectId] = true;
            }
            return true;
        } else {
            return false;
        }
    }
    // public function, use the nonReentrant modifier
    function withdrawFunds(uint256 _projectId) public nonReentrant {
        // ensure only owner of project can call this project func
        require(
            projects[_projectId].creator == msg.sender,
            "Only project creator can withdraw funds"
        );
        // require project to be completed
        require(projects[_projectId].completed, "Project is not completed yet");
        // sends the funds to the creator
        projects[_projectId].creator.transfer(
            projects[_projectId].currentAmount
        );
    }
    // public function so query who the contributors are for a specific project id
    function getProjectContributors(uint256 _projectId)
        public
        view
        returns (address[] memory)
    {
        return projects[_projectId].contributors;
    }
    // return project details
    function getProjectDetails(uint256 _projectId)
        public
        view
        returns (
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            address,
            bool
        )
    {
        return (
            projects[_projectId].title,
            projects[_projectId].description,
            projects[_projectId].goalAmount,
            projects[_projectId].currentAmount,
            projects[_projectId].duration,
            projects[_projectId].creator,
            projects[_projectId].completed
        );
    }
}
