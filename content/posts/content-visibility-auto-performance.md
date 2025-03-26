---
title: "Introducing `content-visibility: auto` - A Hidden Performance Gem"
description: "How to dramatically improve rendering performance of large lists and complex DOMs with a single CSS property"
tags: ["performance", "css", "web"]
date: 2025-03-26
---

## Introduction

When dealing with large lists or complex DOM structures, performance optimization often feels like a complex puzzle. But sometimes, the simplest solutions are the most effective. Enter `content-visibility: auto` - a CSS property that can dramatically improve rendering performance with minimal effort.

## The Magic of content-visibility: auto

`content-visibility: auto` tells the browser to skip rendering elements that are not currently visible in the viewport. It's like having a virtual scroll implementation, but without the complexity of managing scroll positions or item heights manually.

Here's a simple example:

```css
.long-list-item {
  content-visibility: auto;
  contain-intrinsic-size: auto; /* Let the browser figure out the size; measured size is then stored even when element is not rendered  */
  /* Or specify a size: contain-intrinsic-size: 0 50px; */
}
```

The `contain-intrinsic-size` property is crucial here - it tells the browser how much space to reserve for each item while it's not being rendered. You can either let the browser figure out the size automatically with `auto`, or specify an explicit size (like `0 50px` for a 50px height). This prevents layout shifts when items come into view.

## Browser Support and Caveats

The property is well-supported in modern browsers, but there's one important caveat: Safari's native search functionality (Cmd+F) won't always find text in elements that are currently hidden by `content-visibility: auto`. This is because Safari doesn't scan the DOM for hidden content, at least not consistently (as of 18.3.1).

If search functionality is crucial for your use case, you might want to:

1. Disable `content-visibility: auto` for searchable content
2. Implement a custom search solution
3. Use a different optimization strategy
4. (Turn off this optimization for Safari, or if you're feeling fancy: turn off for Safari once search has been triggered)

## A Live Example

Below is an interactive example showing the performance difference. Try scrolling through the list with and without `content-visibility: auto`

<iframe height="300" style="width: 100%;" scrolling="no" title="content-visibility" src="https://codepen.io/cekrem/embed/preview/MYWBzOZ?default-tab=result" frameborder="no" loading="lazy" allowtransparency="true" allowfullscreen="true">
  See the Pen <a href="https://codepen.io/cekrem/pen/MYWBzOZ">
  content-visibility</a> by Christian Ekrem (<a href="https://codepen.io/cekrem">@cekrem</a>)
  on <a href="https://codepen.io">CodePen</a>.
</iframe>

## When to Use It

This optimization is particularly effective for:

- Long lists of items (like product catalogs)
- Complex dashboards with many components
- Infinite scroll implementations
- Tables with many rows

## Conclusion

`content-visibility: auto` is a powerful yet simple optimization that can significantly improve rendering performance of complex UIs. While it's not a silver bullet (especially considering the Safari search limitation), it's a valuable tool in your performance optimization toolkit.

Remember to always measure performance before and after implementing this optimization, as its effectiveness can vary depending on your specific use case and content structure.
