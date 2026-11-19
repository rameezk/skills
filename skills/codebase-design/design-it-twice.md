# Design it twice

Load this when a module's interface is still open and worth getting right: before deepening a module, before adding one that many callers will lean on, or whenever the user asks to see alternatives. The first interface that comes to mind is rarely the best one, and a single designer weighing options in one head tends to produce variations on that first idea. So the alternatives are drawn up apart from each other, each pulled in a different direction, and only then compared. Its terms are the ones defined in [`SKILL.md`](SKILL.md).

## 1. Lay out the problem

Before any alternative is drawn up, write the problem down for the user:

- what callers need from the module, and which callers matter most
- the constraints any interface has to meet, including the ADRs it must sit inside
- each dependency and its kind, from [`deepening.md`](deepening.md)
- where it helps, a handful of lines showing how a caller works today, so the constraints have something concrete to point at

Post this to the user, then start step 2 without waiting for a reply.

## 2. Draw up the alternatives apart

Draw up at least three alternatives, each by its own sub-agent with a fresh context, launched together so they run in parallel and none sees another's answer. If the harness cannot launch sub-agents, draw them up one at a time and finish each before looking at the next.

Give each one the same brief - the files involved, how they are coupled, the dependency kinds, what would sit behind the seam, this skill's vocabulary and the project's terms from `docs/CONTEXT.md` - and one steer of its own, so they pull apart:

- **Smallest interface** - as few entry points as possible, each carrying as much behaviour as it can.
- **Widest reach** - an interface general enough to serve many uses and grow without changing shape.
- **Easiest common call** - make what the most frequent caller does trivial, even at some cost to the rare ones.
- **Seams first** - when dependencies cross a seam, design around the seams and their adapters.

Ask each to return:

1. the interface: its entry points, their inputs and outputs, and the ordering, errors and guarantees a caller relies on
2. a short example of a caller using it
3. what stays hidden behind the interface
4. its seams and adapters, if any, and why each seam is real
5. where it is strong and where it is weak

## 3. Compare and recommend

Show each alternative in full, on its own, before any comparison. Then set them against each other on three things:

- **depth** - how much behaviour each gives for what a caller has to learn
- **locality** - where a future change or bug would land in each
- **seam placement** - where each puts its seams, and whether they are real

Then say which you would build and why. If the strongest answer borrows pieces from more than one alternative, recommend that mix and say which piece came from where. Take a position; a list with no pick leaves the user to do the comparison again.

Which one gets built is the user's call. When it is still open, send it to [[refine]]; once it is settled and clears the ADR bar, record it through [[decision-context]].
