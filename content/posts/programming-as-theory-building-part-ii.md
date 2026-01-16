+++
title = "Programming as Theory Building, Part II: When Institutions Crumble"
description = "Software development teams are institutions. AI degrades them in ways we're only beginning to understand."
date = 2025-01-17
author = "Christian Ekrem"
tags = ["programming", "software-engineering", "theory", "llm", "ai", "craft", "institutions"]
draft = true
+++

In my [previous post on Peter Naur's "Programming as Theory Building"](/posts/programming-as-theory-building-naur/), I argued that a program is not its source code—it's the shared mental model held by the people who built it. When those people leave (or never understood it in the first place), the theory dies, and you're left with a codebase that works but nobody truly comprehends.

I've been thinking about this more, and I've come to believe the problem goes deeper than individual developers losing their edge. It's not just that _people_ are losing the ability to build theories. It's that the _institutions_ where theory-building happens—our teams, our companies, our profession—are being systematically degraded.

## Software Teams Are Institutions

I recently read a draft paper by two Boston University law professors, Woodrow Hartzog and Jessica Silbey, called "How AI Destroys Institutions." Their argument hit me like a truck: AI systems aren't just tools that _can_ be misused—their core design is fundamentally incompatible with how institutions function.

Now, when they say "institutions," they're talking about universities, the legal system, journalism, democracy. Big stuff. But as I read, I kept seeing my own world reflected back at me. Because software development teams _are_ institutions, even if we don't usually think of them that way.

Consider what makes an institution work:

- **Hierarchies of expertise**: Junior developers learn from seniors, who learned from principals, who learned from architects. Knowledge flows through these relationships.
- **Shared purpose and rules**: Coding standards, architectural decisions, domain models—the "rules of the game" that let a group of individuals function as a coherent team.
- **Decision-making with accountability**: Code reviews, design discussions, ADRs. Points where someone can say "wait, that doesn't fit our model" and actually be heard.
- **Human relationships and solidarity**: The trust that makes you ask a teammate for help instead of flailing alone. The camaraderie that makes you _want_ the team to succeed.

These aren't just nice-to-haves. They're the machinery through which _theory gets built and transmitted_. Naur's insight was about individual understanding, but that understanding doesn't exist in a vacuum. It lives in the institution—in the conversations, the reviews, the mentoring, the shared struggle of building something together.

## The Three Ways AI Degrades Institutions

Hartzog and Silbey identify three "destructive affordances" of AI. Not things AI _might_ do if misused, but things AI _does by design_ when deployed the way its creators intend:

### 1. AI Undermines Expertise

This one connects directly to what I wrote before about "reflexive AI usage" robbing us of growth opportunities. But the institutional angle makes it worse.

When juniors accept AI-generated code they don't understand, they're not building theory. Fine, we knew that. But they're _also_ not asking seniors for help, not struggling through code review, not having those hallway conversations where knowledge actually transfers. The institution's pipeline for developing expertise—which took decades to build—gets bypassed entirely.

And here's the kicker: AI can only look backwards. It's trained on what already exists. The institution's ability to _evolve_—to develop new patterns, new approaches, new understanding in response to changing circumstances—depends on humans doing the hard intellectual work of figuring out what doesn't exist yet. When that atrophies, the institution ossifies.

As the paper puts it: when AI is "right," people become less skilled. When AI is "wrong," you need skilled people to catch and fix the errors. Either way, the institution suffers.

A recent MIT Media Lab study makes this painfully concrete. Researchers had students write essays, with one group using ChatGPT and others using traditional methods. The result? 83% of the ChatGPT group couldn't quote anything they'd written. They didn't remember. They didn't feel like the work was theirs.

That's not just "they didn't learn as much." That's _they didn't build any theory at all_. The understanding never formed. And if it never formed, it can never be transferred to the next generation of the institution.

### 2. AI Short-Circuits Decision-Making

Institutions need friction. Not bureaucratic friction for its own sake, but the productive kind—moments where someone can push back, ask questions, challenge assumptions.

Think about a good code review. It's not just checking for bugs. It's a point of _contestation_ where the team's shared understanding gets tested and refined. "Why did you do it this way?" "Does this fit our domain model?" "Have you considered how this interacts with X?" These questions are how theory gets sharpened and transmitted.

AI-generated code arrives without any of this context. There's no `git blame` pointing to a human you can ask. No PR discussion explaining the trade-offs. The code exists in what I called a "theoretical vacuum"—and when it enters your codebase, it imports architectural decisions that nobody on your team actually made.

The institution's decision-making process gets flattened. Rules become invisible. And when rules are invisible, they can't be questioned, iterated on, or adapted to changing circumstances. That's how institutions become rigid and eventually irrelevant.

### 3. AI Isolates Humans

This is the one that surprised me most, but I think it might be the most damaging in the long run.

Institutions run on human connection. The trust that makes someone ask for help instead of hiding their confusion. The solidarity that makes a team want to build something good together, not just ship features. The friction of working with people who think differently than you—which is uncomfortable but essential for growth.

AI offers a sycophantic alternative. It never pushes back. It never says "I don't understand what you're trying to do." It never asks the uncomfortable questions that force you to actually think through your approach. It tells you what you want to hear, generates what you asked for, and moves on.

Every minute a developer spends with an AI assistant is a minute not spent pairing with a colleague, not asking a question in Slack, not having the awkward conversation that might have revealed a fundamental misunderstanding. The paper calls this "displacing opportunities for human connection," and I think that's exactly right.

Hartzog and Silbey cite a study showing that co-workers who receive "workslop" (AI outputs that make more work or make no sense) start seeing their colleagues differently: less creative, less capable, less reliable, less trustworthy. That's institutional trust eroding in real-time.

There's a darker psychological dimension here too. Designer Mike Monteiro recently pointed out that the AI industry's success depends on convincing people they're inadequate. Every time you open Google Docs and see those "Help me write" buttons, the message is clear: _you probably can't do this yourself_. We are not being built up by helpful tools. We're being torn down by tools that insist we can't function without them.

## The Theory Lives in the Institution

Here's where Naur's insight combines with the institutional perspective in a way that keeps me up at night.

Remember: the program is not the code, it's the theory. But where does the theory actually live? Not just in individual heads, but in the _relationships between those heads_. In the shared understanding built through years of working together. In the institutional memory of why we do things this way and not that way.

When AI undermines expertise, short-circuits decision-making, and isolates humans, it's not just making individual developers worse. It's destroying the vessel that holds and transmits the theory itself.

A junior who never struggles through a difficult problem doesn't just fail to learn—they fail to develop the relationships with seniors that would have formed during that struggle. An AI-generated PR that nobody truly reviews doesn't just introduce risky code—it skips the conversation that would have refined everyone's understanding of the domain. A developer who "pairs" with an AI instead of a colleague doesn't just miss out on connection—they miss the creative friction that produces genuinely new ideas.

The theory, in other words, doesn't just die with individuals. It dies when the institution that builds and sustains it crumbles.

## Where AI Actually Helps (With Clear Constraints)

I'm not saying never use AI. [As I've written before](/posts/coding-as-craft-going-back-to-the-old-gym/), AI excels at automating the boring parts—and there's nothing wrong with that.

But the key word is _constraints_. The successful uses I've seen share a pattern:

**The human sets the theory, and the AI executes within it.**

For example: "I've written tests for these three controllers following this pattern. Here's how they behave, here are the edge cases I'm covering, here's why. Now write tests for these two other controllers using the same approach. Ask me whenever something doesn't translate 1:1."

Notice what's happening here. The human has done the theory-building work: understanding the domain, making architectural decisions, establishing patterns. The AI is doing rote execution _within_ that established framework. And crucially, there's a checkpoint: "ask me whenever something doesn't translate 1:1." The human stays in the loop, ready to exercise judgment when the pattern breaks down.

This is AI as a tool, subordinate to human expertise and institutional decision-making. It's not AI as a replacement for the hard intellectual work.

The difference matters. Boilerplate generation, documentation summarization, test scaffolding within an established pattern—these don't require theory-building. They don't involve the architectural decisions and domain understanding that give a codebase its coherence. Using AI for these is like using a calculator for arithmetic: it frees up mental energy for the work that actually matters.

But "write me a feature" or "fix this bug" or "refactor this module"—these _do_ involve theory. They require understanding why things are the way they are and how they should evolve. Offloading this to AI doesn't just skip the struggle. It skips the institutional processes that would have refined that theory and transmitted it to others.

## What We're Actually Fighting For

The AI boosters will tell you this is all about efficiency. "AI systems are just tools," they say. "They help us do what we were going to do anyway, only faster."

But that framing misses what institutions actually _are_. They're not just machines for producing output. They're mechanisms for building expertise, making good decisions, and fostering the human connections that make it all worthwhile. Speed those things up too much and they stop working.

What we're fighting for isn't just our individual craft (though that matters). It's the institutions that make software development a _profession_ rather than just a job. The hierarchies of mentorship that turn juniors into seniors. The decision-making processes that keep codebases coherent over time. The human relationships that make teams more than the sum of their parts.

And maybe it goes deeper than that. Human beings are _made_ to create. It's not an accident or a mere adaptation—it's fundamental to who we are, how we're designed. A child draws an orange on the first day of art class without hesitation, without permission, without worrying whether they're "good enough." That impulse to make marks on the world, to leave evidence of our existence, to build things—it's in our bones. And when we're convinced we can't create, something essential gets stolen from us.

Monteiro puts it bluntly: once you convince people they can't express themselves, it's that much easier to convince them they can't govern themselves. The path from "let AI write your code" to "let AI make your decisions" to "you're not competent to have a say in how things work" is shorter than we think.

These institutions took decades to build. They're far more fragile than we realized.

## The Center Cannot Hold

Hartzog and Silbey end their paper with a warning: "Because AI is anathema to the well-being of our critical institutions, absent rules mitigating AI's cancerous spread, the only roads left lead to social dissolution."

That sounds dramatic for a legal academic paper. But I think they're right—and I think it applies to our institutions too.

Software development teams that fully embrace "reflexive AI usage" will find their expertise pipelines broken, their decision-making processes hollowed out, their human connections atrophied. The theory will die. The code will remain, but nobody will understand it. And then the institutional knowledge will be gone, and no amount of AI will bring it back.

In my previous post, I wrote: "When the dust of this Null-Stack Vibe Bonanza has settled, they'll once again be looking for senior developers."

I still believe that. But I'm now more worried about whether there will be any institutions left to produce them.
