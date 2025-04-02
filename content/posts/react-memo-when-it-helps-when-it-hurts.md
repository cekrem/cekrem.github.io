---
title: "React.memo Demystified: When It Helps and When It Hurts"
description: "A deep dive into React's memoization tools and the hidden pitfalls that make them harder to use than you think"
tags:
  ["react", "performance", "architecture", "clean architecture", "typescript"]
date: 2025-04-02
---

## The Promise of Memoization

When React applications start to slow down, `React.memo`, `useMemo`, and `useCallback` are often the first tools developers reach for. After all, preventing unnecessary re-renders seems like a straightforward path to better performance. But in the React ecosystem, memoization is far more complex than it first appears.

In this post, we'll look at how these tools actually work under the hood, the subtle ways they can fail, and when they're truly beneficial versus when they're just adding unnecessary complexity.

If you haven't already, be sure to check out [my previous posts about optimization _without_ using memoization](/posts/beyond-react-memo-smarter-performance-optimization/).

## Understanding the Problem: JavaScript Reference Comparisons

At its core, the need for memoization in React stems from how JavaScript compares objects, arrays, and functions. While primitive values (strings, numbers, booleans) are compared by their actual value, objects are compared by reference:

```tsx
// Primitives compare by value
const a = 1;
const b = 1;
a === b; // true

// Objects compare by reference
const objA = { id: 1 };
const objB = { id: 1 };
objA === objB; // false, different references

// To make comparison true, they need to reference the same object
const objC = objA;
objA === objC; // true
```

This becomes a problem in React because:

1. Components re-render when their state changes or when their parent component re-renders
2. When a component re-renders, all its local variables (including objects and functions) are recreated _with new references_
3. If these new references are passed as props or used in hook dependencies, they'll trigger unnecessary re-renders or effect executions

## useMemo and useCallback Under the Hood

To solve this problem, React provides memoization hooks that preserve references between renders. But how do they actually work?

Both `useMemo` and `useCallback` primarily exist to help maintain stable references across re-renders. They cache a value and only recalculate it when specified dependencies change.

Here's what they do behind the scenes:

```tsx
// Conceptual implementation of useCallback
let cachedCallback;
const useCallback = (callback, dependencies) => {
  if (dependenciesHaventChanged(dependencies)) {
    return cachedCallback;
  }
  cachedCallback = callback;
  return callback;
};

// Conceptual implementation of useMemo
let cachedResult;
const useMemo = (factory, dependencies) => {
  if (dependenciesHaventChanged(dependencies)) {
    return cachedResult;
  }
  cachedResult = factory();
  return cachedResult;
};
```

The main difference: `useCallback` caches the function itself, while `useMemo` caches the return value of the function it receives.

## The Most Common Misconception: Memoizing Props

One of the most widespread misconceptions is that memoizing props with `useCallback` or `useMemo` prevents child components from re-rendering:

```tsx
const Component = () => {
  // People think this prevents re-renders in child components
  const onClick = useCallback(() => {
    console.log("clicked");
  }, []);

  return <button onClick={onClick}>Click me</button>;
};
```

This is simply not true. If a parent component re-renders, all of its children will re-render by default, regardless of whether their props changed or not. Memoizing props only helps in two specific scenarios:

1. When the prop is used as a dependency in a hook in the child component
2. When the child component is wrapped in `React.memo`

## What React.memo Actually Does

`React.memo` is a higher-order component that memoizes the result of a component render. It performs a shallow comparison of props to determine if a re-render is necessary:

```tsx
const ChildComponent = ({ data, onClick }) => {
  // Component implementation
};

const MemoizedChild = React.memo(ChildComponent);

const ParentComponent = () => {
  // Without memoization, these get new references on every render
  const data = { value: 42 };
  const onClick = () => console.log("clicked");

  // MemoizedChild will re-render on every ParentComponent render
  // despite React.memo, because props keep changing
  return <MemoizedChild data={data} onClick={onClick} />;
};
```

In this example, `React.memo` doesn't prevent re-renders because the props keep changing references. This is where `useMemo` and `useCallback` become useful:

```tsx
const ParentComponent = () => {
  // Stable references across renders
  const data = useMemo(() => ({ value: 42 }), []);
  const onClick = useCallback(() => console.log("clicked"), []);

  // Now MemoizedChild will only re-render when its props actually change
  return <MemoizedChild data={data} onClick={onClick} />;
};
```

## The Hidden Pitfalls of React.memo

Using `React.memo` effectively is surprisingly difficult. Let's explore some common pitfalls that can silently break your memoization:

### 1. The Props Spreading Problem

```tsx
const Child = React.memo(({ data }) => {
  // Component implementation
});

// This breaks memoization because props might change
const Parent = (props) => {
  return <Child {...props} />;
};
```

When you spread props like this, you have no control over whether the properties that `Child` receives maintain stable references. Someone using your `Parent` component could unwittingly break the memoization.

### 2. The Children Prop Problem

Perhaps the most surprising pitfall is that JSX children are just another prop, and they need to be memoized too:

```tsx
const MemoComponent = React.memo(({ children }) => {
  // Implementation
});

const Parent = () => {
  // This breaks memoization! Children is recreated each render
  return (
    <MemoComponent>
      <div>Some content</div>
    </MemoComponent>
  );
};
```

To fix this, you need to memoize the children:

```tsx
const Parent = () => {
  const content = useMemo(() => <div>Some content</div>, []);

  return <MemoComponent>{content}</MemoComponent>;
};
```

### 3. The Nested Memo Component Problem

```tsx
const InnerChild = React.memo(() => <div>Inner</div>);
const OuterChild = React.memo(({ children }) => <div>{children}</div>);

const Parent = () => {
  // Memoization of OuterChild is broken!
  return (
    <OuterChild>
      <InnerChild />
    </OuterChild>
  );
};
```

Even though both components are memoized, `OuterChild` will still re-render because the `InnerChild` JSX element creates a new object reference on each render. The solution? Memoize the child element:

```tsx
const Parent = () => {
  const innerChild = useMemo(() => <InnerChild />, []);

  return <OuterChild>{innerChild}</OuterChild>;
};
```

## When Should You Actually Use Memoization?

Given all these complexities, when should you actually use React's memoization tools?

### Use React.memo when:

1. You have a pure functional component that renders the same result given the same props
2. It renders often with the same props
3. It's computationally expensive to render
4. You've verified through profiling that it's a performance bottleneck

### Use useMemo when:

1. You have an expensive calculation that doesn't need to be recalculated on every render
2. You need to maintain a stable reference to an object or array that's passed to a memoized component
3. You've measured and confirmed the calculation is actually expensive

### Use useCallback when:

1. You're passing callbacks to optimized child components that rely on reference equality
2. The callback is a dependency in a useEffect hook
3. You need to maintain a stable function reference for event handlers in memoized components

## The Composition Alternative

Before reaching for memoization, consider if your component structure could be improved through composition. Component composition often addresses performance issues more elegantly than memoization.

For example, instead of memoizing an expensive component:

```tsx
const ParentWithState = () => {
  const [count, setCount] = useState(0);

  return (
    <div>
      <button onClick={() => setCount(count + 1)}>Increment</button>
      <ExpensiveComponent /> {/* Re-renders on every count change */}
    </div>
  );
};
```

Move the state to a more specific container:

```tsx
const CounterButton = () => {
  const [count, setCount] = useState(0);

  return <button onClick={() => setCount(count + 1)}>Count: {count}</button>;
};

const Parent = () => {
  return (
    <div>
      <CounterButton />
      <ExpensiveComponent /> {/* No longer re-renders when count changes */}
    </div>
  );
};
```

## Conclusion

Memoization in React is a powerful optimization technique, but it's also fraught with subtleties that can trip up even experienced developers. Before liberally applying `React.memo`, `useMemo`, and `useCallback` throughout your codebase:

1. **Profile first**: Use React DevTools Profiler to identify actual performance bottlenecks
2. **Consider composition**: Restructuring components can eliminate the need for memoization
3. **Mind the pitfalls**: Be aware of the many ways memoization can silently break
4. **Measure again**: Verify that your optimizations actually improve performance

When used judiciously and correctly, memoization can significantly improve React application performance. But when applied without care, it can increase complexity with little benefit or even negative performance impact.

Remember that premature optimization is the root of much evil in software development. Start with clean component composition following functional programming principles, measure performance, and only then reach for memoization when you have concrete evidence it's needed.

What are your experiences with React's memoization tools? Have you found other patterns that help avoid unnecessary re-renders? I'd love to hear about it (use the feedback widget on the right).
