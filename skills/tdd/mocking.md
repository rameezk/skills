# When to mock

Load this when a test needs to stand in for something it should not really call. Mocking is where implementation-coupled tests are born, so the default is: don't, unless the seam leads to something outside your control. A mock or fake is an adapter in the sense [[codebase-design]] gives the word, and whether a dependency gets a seam at all is settled by its kind in that skill's guide to deepening a module; this file covers only how a test uses one.

## Mock only at seams onto the outside

Mock:

- third-party systems (payment, email, a vendor's hosted platform)
- databases - sometimes; prefer a real test database
- time and randomness
- the file system - sometimes

Do NOT mock:

- your own modules, classes, or functions
- internal collaborators
- anything you control

Mocking an internal collaborator couples the test to how the code is wired, so it breaks on refactors that change nothing observable. That is the single most common way a test suite becomes painful to change. Test through the interface at the seam and let the real implementation run.

## Shape seams so a test adapter fits

**Inject dependencies** rather than constructing them inside:

```
# Easy to fill the seam with a test adapter
processPayment(order, paymentClient) -> paymentClient.charge(order.total)

# Hard - reaches out and builds its own client from the environment
processPayment(order) -> new PaymentClient(env.KEY).charge(order.total)
```

**Prefer specific, SDK-style operations over one generic fetcher.** Each operation is then mockable on its own, with no conditional logic in the test setup:

```
# GOOD - each call is independently substitutable
api.getUser(id)
api.getOrders(userId)
api.createOrder(data)

# BAD - the mock needs branching to decide what to return
api.fetch(endpoint, options)
```

The SDK-style shape means each stub returns one known shape, no branching in setup, and it is obvious from the test which operations across the seam a behaviour exercises.
