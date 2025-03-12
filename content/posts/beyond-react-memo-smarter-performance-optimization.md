---
title: "Beyond React.memo: Smarter Ways to Optimize Performance"
description: "Why composition patterns might be better than memoization for React performance"
tags:
  ["react", "performance", "architecture", "clean architecture", "typescript"]
date: 2025-03-11
---

## Introduction

When it comes to React performance optimization, `React.memo` is often the first tool developers reach for. It's the hammer we grab when we notice re-render issues, and suddenly everything looks like a nail. But what if I told you that in many cases, there are simpler, more elegant solutions that align better with React's compositional nature?

Today, I want to explore some fundamental concepts about how React renders components and share composition patterns that can dramatically improve performance without the complexity and gotchas of memoization.

For more on this topic, see Nadia Makarevich's excellent [Advanced React: Deep dives, investigations, performance patterns and techniques](https://amzn.to/41DkF1G).

## The Re-render Mystery

Let's start with a common scenario: You've added a simple feature to a React app - perhaps a modal dialog triggered by a button - and suddenly everything feels sluggish. The UI freezes momentarily when the dialog opens. What's happening?

```tsx
const App = () => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div className="layout">
      <Button onClick={() => setIsOpen(true)}>Open dialog</Button>

      {isOpen && <ModalDialog onClose={() => setIsOpen(false)} />}

      <VerySlowComponent />
      <BunchOfStuff />
      <OtherComplexComponents />
    </div>
  );
};
```

The problem is clear once you understand how React's rendering works: when `setIsOpen` is called, React re-renders the entire `App` component and everything inside it - including all those slow components that have nothing to do with our dialog.

## The Memoization Reflex

The typical response might be to reach for `React.memo`:

```tsx
const VerySlowComponent = React.memo(() => {
  // Complex rendering logic
});
```

While this works, it introduces complexity. You'll need to carefully manage dependencies, possibly add `useCallback` for event handlers, and deal with potential bugs when you forget to memoize something. It's a solution, but not always the most elegant one.

## Understanding React's Rendering Model

Before diving into better solutions, let's clarify some fundamental concepts:

1. **Components vs Elements**: A component is a function that returns React elements. An element is an object describing what should appear on screen.

2. **Re-renders**: When state changes, React calls your component function again and compares the returned elements to decide what DOM updates are needed.

3. **The Big Myth**: Many developers believe "components re-render when their props change." This isn't quite right. Components also re-render when their parent re-renders, regardless of whether their props changed - unless they're wrapped in `React.memo`.

## Moving State Down: The Composition Solution

Instead of memoizing everything, consider this elegant pattern:

```tsx
const ButtonWithModalDialog = () => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <>
      <Button onClick={() => setIsOpen(true)}>Open dialog</Button>

      {isOpen && <ModalDialog onClose={() => setIsOpen(false)} />}
    </>
  );
};

const App = () => {
  return (
    <div className="layout">
      <ButtonWithModalDialog />
      <VerySlowComponent />
      <BunchOfStuff />
      <OtherComplexComponents />
    </div>
  );
};
```

This simple refactoring isolates the state and its effects to a smaller component. When the dialog opens, only `ButtonWithModalDialog` re-renders - the slow components remain untouched. No memoization required!

This pattern aligns perfectly with the principles from Uncle Bob's "Clean Architecture" - specifically the Single Responsibility Principle. Each component now has a clearer, more focused responsibility.

## Children as Props: The Power of Composition

Let's look at another scenario: a scrollable container that needs to update its position based on scroll events without re-rendering its entire contents:

```tsx
// Problematic implementation
const ScrollableArea = () => {
  const [scrollPosition, setScrollPosition] = useState(0);

  const handleScroll = (e) => {
    setScrollPosition(e.target.scrollTop);
  };

  return (
    <div className="scrollable" onScroll={handleScroll}>
      <FloatingNavigation position={scrollPosition} />
      <VerySlowComponent />
      <MoreComplexContent />
    </div>
  );
};
```

Every scroll event would trigger re-renders of all the content. Instead of reaching for `React.memo`, we can use React's composition model:

```tsx
const ScrollableWithFloatingNav = ({ children }) => {
  const [scrollPosition, setScrollPosition] = useState(0);

  const handleScroll = (e) => {
    setScrollPosition(e.target.scrollTop);
  };

  return (
    <div className="scrollable" onScroll={handleScroll}>
      <FloatingNavigation position={scrollPosition} />
      {children}
    </div>
  );
};

const App = () => {
  return (
    <ScrollableWithFloatingNav>
      <VerySlowComponent />
      <MoreComplexContent />
    </ScrollableWithFloatingNav>
  );
};
```

The magic here is that `children` is just a regular prop - React doesn't give it special treatment during rendering. The syntactic sugar of nesting content between opening and closing tags (`<Component>Content</Component>`) is equivalent to passing it explicitly as `<Component children={Content} />`.

This works because React elements passed as props (including `children`) are created in the parent component and simply referenced in the child. When the child re-renders, it's using the same element references, so React knows it doesn't need to re-render them unless the references passed in (`children` or others) have changed.

## Why This Works: Elements, Reconciliation and Props

To understand why this pattern is so effective, we need to look at how React's reconciliation works:

1. When a component re-renders, React calls your component function and gets back a tree of elements.
2. React compares this new tree with the previous one using `Object.is()` comparison.
3. If an element reference is the same before and after, React can skip re-rendering that branch of the tree.

When we pass components as `children` or other props, those elements are created in the parent component's scope. The child component just receives references to these already-created elements. When the child re-renders, these references don't change, so React can skip re-rendering them.

## The Hidden Danger of Custom Hooks

While we're discussing performance, it's worth mentioning a common pitfall with custom hooks:

```tsx
// This can cause performance issues
const useModalDialog = () => {
  const [isOpen, setIsOpen] = useState(false);

  return {
    isOpen,
    open: () => setIsOpen(true),
    close: () => setIsOpen(false),
  };
};

const App = () => {
  const { isOpen, open, close } = useModalDialog();

  return (
    <div>
      <Button onClick={open}>Open</Button>
      {isOpen && <ModalDialog onClose={close} />}
      <VerySlowComponent />
    </div>
  );
};
```

This pattern looks clean, but it hides the fact that state changes in the hook will cause the entire `App` to re-render. Hooks don't magically isolate state effects - they just abstract them.

The solution? The same composition pattern we've been discussing:

```tsx
const ModalDialogController = () => {
  const { isOpen, open, close } = useModalDialog();

  return (
    <>
      <Button onClick={open}>Open</Button>
      {isOpen && <ModalDialog onClose={close} />}
    </>
  );
};

const App = () => {
  return (
    <div>
      <ModalDialogController />
      <VerySlowComponent />
    </div>
  );
};
```

## Key Takeaways

1. **Understand the render tree**: React re-renders flow downward from where state changes occur.

2. **Move state down**: Place state as close as possible to the components that actually need it.

3. **Use composition patterns**: Pass components as props or children to prevent unnecessary re-renders.

4. **Be careful with hooks**: They don't isolate re-renders; they just abstract state management.

5. **Consider memoization last**: Use `React.memo`, `useMemo`, and `useCallback` only after you've optimized your component structure.

These patterns align perfectly with React's compositional nature and the principles of Clean Architecture. They lead to components with clearer responsibilities, better separation of concerns, and naturally optimized performance.

## Conclusion

While `React.memo` and other memoization tools have their place, they should rarely be your first solution to performance problems. By understanding React's rendering model and embracing composition patterns, you can build applications that are both performant and maintainable.

The next time you encounter a performance issue in React, before reaching for memoization, ask yourself: "Can I restructure my components to isolate the effects of state changes?" The answer might lead you to a simpler, more elegant solution.

What performance optimization patterns have you found most effective in your React applications? I'd love to hear your experiences in the comments!
