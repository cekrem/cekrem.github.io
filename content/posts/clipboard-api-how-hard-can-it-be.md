+++
title = "The Clipboard API: How Did We Get Here?"
description = "Or: why there are 1000+ npm packages for copying text to clipboard"
tags = ["javascript", "web-apis", "complexity", "npm"]
date = "2025-11-07"
draft = false
+++

I'm writing [a book about Elm for React developers](https://leanpub.com/elm-for-react-devs/). In the JavaScript interop chapter, I needed a simple example of calling a browser API from Elm through a port. Something straightforward, universally useful, not too trivial.

"Perfect," I thought. "Let's copy text to the clipboard."

## The Search

Out of curiosity, I checked npm for clipboard packages:

![Over 1000 packages for clipboard operations](/images/clipboard_npm.png)

**Over one thousand packages.** For copying text to the clipboard.

Let that sink in for a moment.

## The "Simple" Solution

The modern approach looks like this:

```javascript
navigator.clipboard
  .writeText(text)
  .then(() => console.log("Copied!"))
  .catch((err) => console.error("Failed:", err));
```

Clean, simple, promise-based. What could go wrong?

## Everything That Can Go Wrong

### 1. Browser Support

`navigator.clipboard` requires a secure context (HTTPS or localhost). Running on plain HTTP? No clipboard for you.

### 2. Permissions

On some browsers, you need explicit user permission. On others, it only works during a user gesture. On yet others, it silently fails if the tab isn't focused.

### 3. Safari

Safari (of course) has its own special requirements. Sometimes `navigator.clipboard` exists but doesn't work. Sometimes it works but throws errors. Sometimes it works perfectly. Nobody knows why.

### 4. The Old Way Still Works Better

So everyone falls back to the pre-async solution:

```javascript
function copyToClipboard(text) {
  const textarea = document.createElement("textarea");
  textarea.value = text;
  textarea.style.position = "fixed";
  textarea.style.opacity = "0";
  document.body.appendChild(textarea);
  textarea.select();

  try {
    document.execCommand("copy");
    return true;
  } catch (err) {
    return false;
  } finally {
    document.body.removeChild(textarea);
  }
}
```

Create an invisible textarea, append it to the DOM, select its contents, execute an officially deprecated command, clean up. This works more reliably than the "modern" API.

### 5. Mobile Is Its Own Adventure

iOS Safari requires the textarea to be in the viewport. Android has its own quirks. Mobile Chrome sometimes works, sometimes doesn't. Better test on actual devices.

## Why 1000+ Packages?

Each package is someone's attempt to handle all these edge cases:

- `clipboard-polyfill` - Polyfills the modern API
- `copy-to-clipboard` - Uses the old approach
- `clipboard-copy` - Tries modern first, falls back
- `clipboard.js` - Event-based approach
- `react-copy-to-clipboard` - React wrapper
- `vue-clipboard2` - Vue wrapper
- And 994+ more variations...

Each maintainer discovered that "just copy text to clipboard" isn't simple. Each built their own solution. Each accumulated GitHub stars from grateful developers who thought they were the only ones struggling with this.

## The Real Problem

This isn't about the clipboard API specifically. It's about the web platform's accumulation of complexity:

1. New APIs get added to fix old problems
2. Old APIs can't be removed (breaking the web is forbidden)
3. Browser implementations diverge in subtle ways
4. Developers need solutions that work **now**, across all browsers
5. So we create abstraction layers
6. Which create their own complexity
7. Which create new problems
8. Which require new APIs...

## What I Did

For my book example, I linked to a working implementation in the example repo and moved on. Because sometimes the right answer is "this is complicated, here's something that works, let's focus on what we're actually trying to teach."

Which, ironically, is also why Elm keeps JavaScript at arm's length with ports. The browser is infrastructure—useful but inherently unreliable. Better to keep those sharp edges contained.

## The Takeaway

Next time you see 1000 npm packages for something that "should be simple," remember: it probably was simple, once. Then browsers happened. Then reality happened. Then we got 1000 slightly different solutions to the same accidental complexity.

Welcome to web development in 2025, where copying text to the clipboard remains an unsolved problem.

---

_P.S. - If you're interested in that Elm book I mentioned, it's called "An Elm Primer for React Developers" and you can read more [here](/posts/elm-book-announcement/). Early access available [here](https://leanpub.com/elm-for-react-devs/c/blog-october)!_
