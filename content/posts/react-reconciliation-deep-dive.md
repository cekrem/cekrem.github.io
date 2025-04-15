---
title: "React Reconciliation: The Hidden Engine Behind Your Components"
description: "A deep dive into how React's reconciliation algorithm works and why it matters for performance"
tags:
  ["react", "performance", "architecture", "clean architecture", "typescript"]
date: 2025-04-08
---

##### Update: The "Using Keys for Advanced State Preservation" section has been corrected. The original example incorrectly suggested that using the same key across different component types would preserve state between them. This error occurred when simplifying a more complex example shortly before publishing. Thanks to reader feedback for pointing this out, I'm very grateful! I also messed up an internal link, but that's fixed as well. Thanks

## The Reconciliation Engine

In my previous articles ([1](/posts/beyond-react-memo-smarter-performance-optimization/), [2](/posts/react-memo-when-it-helps-when-it-hurts/)), I explored how `React.memo` works and smarter ways to optimize performance through composition. But to truly master React performance, we need to understand the engine that powers it all: React's reconciliation algorithm.

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

React's reconciliation algorithm relies heavily on component position within the tree structure. Position serves as a primary identity indicator during the diffing process.

```tsx
// Let's pretend showDetails is true: Render UserProfile
<>
  {showDetails ? <UserProfile userId={123} /> : <LoginPrompt />}
</>

// Let's pretend showDetails is false: Render LoginPrompt instead
<>
  {showDetails ? <UserProfile userId={123} /> : <LoginPrompt />}
</>
```

In this conditional example, React treats the first child position of the fragment as a single "slot." When `showDetails` changes from `true` to `false`, React compares what's in that position across renders and sees different component types (`UserProfile` vs `LoginPrompt`). Since the component type at position 1 has changed, React unmounts the previous component entirely (including its state) and mounts the new one.

This position-based identity also explains why components preserve their state in simpler cases:

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

Here, regardless of the `isPrimary` value, React sees the same component type (`UserProfile`) at the same position. It will preserve the component instance, simply updating its props rather than remounting it.

This position-based approach works well for most scenarios, but becomes problematic when:

1. Component positions shift dynamically (like in sorted lists)
2. You need to preserve state when components move between different positions
3. You want to control exactly when components should be remounted

This is where React's key system comes in.

### 3. Keys Override Position-Based Comparison

The `key` attribute gives developers explicit control over component identity, overriding React's default position-based identification:

```tsx
const TabContent = ({ activeTab, tabs }) => {
  return (
    <div className="tab-container">
      {tabs.map((tab) => (
        // Key overrides position-based comparison
        <div key={tab.id} className="tab-content">
          {activeTab === tab.id ? (
            <UserProfile
              key="active-profile"
              userId={tab.userId}
              role={tab.role}
            />
          ) : (
            <div key="placeholder" className="placeholder">
              Select this tab to view {tab.userId}'s profile
            </div>
          )}
        </div>
      ))}
    </div>
  );
};
```

Even if the `UserProfile` component appears in different positions across conditional renders, React will treat components with the same key as the same component. When a tab becomes active, React preserves the component's state because the key "active-profile" remains consistent, allowing for smoother transitions between tabs.

This illustrates how keys provide a way to maintain component identity regardless of structural position in the render tree - a powerful tool for controlling how React reconciles your component hierarchy.

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

### 3. Keys for Strategic DOM Control

Keys aren't just for lists - they're a powerful tool for controlling component and DOM element identity in React. For React component state preservation across different views, remember that key and component type work together - components with the same key but different types will still unmount and remount. In these cases, lifting state up is typically the better approach:

```tsx
// State lifting approach for preserving state across different views (keys are no good here...)
const TabContent = ({ activeTab }) => {
  // State that needs to be preserved across tab changes
  const [sharedState, setSharedState] = useState({
    /* initial state */
  });

  return (
    <div>
      {activeTab === "profile" && (
        <ProfileTab state={sharedState} onStateChange={setSharedState} />
      )}
      {activeTab === "settings" && (
        <SettingsTab state={sharedState} onStateChange={setSharedState} />
      )}
      {/* Other tabs */}
    </div>
  );
};
```

Preserving the key woundn't be enough in this case since the type (and reference) is different between tabs.

But take a look at this example, however, using keys and uncontrolled components:

```tsx
const UserForm = ({ userId }) => {
  // No React state here - using uncontrolled inputs

  return (
    <form>
      <input
        key={userId}
        name="username"
        // Uncontrolled input with defaultValue instead of value
        defaultValue=""
      />
      {/* Other form inputs */}
    </form>
  );
};
```

By giving the uncontrolled input a key based on userId, we ensure that React creates a completely new DOM element whenever the userId changes. Since the uncontrolled input's state lives in the DOM itself rather than in React state, this effectively resets the input when switching between different users. In this case `key` is all you need.

Quite something, huh?

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
