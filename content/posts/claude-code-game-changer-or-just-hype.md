+++
title = "Claude Code: Game Changer or Just Hype?"
date = "2025-06-10"
description = "Examining the role of AI coding assistants in the craft of software development - are they revolutionary tools or just shiny distractions?"
tags = ["ai", "coding", "craft", "tools", "claude"]
+++

Last week, I watched two very different developers encounter Claude Code for the first time. The contrast in their reactions perfectly captures the tension I've been feeling about AI coding assistants lately.

For those unfamiliar, [Claude Code](https://www.anthropic.com/claude-code) is Anthropic's AI-powered coding assistant that can read, write, and edit code across your entire codebase. Unlike traditional autocomplete tools, it can understand context across multiple files, execute commands, run tests, and even browse the web for documentation. Think of it as having an AI pair programmer that never gets tired and has read every Stack Overflow answer ever written.

The tool represents a new generation of AI assistants that go beyond simple code generation - they can understand your project structure, debug issues, refactor code, and even help with architecture decisions. It's part of a broader trend where AI tools are becoming increasingly capable of handling complex, multi-step programming tasks.

So, back to my friends:

My first friend - let's call him the "Null Stack Developer" - is one of those "vibe coders" who can seemingly make anything work with enough caffeine and sheer determination. He fired up Claude Code, asked it to build him a React dashboard with real-time data visualization, and within minutes was marveling at the generated components. "This is insane," he kept saying, watching perfectly structured TypeScript materialize on his screen. "It's like having a senior developer sitting next to me."

My second friend, a seasoned professional with battle scars from countless production fires, approached it with the healthy skepticism that comes from years of debugging other people's clever code. But even he admitted: "I'm not sure if we're quite there yet, but I suspect we're closing in on something resembling a game changer."

## The Craft Question

This brings me back to something I've been thinking about a lot lately: coding as craft. In my post about [embracing coding as craft and going back to the old gym](/posts/coding-as-craft-going-back-to-the-old-gym/), I talked about the value of fundamentals - of understanding your tools deeply, staying close to the metal, and building muscle memory through repetition. The question is: where do AI assistants fit into this hands-on approach?

Here's a concrete example from my own work: I recently built an Elm testimonials widget for this site. I could have asked Claude Code to generate the entire component, but instead I took a different approach. I used an AI agent to transform some messy DOM nodes into clean JSON data - perfect grunt work that saved me a few minutes of tedious copy-paste-format cycles. But then I opened Vim and wrote the actual Elm widget myself, line by line (learning all the while, and having fun).

The difference matters. By writing the widget manually, I stayed connected to the implementation details. I felt the friction of Elm's type system guiding me toward better design. I had to think through state management, event handling, and the component's lifecycle. I built understanding that I can carry forward to the next project.

The craft of software development isn't just about high-level architecture and design decisions. I'd argue it's also about staying connected to the implementation details, understanding how your abstractions work under the hood, and building intuition through hands-on experience. When you let AI handle too much of the actual coding, you risk losing that connection.

## The Helper, Not the Replacement

This is where AI tools find their sweet spot - but with important boundaries. They excel at the genuinely tedious work: transforming data formats, generating boilerplate, setting up project scaffolding. But there's a crucial distinction between tedious work and core implementation work.

The key insight from watching my two friends is this: the tool's value depends entirely on how you draw these boundaries. My vibe coder friend was impressed by the magic, but he wasn't building the muscle memory that comes from implementing core functionality himself. My experienced friend was more selective - using it as a very sophisticated autocomplete for the parts that don't teach you anything new, while staying hands-on for the parts that matter.

## Staying Head, Not Tail

The real danger isn't that AI will replace developers - it's that we'll become passive consumers of generated code without understanding what we're shipping. When you let the AI drive the thought process, you become the tail instead of the head.

But there's a subtler danger too: losing the connection between thinking and implementing. I've previously written about how physical practice builds intuition that pure theory can't. The same applies to coding. When you implement core functionality by hand, you discover edge cases, feel the natural boundaries of your abstractions, and build intuition about performance and maintainability.

There's an old saying at my (actual, not metaphorical) gym: "You don't stop lifting when you grow old, you grow old when you stop lifting." The same principle applies to learning new skills - including coding skills. You have to stay willing to feel awkward, to fall down, to build muscle memory one repetition at a time.

![A basic Ollie](/images/skateboard.jpg)
I btw also (true story!) started skateboarding this weekend. Because 36 is far too young to stop learning, and more to the point: not nearly old enough to grow addicted to AIs in _any_ way.

So I still write my Elm widgets in Vim rather than asking AI to generate them. I'm a craftsman, not an assembly line worker, and for that I'm infinitely grateful. The act of typing `case msg of` and thinking through each branch, of wrestling with the type checker, of refactoring when the design doesn't feel right - that's where learning happens. Just like learning to balance on a skateboard, you can't shortcut your way to intuition.

The craft isn't just in knowing what to build or how to structure it. It's also in staying connected to the implementation, maintaining the feedback loop between your high-level intentions and the low-level realities of making software work.

## The Verdict

So, game changer or just hype? I think it's both and neither.

It's not a game changer in the sense that it doesn't fundamentally alter what good software development looks like. We still need to understand our domain, design thoughtful APIs, write maintainable code, and ship reliable systems.

But it is a game changer in the sense that it can dramatically reduce the friction between having an idea and implementing it. It can make good developers more productive and help them focus on higher-value work.

Just look at [what it wrote](https://github.com/cekrem/cekrem.github.io/blob/master/CLAUDE.md) when I tried `/init` on this blog repo, it's actually impressively to the point! I suspect Claude will be helpful when I'm in dire need of a clean and good readme!

The hype part comes when people expect it to replace human judgment or when they use it as a crutch instead of a tool. Like any powerful tool, it amplifies your existing capabilities - both your strengths and your weaknesses.

My advice? Embrace these tools where it makes sense, but draw clear boundaries. Use them for data transformation, boilerplate generation, and tedious formatting tasks. But when it comes to core business logic, state management, or anything that teaches you something new about your domain - keep your hands on the keyboard at all times! And – this shouldn't need saying, but I think it does – don't, at any point, stop thinking!

The goal isn't to write less code - it's to write better software while staying connected to the craft. Let AI handle the grunt work so you can focus more time on the implementation details that actually matter. But never let it handle so much that you lose the feedback loop between thinking and building.

After all, the best software comes from developers who understand their tools deeply, not from those who've learned to prompt them cleverly.
