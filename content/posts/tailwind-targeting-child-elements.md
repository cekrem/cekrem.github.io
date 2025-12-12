+++
title = "Tailwind CSS: Targeting Child Elements (when you have to)"
description = "Understanding arbitrary variants and how Tailwind lets you style nested elements without leaving your utility classes"
tags = ["tailwind", "css", "web"]
date = "2025-12-11"
draft = false
+++

The whole point of Tailwind is applying utility classes directly to elements. Styling generic elements like `p` or `div` with descendant selectors goes against the grain—it's the kind of thing Tailwind was designed to replace.

But sometimes you don't have a choice. Maybe it's content from a CMS, a third-party component, or dynamically generated HTML. You need to style elements you don't control.

**Let's be clear upfront:** adding a small piece of vanilla CSS to handle this is often the simplest and most sensible solution. A dedicated stylesheet for CMS content is a perfectly valid approach. But if you're committed to staying within Tailwind's utility-class paradigm—or just curious about what's possible—this post shows how you _can_ target child elements using arbitrary variants.

## The Problem

Let's say you have a container with embedded HTML you don't control:

```html
<div class="cms-content">
  <p>Some text with a <a href="#">link</a> in it.</p>
  <ul>
    <li>List item one</li>
    <li>List item two</li>
  </ul>
</div>
```

You want all links inside to have specific styling—underlines on hover, a distinct color that differs from the inherited text color, maybe a font weight. The traditional approach? Write custom CSS:

```css
.cms-content a {
  font-weight: 600;
  text-decoration: none;
}
.cms-content a:hover {
  text-decoration: underline;
}
.cms-content li {
  list-style-type: disc;
  margin-left: 1.5rem;
}
```

That's a perfectly valid approach—and often the right one! A small stylesheet for CMS content is simple and maintainable. But let's see what Tailwind offers if you want to keep everything in utility classes.

## Arbitrary Variants: The Tailwind Way

Tailwind's arbitrary variants let you write any CSS selector directly in your class names using square bracket notation:

```html
<div
  class="[&_a]:font-semibold [&_a]:no-underline [&_a:hover]:underline [&_li]:list-disc [&_li]:ml-6"
>
  <p>Some text with a <a href="#">link</a> in it.</p>
  <ul>
    <li>List item one</li>
    <li>List item two</li>
  </ul>
</div>
```

That `[&_a]` syntax might look strange at first, but it's straightforward once you understand what's happening.

## Breaking Down the Syntax

The magic is in understanding what `&` means. In Tailwind's arbitrary variants, `&` represents the current element—the one your class is applied to. It works exactly like `&` in Sass/SCSS or CSS nesting.

So when you write:

```html
<div class="[&_a]:font-semibold"></div>
```

Tailwind generates CSS that looks like this:

```css
.\[\&_a\]\:font-semibold a {
  font-weight: 600;
}
```

The class name gets escaped (them backslashes...), but the important part is the `a` descendant selector. The `&` gets replaced with the generated class selector, and then your selector (`a`) is appended. The result: any `<a>` element anywhere inside an element with this class gets the styling.

## Common Patterns

Here are some useful child-targeting patterns:

### Direct Children

```html
<!-- All direct divs get borders and padding -->
<div class="[&>div]:border [&>div]:p-4">...</div>

<!-- First direct child removes top margin -->
<div class="[&>*:first-child]:mt-0">...</div>

<!-- Last child removes bottom border -->
<div class="[&>*:last-child]:border-b-0">...</div>
```

### All Descendants

```html
<!-- All links get hover underlines -->
<div class="[&_a]:no-underline [&_a:hover]:underline">...</div>

<!-- All list items get disc markers -->
<div class="[&_li]:list-disc [&_li]:ml-6">...</div>

<!-- All images get rounded corners -->
<div class="[&_img]:rounded-lg">...</div>
```

Note the difference: `>` targets direct children only, while a space (represented as `_` in Tailwind) targets all descendants.

### Pseudo-states on Children

```html
<!-- Hover state on child elements -->
<div class="[&>button:hover]:bg-blue-600">...</div>

<!-- Disabled inputs get muted background -->
<form
  class="[&_input:disabled]:bg-gray-100 [&_input:disabled]:cursor-not-allowed"
>
  ...
</form>

<!-- Focus styles for nested inputs -->
<div class="[&_input:focus]:ring-2 [&_input:focus]:ring-blue-500">...</div>
```

## When This Makes Sense

To be honest, a vanilla CSS stylesheet is often the better choice for styling embedded content. It's simpler, more readable, and easier to maintain. But this arbitrary variant approach might make sense when:

- **You're already all-in on Tailwind** and want to avoid context-switching to CSS
- **You need just one or two rules** and a whole stylesheet feels like overkill
- **Your build pipeline makes adding CSS awkward** (though this is a smell worth addressing)
- **You want the styling colocated** with the component that renders the content

For content you _do_ control, just apply classes directly to the elements. That's still the Tailwind way—and frankly, it's simpler than any of this.

## A Practical Example: CMS Content

Here's the scenario that prompted this post: we display articles from a headless CMS at my client's. The content arrives as pre-rendered HTML that we wrap in our own container. We don't control the inner markup—it might contain paragraphs, links, lists, images, whatever the CMS produces. The structure, elements used (and lack of ability to add classes where we want) adds some interesting constraints.

(Note: always sanitize embedded content! But that's out of scope for this post.)

### The Vanilla CSS Approach (Often Best)

For anything beyond a few simple rules, a dedicated stylesheet is usually cleaner:

```css
.cms-content a {
  font-weight: 600;
}
.cms-content a:hover {
  text-decoration: underline;
}
.cms-content img {
  border-radius: 0.5rem;
  max-width: 100%;
}
.cms-content li {
  list-style-type: disc;
  margin-left: 1.5rem;
}
```

This is readable, maintainable, and doesn't require learning special syntax. For many projects, this is the right answer.

### The Tailwind Approach

But if you're committed to keeping styles in your component, here's how it looks (in Elm, as usual):

```elm
viewArticleContent : List (Html msg) -> Html msg
viewArticleContent content =
    Html.article
        [ Attr.class "p-4"
        , Attr.class "[&_a]:font-semibold [&_a:hover]:underline"
        , Attr.class "[&_img]:rounded-lg [&_img]:max-w-full"
        , Attr.class "[&_li]:list-disc [&_li]:ml-6"
        ]
        content
```

Or in React:

```jsx
const ArticleContent = ({ children }) => (
  <article
    className="
      p-4
      [&_a]:font-semibold [&_a:hover]:underline
      [&_img]:rounded-lg [&_img]:max-w-full
      [&_li]:list-disc [&_li]:ml-6
    "
  >
    {children}
  </article>
);
```

All the styling lives in the wrapper component. When the design changes, you update the classes in one place.

(Tailwind also has a `@tailwindcss/typography` plugin with a `prose` class that handles rich text styling, and if you're lucky that's enough in and by itself—but sometimes you need finer control, or you're matching an existing design system.)

## The Takeaway

Arbitrary variants with `[&...]` syntax let you write virtually any CSS selector within Tailwind's utility-class paradigm. The `&` represents the element your class is on, and everything after it is standard CSS selector syntax (with `_` for spaces).

Is this the best approach? Probably not! A small vanilla CSS stylesheet for embedded content is often simpler, more readable, and easier for your team to maintain. Tailwind and traditional CSS can coexist just fine.

But if you want to (or have to) stay within Tailwind's utility-class model—or you're curious about what's possible—now you know how.
