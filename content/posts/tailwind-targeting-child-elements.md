+++
title = "Tailwind CSS: Targeting Child Elements (when you have to)"
description = "Understanding arbitrary variants and how Tailwind lets you style nested elements without leaving your utility classes"
tags = ["tailwind", "css", "web"]
date = "2025-12-11"
draft = false
+++

The whole point of Tailwind is applying utility classes directly to elements. Styling generic elements like `p` or `div` with descendant selectors goes against the grain—it's the kind of thing Tailwind was designed to replace.

But sometimes you don't have a choice. Maybe it's content from a CMS, a third-party component, or dynamically generated HTML. You need to style elements you don't control. In vanilla CSS, you'd write a selector like `.third-party-stuff > p` and move on. But what about Tailwind?

## The Problem

Let's say you have a container with some paragraphs:

```html
<div class="content">
  <p>First paragraph</p>
  <p>Second paragraph</p>
</div>
```

You want all paragraphs inside `.content` to have specific styling. The traditional approach? Write custom CSS:

```css
.content > p {
  color: blue;
  margin-bottom: 1rem;
}
```

But that defeats the purpose of utility-first CSS. You're back to maintaining a separate stylesheet, naming things, and context-switching. Not the end of the world, but not let's see if if there's another way!

## Arbitrary Variants to the Rescue

Tailwind's arbitrary variants let you write any CSS selector directly in your class names using square bracket notation:

```html
<div class="[&>p]:text-blue-500 [&>p]:mb-4">
  <p>First paragraph</p>
  <p>Second paragraph</p>
</div>
```

That `[&>p]` syntax might look strange at first, but it's straightforward once you understand what's happening.

## Breaking Down the Syntax

The magic is in understanding what `&` means. In Tailwind's arbitrary variants, `&` represents the current element—the one your class is applied to. It works exactly like `&` in Sass/SCSS or CSS nesting.

So when you write:

```html
<div class="[&>p]:text-blue-500"></div>
```

Tailwind generates CSS that looks like this:

```css
.\[\&\>p\]\:text-blue-500 > p {
  --tw-text-opacity: 1;
  color: rgb(59 130 246 / var(--tw-text-opacity));
}
```

The class name gets escaped (those backslashes), but the important part is `> p`. The `&` gets replaced with the generated class selector, and then your selector (`>p`) is appended. The result: any direct child `<p>` of an element with this class gets the styling.

## Common Patterns

Here are some useful child-targeting patterns:

### Direct Children

```html
<!-- All direct paragraph children -->
<div class="[&>p]:text-gray-600">...</div>

<!-- All direct divs -->
<div class="[&>div]:border [&>div]:p-4">...</div>

<!-- First direct child only -->
<div class="[&>*:first-child]:mt-0">...</div>
```

### All Descendants

```html
<!-- All paragraphs anywhere inside -->
<div class="[&_p]:text-gray-600">...</div>

<!-- All links anywhere inside -->
<div class="[&_a]:text-blue-500 [&_a]:underline">...</div>
```

Note the difference: `>` targets direct children only, while a space (represented as `_` in Tailwind) targets all descendants.

### Specific Elements

```html
<!-- Style the second child -->
<ul class="[&>li:nth-child(2)]:font-bold">
  ...
</ul>

<!-- Hover state on child elements -->
<div class="[&>button:hover]:bg-blue-600">...</div>

<!-- Disabled inputs anywhere inside -->
<form class="[&_input:disabled]:bg-gray-100">...</form>
```

## When To Use This

This approach shines when you're dealing with:

- **CMS content**: You're styling HTML you don't control
- **Third-party components**: The component doesn't expose enough styling props
- **Prose content**: Markdown-rendered content that needs consistent styling
- **Dynamic content**: Content generated at runtime

For content you do control, just apply classes directly to the elements. That's still the Tailwind way.

## A Practical Example: CMS Content

Here's the scenario that prompted this post: we display articles from a headless CMS (well, not _quite_, but for the sake of keeping things simple, let's leave it at at that). The content arrives as pre-rendered HTML that we wrap in our own container. We don't control the inner markup—it might contain divs, paragraphs, links, whatever the CMS produces.

(Note: what we _also_ do before thinking of styling is sanitize the content! But that's out of scope for this post.)

The solution is a simple wrapper that applies styles to its children:

```elm
viewArticleContent : List (Html msg) -> Html msg
viewArticleContent someThirdPartyContentWeDontControl =
    Html.article
        [ Attr.class "p-4"
        , Attr.class "[&_div]:max-w-prose"
        , Attr.class "[&_a]:text-blue-600 [&_a]:font-bold [&_a:hover]:underline"
        ]
        someThirdPartyContentWeDontControl
```

Or the equivalent in React:

```jsx
const ArticleContent = ({ children }) => (
  <article
    className="
    p-4
    [&_div]:max-w-[65ch]
    [&_a]:text-blue-600 [&_a]:font-bold [&_a:hover]:underline
  "
  >
    {children}
  </article>
);
```

All the styling lives in the wrapper component, applied to whatever HTML gets rendered inside. No separate stylesheet, no CSS modules, no fighting with specificity. When the design changes, we update the classes in one place.

(Tailwind also has a `@tailwindcss/typography` plugin with a `prose` class that handles rich text styling, and if you're lucky that's enough in and by itself—but sometimes you need finer control, or you're matching an existing design system.)

## The Takeaway

Arbitrary variants with `[&...]` syntax let you write virtually any CSS selector within Tailwind's utility-class paradigm. The `&` represents the element your class is on, and everything after it is standard CSS selector syntax (with `_` for spaces).

It's not always the prettiest solution, but it keeps your styling colocated with your markup—which is the whole point of utility-first CSS.
