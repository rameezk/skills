# Design it twice

Load this when a module's interface is still open and worth getting right: before deepening a module, before adding one that many callers will lean on, or whenever the user asks to see alternatives. An interface settled at the first attempt is usually just the first one thought of, and a designer considering options alone keeps circling back to it. So the alternatives are drawn up apart from each other, each pulled in a different direction, and only then compared. Its terms are the ones defined in [`SKILL.md`](SKILL.md).

## 1. Lay out the problem

Before any alternative is drawn up, write the problem down for the user:

- what callers need from the module, and which callers matter most
- the constraints any interface has to meet, including the ADRs it must sit inside
- each dependency and its kind, from [`deepening.md`](deepening.md)
- where it helps, a handful of lines showing how a caller works today, so the constraints have something concrete to point at

Post the write-up for the user, then start step 2 without waiting for a reply.

## 2. Draw up the alternatives apart

Hand each alternative to a separate sub-agent that starts from a clean context. Aim for three or more, and start them all at once so no draft can see another. If the harness cannot launch sub-agents, draw them up one at a time and finish each before looking at the next.

Give each one the same brief - the files involved, how they are coupled, the dependency kinds, what would sit behind the seam, this skill's vocabulary and the project's terms from `docs/CONTEXT.md` - and one steer of its own, so they pull apart:

- **Fewest calls** - a caller gets by with one to three calls, and each call does as much as it can.
- **Room to grow** - the shape copes with callers and needs that do not exist yet.
- **The usual caller first** - find the caller that shows up most and make its code one obvious line, accepting more work for unusual callers.
- **Dependencies drive it** - where dependencies cross a seam, decide the seams and what plugs into each before anything else.

Each one hands back its interface in full, in the sense [`SKILL.md`](SKILL.md) gives the word, then a few lines of caller code using it, what it keeps hidden, the seams it relies on with what fills each, and an honest note on its weak spots.

## 3. Compare and recommend

Show each alternative in full, on its own, before any comparison. Then set them against each other on three things:

- **depth** - how much behaviour each gives for what a caller has to learn
- **locality** - where a future change or bug would land in each
- **seam placement** - where each puts its seams, and whether they are real

Then say which you would build and why. If the strongest answer borrows pieces from more than one alternative, recommend that mix and say which piece came from where. Take a position; a list with no pick leaves the user to do the comparison again.

Which one gets built is the user's call. When it is still open, send it to [[refine]]; once it is settled and clears the ADR bar, record it through [[decision-context]].
