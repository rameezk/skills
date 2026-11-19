---
name: codebase-design
description: The shared vocabulary and principles for shaping code into deep modules - module, interface, implementation, depth, seam, adapter, leverage, locality. Use whenever a module is being designed, split, merged or otherwise reshaped, when choosing where a seam goes, when judging whether a module earns its place, or when a skill elsewhere has to talk about module shape.
---

# Codebase Design

Good structure here means **deep modules**: each one gives its callers a lot of behaviour for a small interface to learn, sits at a seam where it can be tested or swapped, and keeps everything about one concern in one place. This skill is the language for talking about that shape - in a design discussion, a spec, a test plan or a review - and the principles for choosing between shapes.

Two other sources of language sit beside this one. `docs/CONTEXT.md`, when it exists, names *what* the code is about; this vocabulary names *how it is shaped*. Use the domain terms for the concepts and these terms for the structure, never one in place of the other. The ADRs under `docs/adr/` record what is already settled: design inside them, and treat a shape that would contradict an accepted ADR as a new decision rather than something to slip in (see [[decision-context]]).

## Vocabulary

Whenever one of these ideas comes up, say its term and never a looser stand-in for it. Each term draws a line that a vaguer word would blur. That holds when an answer is written plainly too: keep the term, and explain it in passing if the reader may not know it, rather than swapping it for an everyday word.

- **Module** - anything callers use through an interface: a function, a class, a file, a package, or a slice that cuts across layers. Size plays no part in it.
- **Interface** - everything a caller has to know to use a module correctly. A signature covers only part of that; a caller also leans on what must be true before calling, which side effects happen, how it fails, and any set-up it needs first, and all of it counts.
- **Implementation** - the code behind the interface: what a caller never needs to know.
- **Depth** - how much behaviour a module delivers for each thing a caller must learn about its interface. A **deep** module hides a lot behind a little. A **shallow** module's interface is about as large as the work it does, so calling it is hardly easier than doing that work yourself. Depth is judged from the caller's side: an implementation split into many small pieces is still deep if callers see none of them.
- **Seam** - the spot a module's interface occupies, and so the spot where one piece of behaviour can be swapped for another while the code that calls it stays untouched. Picking that spot and picking what sits behind it are two separate calls.
- **Adapter** - a concrete piece of code that plugs into a seam and fulfils its interface, such as the real database client or an in-memory fake for tests. Calling something an adapter says which slot it fills, and nothing about how much code is inside it.
- **Leverage** - the payoff of depth for callers: each thing learned about the interface unlocks more behaviour, and the work done once inside is reused by every caller, tests included.
- **Locality** - the payoff of depth for maintainers: when something has to be fixed, changed or understood, there is one module to open rather than a hunt through every caller.

Say **implementation** when talking about what a module contains and **adapter** when talking about what fills a seam. One piece of code can be both; the word you pick says which question is on the table.

Some common words are left out on purpose:

- **"service"** and **"component"** - say module. Both carry framework and deployment baggage that says nothing about shape.
- **"API"** - say interface. "API" usually stops at the signature and leaves out the rest of what a caller relies on.
- **"boundary"** - say seam when you mean where something can be swapped, and interface when you mean what callers see. "Boundary" is used for too many things to pin either down.

## Principles

Name each principle when you use it, in the words of its bold heading, so a reader can tell which rule a judgement rests on.

- **The deletion test.** To judge whether a module earns its place, imagine deleting it and putting what it does back into its callers. If the complexity comes back - repeated in each caller, or pushed onto each of them to learn - the module was paying its way. If the complexity just disappears, because the module only handed calls along, it was a pass-through: shallow, and a candidate to fold into its caller or its neighbour. Report the result as "by the deletion test, this module is deep" or "... is shallow", followed by what the test showed.
- **The interface is the test surface.** Tests use a module the same way its callers do: through its interface, at its seam. If a test can only check something by going around the interface, into a private helper or internal state, take that as evidence the module is badly shaped and fix the shape rather than adding a back door. Seams that exist only inside a deep module, for its own implementation to use, stay out of its interface.
- **One adapter is a hypothetical seam; two adapters make a real one.** Count what actually plugs into a seam. Until there are two - commonly the live adapter plus a test double - the seam is a detour every reader must follow for no benefit, so leave it out until the second one exists.
- **Replace, don't layer.** When shallow modules are merged into a deeper one, write the tests at the new interface and delete the tests that pinned the old shallow pieces. Keeping both leaves the suite twice the size and tied to a structure that no longer exists.

## Going further

- **Deepening a module**, or merging a cluster of shallow ones: see [`deepening.md`](deepening.md) for how each kind of dependency shapes the result, where seams belong, and how the tests move.
- **Choosing between interfaces**, when a module's shape is still open: see [`design-it-twice.md`](design-it-twice.md) for drawing up several very different interfaces in parallel and comparing them before picking one.

## Hand-offs

- **A choice the user has to make** - which of several interfaces to build, where a seam goes, whether to merge two modules - is decided in [[refine]]. Lay out the options in this vocabulary with the one you would pick, and send the user there rather than settling it on your own.
- **A domain term that comes up or gets sharper** while designing goes into `docs/CONTEXT.md`, and **a structural decision that is hard to reverse** and clears the ADR bar is recorded as an ADR. Both go through [[decision-context]].
