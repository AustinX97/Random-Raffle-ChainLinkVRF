# Proveably Random Raffle Smart Contract

## About

We want to create a 100% Random Lottery that can be proved to be random!

## What we want it to do?

1. User can enter by Paying a Fee
    1.1 The Winner takes home all the Ticket Fee
2. The Lottery will draw a winner after Time X, automatically!
3. This will be done programatically!
4. We will use Chainlink VRF and Chainlink Automation
    4.1 Chainlink VRF -> Randomness
    4.3 Chainlink Automation -> Time-based Triggers

  Course Notes:
  1) Follow the CEI Model -> 
  Checks; Required i.e: Errors that we need | Revert Statements
  Effects; Things that effects our own contract
  Interactions; Things that we do to communicate with other contracts

  2) When you write a code, design an outline // Pseudocode 
  For this Lottery Project, we need to do the following:
  1 People Pay to Participate in Lottery
  1.1 Create a Min Participation Fee
  1.2 Store the Participants in an array | Revert if Fee is Less / More
  1.3 Stop Entry after X Time | When we have XYZ Condition Set
  
  2 Random Winner is Picked after a Certain Time
  2.1 Generate a Random Number Using Chainlink VRF
  2.2 Use MOD Fn on Random Number to get a number RESULT b/w 0-9
  2.3 The Result will be Winner in Array Index RESULT
  2.4 Reset the Array of Winners (so we don't get same participant's in the next lottery without paying)

  
  3 Winner is Paid
  3.1 Pay the Winner, The Total Money stored in the contract | No Lottery Fee ATM
  

  4 The Proj Restarts for 2nd Lottery

  # Write Deploy Script
  1. Create a RUN() Fn that returns the Raffle Contract
  2. Since Raffle has constructor that takes values like Gas Lane, Enterance Fee etc, we need HelperConfig as we use will work on Loca, Test and Mainnet Chain
  3. # Helper Config
  3.1 Helper Config is also a Script
  3.2 Pass the values in "Struct NetworkConfig" from Raffle Constructor
  3.3 Create Fns, that RETURNS "Network Config of Chains", Sepolia, Anvil, Mainnet etc
  3.4 Create a Constructor for Chain ID: 
  3.4.1 Check with If|Else the Chain ID and then pass "activeNetworkConfig"

    # Coming Back to Deploy.s.sol
    1) If we donot have a Subscription ID, we create a new One (If SubID == 0)
    2) Then we Fund It
    3) We Launch our Raffle, & Since it's going to be a Brand New one, we want to Add Consumer  

# Create Interaction.s.sol File
  We need it bec we have to create a SubscriptionID on Chainlink Programitacally

  1) write a run FN that returns uint64 (bec subID is in uint 64)
  2) We need VRF Cordinator Add that we are getting from HelperConfig
  3) CreateSubscriptionUsingConfig Fn just takes the config (the VRF Address we pass through HelperConfig)

  4) We also create a createSubscriptionID FN (optional just to make it modular) which takes in the address (address vrfCordinator) and returns uint64
  5) This CreateSubscription Contract from Interactions.s.sol and Fn createSubscriptionID is used to create a Sub ID in the DeployRaffle.s.sol. Once it is done, we need to FUND IT!

  6) We create a New Contract in Interactions.s.sol: FundSubscription.
      We need: 1) Amount to Fund, SubId to Fund, vrfCordinatorV2 Address, and Chainlink Address 

  7) We also use multiple revamped external packages like LinkTokens, DevOpsTools by Cyfrin to minimize our work. 

  8) We Create another CONTRACT AddConsumer in Interactions.s.sol to Add consumer through script 
  3. Write Test That Works on Forked Mainnet



  # Write Test

  1. Write Test That Works on Local Chain
  2. Write Test That Works on Forked Testnet
  3. Write Test That Works on FOrked Mainnet

# Writing Test
    # Unit Test
  1) Check Raffle Starts with State = Open
  2) Check Players Pay Enough Eth to Participate
  3) Check Array of Participants is being updated / recorded
  4) Emits Events that Participant has entered the raffle!
   4.1) expectEmit FN in foundry works with Bool, and need emiter's adress (contract address)
     

   

