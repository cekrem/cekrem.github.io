---
title: "Open-Closed Principle in React: Building Extensible Components"
description: "Part 4 of our Clean Architecture series, exploring the 'O' in SOLID"
tags: ["architecture", "SOLID", "clean architecture", "react", "typescript"]
date: 2025-01-28
---

## Introduction

After exploring [Dependency Inversion](/posts/clean-architecture-and-plugins-in-go), [Interface Segregation](/posts/interface-segregation-in-practice), and [Liskov Substitution](/posts/liskov-substitution-the-real-meaning-of-inheritance), let's tackle the Open-Closed Principle (OCP) in the context of modern React applications.

Again, kudos to Uncle Bob for reminding me about the importance of good **software architecture** in his classic [Clean Architecture](https://amzn.to/4iAc8o1)! That book is my primary inspiration for this series.

> The Open-Closed Principle states that software entities should be open for extension but closed for modification.

In React terms: components should be easy to extend without changing their existing code. Let's see how this plays out in practice.

## The Problem with Closed Components

Here's a common anti-pattern:

```tsx
// DON'T DO THIS
const Button = ({ label, onClick, variant }: ButtonProps) => {
  let className = "button";

  // Direct modification for each variant
  if (variant === "primary") {
    className += " button-primary";
  } else if (variant === "secondary") {
    className += " button-secondary";
  } else if (variant === "danger") {
    className += " button-danger";
  }

  return (
    <button className={className} onClick={onClick}>
      {label}
    </button>
  );
};
```

This violates OCP because:

1. Adding a new variant requires modifying the component
2. The component needs to know about all possible variants
3. Testing becomes more complex with each addition

## Building Open Components

Let's refactor this to follow OCP:

```tsx
type ButtonBaseProps = {
  label: string;
  onClick: () => void;
  className?: string;
  children?: React.ReactNode;
};

const ButtonBase = ({
  label,
  onClick,
  className = "",
  children,
}: ButtonBaseProps) => (
  <button className={`button ${className}`.trim()} onClick={onClick}>
    {children || label}
  </button>
);

// Variant components extend the base
const PrimaryButton = (props: ButtonBaseProps) => (
  <ButtonBase {...props} className="button-primary" />
);

const SecondaryButton = (props: ButtonBaseProps) => (
  <ButtonBase {...props} className="button-secondary" />
);

const DangerButton = (props: ButtonBaseProps) => (
  <ButtonBase {...props} className="button-danger" />
);
```

Now we can easily add new variants without modifying existing code:

```tsx
// Adding a new variant without touching the original components
const OutlineButton = (props: ButtonBaseProps) => (
  <ButtonBase {...props} className="button-outline" />
);
```

## Component Composition Pattern

Let's look at a more complex example using composition:

```tsx
type CardProps = {
  title: string;
  children: React.ReactNode;
  renderHeader?: (title: string) => React.ReactNode;
  renderFooter?: () => React.ReactNode;
  className?: string;
};

const Card = ({
  title,
  children,
  renderHeader,
  renderFooter,
  className = "",
}: CardProps) => (
  <div className={`card ${className}`.trim()}>
    {renderHeader ? (
      renderHeader(title)
    ) : (
      <div className="card-header">{title}</div>
    )}

    <div className="card-content">{children}</div>

    {renderFooter && renderFooter()}
  </div>
);

// Extended without modification
const ProductCard = ({ product, onAddToCart, ...props }: ProductCardProps) => (
  <Card
    {...props}
    renderFooter={() => (
      <button onClick={onAddToCart}>Add to Cart - ${product.price}</button>
    )}
  />
);
```

## Higher-Order Components for Extension

HOCs provide another way to follow OCP:

```tsx
type WithLoadingProps = {
  isLoading?: boolean;
};

const withLoading = <P extends object>(
  WrappedComponent: React.ComponentType<P>
) => {
  return ({ isLoading, ...props }: P & WithLoadingProps) => {
    if (isLoading) {
      return <div className="loader">Loading...</div>;
    }

    return <WrappedComponent {...(props as P)} />;
  };
};

// Usage
const UserProfileWithLoading = withLoading(UserProfile);
```

## Custom Hooks Following OCP

Custom hooks can also follow OCP:

```tsx
const useDataFetching = <T,>(url: string) => {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<Error | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();
  }, [url]);

  const fetchData = async () => {
    try {
      const response = await fetch(url);
      const result = await response.json();
      setData(result);
    } catch (e) {
      setError(e as Error);
    } finally {
      setLoading(false);
    }
  };

  return { data, error, loading, refetch: fetchData };
};

// Extended without modification
const useUserData = (userId: string) => {
  const result = useDataFetching<User>(`/api/users/${userId}`);

  // Add user-specific functionality
  const updateUser = async (data: Partial<User>) => {
    // Update logic
  };

  return { ...result, updateUser };
};
```

## Testing Benefits

OCP makes testing much more straightforward:

```tsx
describe("ButtonBase", () => {
  it("renders with custom className", () => {
    render(<ButtonBase label="Test" onClick={() => {}} className="custom" />);

    expect(screen.getByRole("button")).toHaveClass("button custom");
  });
});

// New variants can have their own tests
describe("PrimaryButton", () => {
  it("includes primary styling", () => {
    render(<PrimaryButton label="Test" onClick={() => {}} />);

    expect(screen.getByRole("button")).toHaveClass("button button-primary");
  });
});
```

## Key Takeaways

1. **Use composition over modification** - extend through props and render props
2. **Create base components** that are easy to extend
3. **Leverage HOCs and custom hooks** for reusable extensions
4. **Think in terms of extension points** - what might need to change?
5. **Use TypeScript** to make extensions type-safe

## OCP and "Composition over Inheritance"

The React team's recommendation of ["composition over inheritance"](https://react.dev/learn/thinking-in-react) aligns perfectly with the Open-Closed Principle. Here's why:

```tsx
// Inheritance-based approach (less flexible)
class Button extends BaseButton {
  render() {
    return (
      <button className={this.getButtonClass()}>
        {this.props.icon && <Icon name={this.props.icon} />}
        {this.props.label}
      </button>
    );
  }
}

// Composition-based approach (more flexible, follows OCP)
const Button = ({
  label,
  icon,
  renderPrefix,
  renderSuffix,
  ...props
}: ButtonProps) => (
  <ButtonBase {...props}>
    {renderPrefix?.()}
    {icon && <Icon name={icon} />}
    {label}
    {renderSuffix?.()}
  </ButtonBase>
);

// Now we can extend behavior without modification
const DropdownButton = ({ items, ...props }: DropdownButtonProps) => (
  <Button
    {...props}
    renderSuffix={() => <DropdownIcon />}
    onClick={() => setIsOpen(true)}
  />
);

const LoadingButton = ({ isLoading, ...props }: LoadingButtonProps) => (
  <Button
    {...props}
    renderPrefix={() => isLoading && <Spinner />}
    disabled={isLoading}
  />
);
```

This composition-based approach:

1. Makes components open for extension (through props and render functions)
2. Keeps base components closed for modification
3. Allows for unlimited combinations of behaviors
4. Maintains type safety and prop transparency

The React team's preference for composition isn't just about style—it's about creating extensible, maintainable components that naturally follow OCP.

## Conclusion

The Open-Closed Principle might seem abstract, but in React it translates to practical patterns that make our components more maintainable and flexible. Combined with our previous SOLID principles, it helps create a robust architecture that's easy to extend and maintain.

Stay tuned for our final post in the series, where we'll explore the Single Responsibility Principle!

> **Pro tip**: If you find yourself using lots of if/else statements for different variants or behaviors, you're probably violating OCP. Consider using composition instead.

## Update: Friendly Disclaimer and Reminder

If you're looking for a comprehensive guide to software architecture, this is not it. The purpose of my recent posts about software architecture is to explore some some principles in a practical way, principles I've previously been too quick to dismiss or too lazy to apply. I'm neither claiming mastery of these concepts, nor am I suggesting that these principles should be rigidly applied in every situation. I'm not even proposing that my brief examples are the best way to implement or even explain these principles. Rather, I'm documenting my attempts to bridge classical software engineering principles with contemporary development practices. In fact, I have yet to decide for my self how close to "Clean Architecture" I want to get in the end vs how pragmatic I want to be. But for now I'm (mostly) enjoying the learning and exploration. Keep that in mind before you harass me, Uncle Bob or anyone else on Reddit about it 😅

And to all of you who have disagreed with me in a meaningful and respectful way, thank you. It's been a great learning experience for me.

Thanks :)
