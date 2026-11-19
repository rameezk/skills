# Deepening a module

Load this when a shallow module, or a cluster of them that keep changing together, is to be merged into one deeper module. Its terms are the ones defined in [`SKILL.md`](SKILL.md).

What shapes a deepening most is what the new module depends on. Sort each dependency into one of the four kinds below and name the kind out loud: it decides whether a seam is needed, what fills it, and what the tests run against. When a module has dependencies of several kinds, handle each by its own kind.

## Dependency kinds

### 1. In-process

Logic that never leaves the process: calculations and data held in memory, with nothing read from or written to the outside. Nothing stands in the way: merge the pieces, put the interface where callers need it, and test through that interface with the real code running. No seam and no adapter are called for.

### 2. Local, with a stand-in

Something outside the process that has a faithful local stand-in a test can run for real: a temporary directory for the file system, an embedded or throwaway database for the real one, a local broker for a queue. Deepen the module so it owns the dependency outright, and have the tests run the stand-in. Keep the dependency entirely inside the module: callers see only what they actually have to choose, such as a location.

### 3. Across the network, and yours

Code you own that sits across a network or a process gap: another of your own programs, a worker reached over a queue, an internal endpoint. The logic belongs in one deep module on this side, with the transport behind a seam at that module's edge. Two adapters fill the seam - the real transport for live use, and one that keeps everything in memory for tests - which is exactly what makes it a real seam rather than a hypothetical one.

### 4. Third-party

A system you do not control: a payment provider, a mail sender, a vendor's hosted platform. The deepened module takes it through a seam, and tests plug in a fake adapter. Unlike the in-memory adapter for your own code in kind 3, this fake imitates a system you cannot see inside, so keep it to what the provider documents and nothing more.

## Seams and tests

The seam rules and "replace, don't layer" in [`SKILL.md`](SKILL.md) apply as they stand. The one thing deepening adds is order: the old tests go only after the new ones cover the behaviour, since removing them first leaves a stretch where nothing guards it.
