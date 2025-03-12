+++
title = "Feedback.one: A Refreshing Take on User Feedback Built with Elm and Rust"
description = "Exploring a lightweight, elegant feedback widget that demonstrates the power of functional programming in production"
tags = ["elm", "rust", "web development", "tools", "functional programming"]
date = "2025-03-15"
draft = false
+++

I recently added a new feedback widget to this site – [feedback.one](https://feedback.one/) – and I'm impressed enough with it that I thought it deserved its own post. Beyond being a useful tool, it's also an excellent example of how functional programming languages like Elm can shine in production environments.

## What is feedback.one?

At its core, feedback.one is a simple but powerful tool that adds a non-intrusive feedback button to your website. With one line of code, you get:

- A customizable feedback widget that doesn't interfere with your site's design
- Unlimited feedback submissions (yes, actually unlimited, not "unlimited until you hit our secret cap")
- No impact on your site's performance
- A clean dashboard to manage and respond to feedback

What makes it particularly interesting to me is the tech stack: it's built with Elm and Rust – two languages that prioritize correctness, performance, and maintainability.

## Why the Tech Stack Matters

When choosing tools for your project, the underlying technology might seem irrelevant – after all, users care about features and experience, not implementation details. But the tech stack often reveals the values and priorities of the creators.

### Elm: Correctness by Design

Elm is a functional language that compiles to JavaScript and is specifically designed for building reliable web applications. If you've read [my previous post on Elm](/posts/why-i-hope-i-get-to-write-a-lot-of-elm-code-in-2025/), you know I'm a fan of its approach to frontend development.

The fact that feedback.one uses Elm suggests a few things:

1. **Reliability is a priority** – Elm's compiler is famous for catching errors at compile time that would be runtime errors in JavaScript
2. **Long-term maintenance matters** – Elm code tends to be more maintainable as projects grow
3. **The team values functional programming principles** – Immutability, pure functions, and strong typing

### Rust: Performance and Safety

On the backend, feedback.one uses Rust – a systems programming language focused on safety, speed, and concurrency. Rust's memory safety guarantees without garbage collection make it ideal for performance-critical applications.

Using Rust indicates:

1. **Performance is taken seriously** – Rust is consistently among the fastest languages available
2. **Security is a core concern** – Rust's ownership model prevents entire classes of bugs
3. **The team is willing to invest in the right tools** – Rust has a steeper learning curve than many alternatives

## The User Experience

What I appreciate most about feedback.one is how it balances simplicity with effectiveness. The integration process couldn't be simpler:

```html
<script
  async
  defer
  src="https://feedback.one/widget.js"
  data-project="your-project-id"
></script>
```

That's it. One line of code and you're done.

The widget itself is equally thoughtful – it sits unobtrusively in the corner of your site until needed, then expands into a clean, focused interface when clicked. No popups, no interruptions to the user experience, just a helpful tool available when wanted.

## The Business Model: Refreshingly Honest

In an era of "free tiers" that are really just limited trials, feedback.one's approach is refreshing. Their basic service is genuinely free, with no artificial limits on submissions or users.

Their stated plan is to monetize through advanced features later while keeping the core functionality free. This aligns with the values suggested by their tech choices – building something sustainable and valuable rather than optimizing for short-term gains.

## Why I Added It to My Site

I've always believed that direct feedback from readers is invaluable, but I've been hesitant to add complex widgets that might slow down the site or compromise privacy. Feedback.one struck the right balance for me:

1. **Lightweight** – No performance impact
2. **Non-intrusive** – Doesn't interfere with the reading experience
3. **Privacy-focused** – No tracking or analytics beyond what's needed for the feedback itself
4. **Simple to implement** – I spent more time writing this blog post than implementing the widget

And while it's mostly designed as a means to give feedback for systems more complicated than my blog (:D), I thought it interesting (and simple) enough to give it a go.

## The Bigger Picture: Functional Programming in Production

Beyond its practical utility, feedback.one serves as a case study for functional programming in production. It demonstrates that languages like Elm and Rust aren't just academic curiosities – they can power real-world tools that are simple, reliable, and performant.

This matters because we often see a disconnect between programming paradigms that are theoretically "better" and what actually gets used in production. Tools like feedback.one help bridge that gap, showing that the benefits of functional programming can translate directly to better products.

## Try It Out

If you're reading this post and have thoughts to share, you can use the feedback button on the right side of the page. It's a small example of the tool in action, and I'd love to hear what you think – about this post, about feedback.one, or about the site in general.

And if you're building your own site or application, consider giving feedback.one a try. It's a simple tool that does one thing well, built with technologies that prioritize correctness and maintainability – values that align well with creating quality software.

## Resources

- [Feedback.one](https://feedback.one/) – The official site
- [Elm](https://elm-lang.org/) – The functional language for reliable webapps
- [Rust](https://www.rust-lang.org/) – A language empowering everyone to build reliable and efficient software
- [Elm Land](https://elm.land/) – The framework used by feedback.one for their Elm implementation
