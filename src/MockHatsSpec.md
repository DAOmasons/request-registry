Your `MockHats` contract is designed to simulate the behavior of the `IHats` interface from the Hats protocol in a testing environment. This mock contract is crucial for testing your `RequestRegistry` contract's interaction with the Hats protocol without having to deploy or interact with the actual Hats protocol contracts.

### Spec Sheet for MockHats Contract

#### Purpose
- To provide a controlled and predictable environment for testing the interaction between the `RequestRegistry` contract and the Hats protocol.
- To simulate various scenarios and states that could occur when interacting with the real `IHats` contract.

#### Key Functionalities
1. **isWearerOfHat Function**: Determines if a specified address is a wearer of a given hat ID.
2. **checkHatStatus Function**: Checks the status (active/inactive) of a specified hat ID.
3. **getHatEligibilityModule Function**: Retrieves the eligibility module address for a given hat ID.
4. **setWearerOfHat Helper Function**: Allows tests to set the wearer status for a hat ID.
5. **setHatStatus Helper Function**: Enables tests to set the status for a specific hat ID.
6. **setHatEligibilityModule Helper Function**: Permits tests to set the eligibility module for a hat ID.
7. **Other IHats Methods**: Includes all other methods defined in the `IHats` interface, either as empty implementations or returning simple values. These can be expanded as needed for specific testing scenarios.

#### How to Use the MockHats Contract

1. **Initialization**: Deploy the `MockHats` contract in your test setup. This is typically done in the `setUp` function of your test suite.

2. **Setting Up States**:
   - Use helper functions like `setWearerOfHat`, `setHatStatus`, and `setHatEligibilityModule` to configure the mock contract's state before executing your test cases. 
   - For example, if a test requires a specific address to be recognized as the wearer of a certain hat, use `setWearerOfHat` to set this state in the mock contract.

3. **Testing Interactions**:
   - In your test cases, after setting up the necessary states in `MockHats`, call functions on the `RequestRegistry` contract that interact with the Hats protocol.
   - Check whether the `RequestRegistry` contract responds correctly based on the simulated behavior of the `MockHats` contract.

4. **Asserting Outcomes**:
   - Verify that the `RequestRegistry` contract behaves as expected. This could include checking state changes, emitted events, or reverted transactions.
   - Use assertions to confirm that the interactions with the `MockHats` contract produce the desired outcomes in the `RequestRegistry` contract.

#### Example Test Case

```solidity
function testRequestRegistryInteraction() public {
    // Setup MockHats with desired states
    mockHats.setWearerOfHat(userAddress, hatId, true);
    mockHats.setHatStatus(hatId, true);

    // Interact with RequestRegistry
    requestRegistry.someFunctionThatInteractsWithHats(hatId, otherParams);

    // Assert expected outcomes
    assertTrue(requestRegistry.someState(), "Expected state change did not occur");
    // Additional assertions as needed
}
```

