---
title: "React Reconciliation: The Hidden Engine Behind Your Components"
description: "A deep dive into how React's reconciliation algorithm works and why it matters for performance"
tags:
  ["react", "performance", "architecture", "clean architecture", "typescript"]
date: 2025-04-08
---

##### Disclaimer: I've been made aware of some issues with some of the code examples in this article. First of all, sorry about any confusion as a result! I'll re-test them all manually and figure out where I went wrong in my simplification of these concepts first thing after my Easter holiday. I still think the text holds true and the general principles explained are sound. Thanks for your patience, and again, sorry

## The Reconciliation Engine

In my previous articles ([1](//posts/beyond-react-memo-smarter-performance-optimization/), [2](/posts/react-memo-when-it-helps-when-it-hurts/)), I explored how `React.memo` works and smarter ways to optimize performance through composition. But to truly master React performance, we need to understand the engine that powers it all: React's reconciliation algorithm.

Reconciliation is the process by which React updates the DOM to match your component tree. It's what makes React's declarative programming model possible - you describe what you want, and React figures out how to make it happen efficiently.

## Component Identity and State Persistence

Before diving into the technical details, let's explore a surprising behavior that reveals how React thinks about component identity.

Consider this simple text input toggle example:

```tsx
const UserInfoForm = () => {
  const [isEditing, setIsEditing] = useState(false);

  return (
    <div className="form-container">
      <button onClick={() => setIsEditing(!isEditing)}>
        {isEditing ? "Cancel" : "Edit"}
      </button>

      {isEditing ? (
        <input
          type="text"
          placeholder="Enter your name"
          className="edit-input"
        />
      ) : (
        <input
          type="text"
          placeholder="Enter your name"
          disabled
          className="view-input"
        />
      )}
    </div>
  );
};
```

The interesting behavior occurs when you interact with this form. If you type something into the input field while editing and then click the "Cancel" button, your text remains when you click "Edit" again! This happens even though the two `input` elements have different props (one is disabled with a different class).

React preserves the DOM element and its state because both elements are of the same type (`input`) at the same position in the element tree. React simply updates the props of the existing element rather than recreating it.

But if we changed our implementation to:

```tsx
{
  isEditing ? (
    <input type="text" placeholder="Enter your name" className="edit-input" />
  ) : (
    <div className="view-only-display">Name will appear here</div>
  );
}
```

Then toggling the edit mode would result in completely different elements being mounted and unmounted, with any user input being lost.

This behavior highlights a fundamental aspect of React's reconciliation: **element type is the primary factor in determining identity**. Understanding this concept is key to mastering React performance.

## Element Trees, Not Virtual DOM

You've probably heard that React uses a "Virtual DOM" to optimize updates. While this is a useful mental model, it's more accurate to think of React's internal representation as an element tree - a lightweight description of what should be on screen.

When you write JSX like this:

```tsx
const Component = () => {
  return (
    <div>
      <h1>Hello</h1>
      <p>World</p>
    </div>
  );
};
```

React transforms it into a tree of plain JavaScript objects:

```tsx
{
  type: 'div',
  props: {
    children: [
      {
        type: 'h1',
        props: {
          children: 'Hello'
        }
      },
      {
        type: 'p',
        props: {
          children: 'World'
        }
      }
    ]
  }
}
```

For DOM elements like `div` or `input`, the "type" is a string. For custom React components, the "type" is the actual function reference:

```tsx
{
  type: Input, // Reference to the Input function itself
  props: {
    id: "company-tax-id",
    placeholder: "Enter company Tax ID"
  }
}
```

## How Reconciliation Works

When React needs to update the UI (after state changes or a re-render), it:

1. Creates a new element tree by calling your components
2. Compares it with the previous tree
3. Figures out what DOM operations are needed to make the real DOM match the new tree
4. Performs those operations efficiently

The comparison algorithm follows these key principles:

### 1. Element Type Determines Identity

React first checks the "type" of elements. If the type changes, React rebuilds the entire subtree:

```tsx
// From this (first render)
<div>
  <Counter />
</div>

// To this (second render)
<span>
  <Counter />
</span>
```

Since `div` changed to `span`, React destroys the entire old tree (including `Counter`) and builds a new one from scratch.

### 2. Position in the Tree Matters

React compares elements at the same position in the tree:

```tsx
// Before
<>
  {showDetails ? <UserProfile userId={123} /> : <LoginPrompt />}
</>

// After (when showDetails changes)
<>
  {showDetails ? <UserProfile userId={123} /> : <LoginPrompt />}
</>
```

In this conditional example, when `showDetails` is `true`, there's a `UserProfile` element at position 1. When it's `false`, there's a `LoginPrompt` at position 1. React sees different component types at the same position, so it unmounts one and mounts the other.

But if we had two components of the same type:

```tsx
// Before
<>
  {isPrimary ? (
    <UserProfile userId={123} role="primary" />
  ) : (
    <UserProfile userId={456} role="secondary" />
  )}
</>
```

React sees the same component type (`UserProfile`) at position 1 before and after, so it just updates its props rather than destroying and recreating the component.

### 3. Keys Override Position-Based Comparison

The `key` attribute lets you override the position-based identity:

```tsx
<>
  {isPrimary ? (
    <UserProfile key="active-profile" userId={123} role="primary" />
  ) : (
    <UserProfile key="active-profile" userId={456} role="secondary" />
  )}
</>
```

Even if the components appear in different branches of the conditional, React will treat them as the same component because they have the same key, preserving state when switching between them.

## The Magic of Keys

Keys are primarily known for their role in lists, but they have deeper implications for React's reconciliation process.

### Why Keys Are Required for Lists

When rendering lists, React uses keys to track which items have been added, removed, or reordered:

```tsx
<ul>
  {items.map((item) => (
    <li key={item.id}>{item.text}</li>
  ))}
</ul>
```

Without keys, React would solely rely on the element's position in the array. If you insert a new item at the beginning, React would see every element as having changed position and would rerender the entire list.

With keys, React can match elements between renders regardless of their position.

### Keys Outside of Arrays?

React doesn't force you to add keys for static elements:

```tsx
// No keys needed
<>
  <Input />
  <Input />
</>
```

This works because React knows these elements are static - their position in the tree is predictable.

But keys can be powerful even outside of lists. Consider this example:

```tsx
const Component = () => {
  const [isReverse, setIsReverse] = useState(false);

  return (
    <>
      <Input key={isReverse ? "some-key" : null} />
      <Input key={!isReverse ? "some-key" : null} />
    </>
  );
};
```

When `isReverse` toggles, the key `'some-key'` moves from one input to the other, causing React to "move" the component's state between the two positions!

### Mixing Dynamic and Static Elements

A common worry is whether adding items to a dynamic list might shift the identity of static elements after the list:

```tsx
<>
  {items.map((item) => (
    <ListItem key={item.id} />
  ))}
  <StaticElement /> {/* Will this re-mount if items change? */}
</>
```

React handles this intelligently. It treats the entire dynamic list as a single unit at the first position, so the `StaticElement` will always maintain its position and identity, regardless of changes to the list.

Here's how React actually represents this internally:

```tsx
[
  // The entire dynamic array becomes a single child
  [
    { type: ListItem, key: "1" },
    { type: ListItem, key: "2" },
  ],
  { type: StaticElement }, // Always maintains its second position
];
```

Even if you add or remove items from the list, the `StaticElement` will remain at position 2 in the parent array. This means it won't re-mount when the list changes. This is a clever optimization that ensures static elements don't get unnecessarily re-mounted due to changes in adjacent dynamic lists.

## Component Identity and Performance

Understanding these reconciliation details explains several React performance patterns:

### 1. Why Inline Component Definitions Are Bad

Defining components inside other components creates new function references on every render:

```tsx
const Parent = () => {
  // Bad practice: InnerComponent recreated on every render
  const InnerComponent = () => <div>Inner content</div>;

  return <InnerComponent />;
};
```

Since the component's "type" (function reference) changes on every render, React treats it as a completely different component, unmounting and remounting it every time.

### 2. Why Composition Patterns Work

The composition pattern from our previous article leverages React's reconciliation algorithm:

```tsx
const CounterButton = () => {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(count + 1)}>Count: {count}</button>;
};

const Parent = () => {
  return (
    <div>
      <CounterButton />
      <ExpensiveComponent />
    </div>
  );
};
```

When `count` changes, only the `CounterButton` tree needs reconciliation. React doesn't even touch the `ExpensiveComponent` tree since it's in a separate branch.

### 3. Using Keys for Advanced State Preservation

Based on our understanding of keys, we can implement advanced patterns:

```tsx
const TabContent = ({ activeTab }) => {
  // All tab contents have the same key, so React preserves state
  // when switching between tabs
  return (
    <div>
      {activeTab === "profile" && <ProfileTab key="tab-content" />}
      {activeTab === "settings" && <SettingsTab key="tab-content" />}
      {activeTab === "activity" && <ActivityTab key="tab-content" />}
    </div>
  );
};
```

Why does this work? When the `activeTab` changes, React sees:

1. Before: An element with type `ProfileTab` and key `"tab-content"`
2. After: An element with type `SettingsTab` and key `"tab-content"`

React identifies components first by key, then by type. Since the key remains the same, React treats this as "the same component changed its type" rather than "one component was unmounted and another mounted."

This effectively transfers the internal state from one component to another! If `ProfileTab` had form inputs with user-entered values, those values would persist when switching to `SettingsTab`, even though they're completely different components.

This pattern can be useful for preserving form input state between tabs or wizard steps, or for transition effects where you want to maintain some state while changing the visual representation.

## State Colocation: A Powerful Performance Pattern

State colocation is a pattern that involves keeping state as close as possible to where it's used. This approach minimizes unnecessary re-renders by ensuring that only the components directly affected by state changes are updated.

Consider this example:

```tsx
// Poor performance - entire app re-renders when filter changes
const App = () => {
  const [filterText, setFilterText] = useState("");
  const filteredUsers = users.filter((user) => user.name.includes(filterText));

  return (
    <>
      <SearchBox filterText={filterText} onChange={setFilterText} />
      <UserList users={filteredUsers} />
      <ExpensiveComponent />
    </>
  );
};
```

When `filterText` changes, the entire `App` component re-renders, including `ExpensiveComponent` which isn't affected by the filter.

By colocating the filter state with just the components that use it:

```tsx
const UserSection = () => {
  const [filterText, setFilterText] = useState("");
  const filteredUsers = users.filter((user) => user.name.includes(filterText));

  return (
    <>
      <SearchBox filterText={filterText} onChange={setFilterText} />
      <UserList users={filteredUsers} />
    </>
  );
};

const App = () => {
  return (
    <>
      <UserSection />
      <ExpensiveComponent />
    </>
  );
};
```

Now when the filter changes, only `UserSection` re-renders. This pattern not only improves performance but also leads to better component design by ensuring each component only manages the state that truly belongs to it.

## Component Design: Optimizing for Change

Performance optimization is often a component design problem. If a component does too many things, it's more likely to re-render unnecessarily.

Before reaching for `React.memo`, ask:

1. **Does this component have mixed responsibilities?** Components that handle multiple concerns are likely to re-render more frequently.

2. **Is state being lifted too high?** When state is kept higher in the tree than needed, it causes more components to re-render.

Consider this example:

```tsx
// Problematic design - mixed concerns
const ProductPage = ({ productId }) => {
  const [selectedSize, setSelectedSize] = useState("medium");
  const [quantity, setQuantity] = useState(1);
  const [shipping, setShipping] = useState("express");
  const [reviews, setReviews] = useState([]);

  // Fetches both product details and reviews
  useEffect(() => {
    fetchProductDetails(productId);
    fetchReviews(productId).then(setReviews);
  }, [productId]);

  return (
    <div>
      <ProductInfo
        selectedSize={selectedSize}
        onSizeChange={setSelectedSize}
        quantity={quantity}
        onQuantityChange={setQuantity}
      />
      <ShippingOptions shipping={shipping} onShippingChange={setShipping} />
      <Reviews reviews={reviews} />
    </div>
  );
};
```

Every time the size, quantity, or shipping changes, the entire page re-renders, including the unrelated reviews section.

A better design separates these concerns:

```tsx
const ProductPage = ({ productId }) => {
  return (
    <div>
      <ProductConfig productId={productId} />
      <ReviewsSection productId={productId} />
    </div>
  );
};

const ProductConfig = ({ productId }) => {
  const [selectedSize, setSelectedSize] = useState("medium");
  const [quantity, setQuantity] = useState(1);
  const [shipping, setShipping] = useState("express");

  // Product-specific logic

  return (
    <>
      <ProductInfo
        selectedSize={selectedSize}
        onSizeChange={setSelectedSize}
        quantity={quantity}
        onQuantityChange={setQuantity}
      />
      <ShippingOptions shipping={shipping} onShippingChange={setShipping} />
    </>
  );
};

const ReviewsSection = ({ productId }) => {
  const [reviews, setReviews] = useState([]);

  useEffect(() => {
    fetchReviews(productId).then(setReviews);
  }, [productId]);

  return <Reviews reviews={reviews} />;
};
```

This structure ensures that changing the product size doesn't cause the reviews to re-render. No memoization needed - just good component boundaries.

## Reconciliation and Clean Architecture

This understanding of reconciliation aligns perfectly with Clean Architecture principles:

1. **Single Responsibility Principle**: Each component should have one reason to change. When components are focused on a single responsibility, they're less likely to trigger unnecessary re-renders.

2. **Dependency Inversion**: Components should depend on abstractions, not concrete implementations. This makes it easier to optimize performance through composition.

3. **Interface Segregation**: Components should have minimal, focused interfaces. This reduces the chance of prop changes triggering unnecessary re-renders.

## Practical Guidelines

Based on our deep dive into reconciliation, here are some practical guidelines:

1. **Keep component definitions outside parent components** to prevent remounting.

2. **Move state down** to isolate re-render boundaries.

3. **Be consistent with component types** in the same position to avoid unmounting.

4. **Use keys strategically** - not just for lists, but whenever you want to control component identity.

5. **When debugging re-render issues**, think in terms of element trees and component identity.

6. **Remember that React.memo is just a tool** that works within the constraints of reconciliation - it doesn't change the fundamental algorithm.

## Conclusion

Understanding React's reconciliation algorithm reveals the "why" behind many React performance patterns. It explains why composition works so well, why we need keys for lists, and why defining components inside other components is problematic.

This knowledge helps us make better architectural decisions that naturally lead to performant React applications. Rather than fighting React's reconciliation algorithm with excessive memoization, we can work with it by designing component structures that align with how React identifies and updates components.

The next time you're optimizing a React application, think about how your component structure affects the reconciliation process. Sometimes, the best optimization is a simpler, more focused component tree that respects how React identifies and updates components.

What patterns have you found most effective for working with React's reconciliation process? I'd love to hear your experiences, use the Feedback.One button on the right 🤓
