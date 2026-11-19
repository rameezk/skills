# Deepening a module

Load this when a shallow module, or a cluster of them that keep changing together, is to be merged into one deeper module. Its terms are the ones defined in [`SKILL.md`](SKILL.md).

What shapes a deepening most is what the new module depends on. Sort each dependency into one of the four kinds below and name the kind out loud: it decides whether a seam is needed, what fills it, and what the tests run against. When a module has dependencies of several kinds, handle each by its own kind.

## Dependency kinds

### 1. In-process

Plain computation and in-memory state, with no I/O. Nothing stands in the way: merge the pieces, put the interface where callers need it, and test through that interface with the real code running. No seam and no adapter are called for.

### 2. Local, with a stand-in

Something outside the process that has a faithful local stand-in a test can run for real: a temporary directory for the file system, an embedded or throwaway database for the real one, a local broker for a queue. Deepen the module so it owns the dependency outright, and have the tests run the stand-in. Any seam stays inside the module; nothing about the dependency shows through its interface beyond what callers genuinely need to choose, such as a location.

### 3. Remote, but yours

Code you own that sits across a network or a process gap: another of your own programs, a worker reached over a queue, an internal endpoint. The logic belongs in one deep module on this side, with the transport behind a seam at that module's edge. Two adapters fill the seam - the real transport in production and an in-memory one in tests - which is exactly what makes it a real seam rather than a hypothetical one.

### 4. Third-party

A system you do not control: a payment provider, a mail sender, a vendor's hosted service. The deepened module takes it through a seam, and tests plug in a fake adapter that behaves as the provider is documented to. This is the only kind where a stand-in written for tests is the norm rather than a fallback.

## Seams inside and at the edge

A deep module often has seams inside its implementation that its own tests use, as well as the seam where its interface sits. Keep the inner ones out of the interface. Exposing a seam just because a test reaches for it makes the module shallower for every caller.

Before adding any seam, count its adapters. If only one would ever plug in, there is no seam yet, only indirection - leave it out.

## Moving the tests

Deepening is also a change to the test suite, and it runs in one direction:

1. Write the tests for the deepened module at its new interface, asserting on what callers can observe.
2. Once they cover the behaviour, delete the tests that pinned the old shallow pieces. They test a structure that no longer exists, and keeping them beside the new ones only doubles the suite.
3. A test that breaks under a refactor that leaves behaviour alone is testing past the interface. Rewrite it at the interface or drop it.
