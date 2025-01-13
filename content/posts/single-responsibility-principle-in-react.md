---
title: "Single Responsibility Principle in React: The Art of Component Focus"
description: "The final part of our Clean Architecture series, exploring the 'S' in SOLID"
tags: ["architecture", "SOLID", "clean architecture", "react", "typescript"]
date: 2025-02-04
---

## Introduction

We've covered [Dependency Inversion](/posts/clean-architecture-and-plugins-in-go), [Interface Segregation](/posts/interface-segregation-in-practice), [Liskov Substitution](/posts/liskov-substitution-the-real-meaning-of-inheritance), and [Open-Closed](/posts/open-closed-principle-in-react). Now it's time for the foundation of SOLID: the Single Responsibility Principle (SRP).

Again, kudos to Uncle Bob for reminding me about the importance of good **software architecture** in his classic [Clean Architecture](https://amzn.to/4iAc8o1)! That book is my primary inspiration for this series.

> The Single Responsibility Principle states that a class should have only one reason to change.

In React terms: a component should do one thing, and do it well. Let's explore what this means in practice.

## The Problem with Multiple Responsibilities

Here's a common anti-pattern:

```tsx
// DON'T DO THIS
const UserProfile = () => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  
  useEffect(() => {
    fetchUser();
  }, []);
  
  const fetchUser = async () => {
    try {
      const response = await fetch('/api/user');
      const data = await response.json();
      setUser(data);
    } catch (e) {
      setError(e as Error);
    } finally {
      setLoading(false);
    }
  };
  
  const handleUpdateProfile = async (data: Partial<User>) => {
    try {
      await fetch('/api/user', {
        method: 'PUT',
        body: JSON.stringify(data)
      });
      fetchUser(); // Refresh data
    } catch (e) {
      setError(e as Error);
    }
  };
  
  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;
  if (!user) return <div>No user found</div>;
  
  return (
    <div>
      <h1>{user.name}</h1>
      <form onSubmit={/* form logic */}>
        {/* Complex form fields */}
      </form>
      <UserStats userId={user.id} />
      <UserPosts userId={user.id} />
    </div>
  );
};
```

This component violates SRP because it's responsible for:
1. Data fetching and state management
2. Error handling
3. Loading states
4. Form handling
5. Layout and presentation

## Separating Responsibilities

Let's break this down into focused components:

```tsx
// Data fetching hook
const useUser = (userId: string) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    fetchUser();
  }, [userId]);

  const fetchUser = async () => {
    try {
      const response = await fetch(`/api/user/${userId}`);
      const data = await response.json();
      setUser(data);
    } catch (e) {
      setError(e as Error);
    } finally {
      setLoading(false);
    }
  };

  return { user, loading, error, refetch: fetchUser };
};

// Presentation component
const UserProfileView = ({ 
  user, 
  onUpdate 
}: { 
  user: User; 
  onUpdate: (data: Partial<User>) => void;
}) => (
  <div>
    <h1>{user.name}</h1>
    <UserProfileForm user={user} onSubmit={onUpdate} />
    <UserStats userId={user.id} />
    <UserPosts userId={user.id} />
  </div>
);

// Form component
const UserProfileForm = ({ 
  user, 
  onSubmit 
}: { 
  user: User; 
  onSubmit: (data: Partial<User>) => void;
}) => {
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // Form handling logic
    onSubmit(formData);
  };

  return (
    <form onSubmit={handleSubmit}>
      {/* Form fields */}
    </form>
  );
};

// Container component
const UserProfileContainer = ({ userId }: { userId: string }) => {
  const { user, loading, error, refetch } = useUser(userId);
  
  const handleUpdate = async (data: Partial<User>) => {
    try {
      await fetch(`/api/user/${userId}`, {
        method: 'PUT',
        body: JSON.stringify(data)
      });
      refetch();
    } catch (e) {
      // Error handling
    }
  };
  
  if (loading) return <LoadingSpinner />;
  if (error) return <ErrorMessage error={error} />;
  if (!user) return <NotFound message="User not found" />;
  
  return <UserProfileView user={user} onUpdate={handleUpdate} />;
};
```

## Error Boundary Pattern

Error handling can be its own responsibility:

```tsx
class ErrorBoundary extends React.Component<{
  fallback: React.ReactNode;
  children: React.ReactNode;
}> {
  state = { hasError: false, error: null };

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback;
    }

    return this.props.children;
  }
}

// Usage
const App = () => (
  <ErrorBoundary fallback={<GlobalErrorView />}>
    <UserProfileContainer userId="123" />
  </ErrorBoundary>
);
```

## Layout Components

Even layouts should have single responsibilities:

```tsx
const PageLayout = ({ children }: { children: React.ReactNode }) => (
  <div className="page-layout">
    <Header />
    <main>{children}</main>
    <Footer />
  </div>
);

const TwoColumnLayout = ({ 
  left, 
  right 
}: { 
  left: React.ReactNode; 
  right: React.ReactNode;
}) => (
  <div className="two-column-layout">
    <div className="left-column">{left}</div>
    <div className="right-column">{right}</div>
  </div>
);
```

## Testing Benefits

SRP makes testing much more focused:

```tsx
describe('UserProfileView', () => {
  const mockUser = {
    id: '123',
    name: 'Test User'
  };
  
  it('renders user name', () => {
    render(
      <UserProfileView 
        user={mockUser} 
        onUpdate={() => {}} 
      />
    );
    
    expect(screen.getByText('Test User')).toBeInTheDocument();
  });
});

describe('useUser', () => {
  it('fetches user data', async () => {
    const { result } = renderHook(() => useUser('123'));
    
    expect(result.current.loading).toBe(true);
    await waitFor(() => {
      expect(result.current.user).toBeDefined();
    });
  });
});
```

## Key Takeaways

1. **Separate data and presentation** - use hooks for data, components for UI
2. **Create focused components** - each component should do one thing well
3. **Use composition** to build complex features from simple parts
4. **Extract reusable logic** into custom hooks
5. **Think in layers** - data, business logic, presentation

## Conclusion

When each component has a single, well-defined responsibility, your entire application becomes more maintainable, testable, and flexible.

It's important to note that "single responsibility" doesn't always mean "does only one thing" in a literal sense. As Uncle Bob emphasizes in [Clean Architecture](https://amzn.to/4iAc8o1), it's about having a single *reason to change*. This subtle distinction is crucial:

- A component might do several related things, but if they all change for the same reason (like updating the user profile UI), they probably belong together
- Conversely, two seemingly simple operations might need to be separated if they change for different reasons (like user preferences vs. authentication logic)

The key is identifying the right boundaries based on the *actors* who request changes. For example:
- UI changes requested by UX team
- Business rule changes requested by domain experts
- Infrastructure changes requested by DevOps

This "actor-based" approach to responsibilities helps create more stable and maintainable architectures. For a deeper dive into this perspective and more advanced applications of SRP, I highly recommend reading chapters 7-8 of [Clean Architecture](https://amzn.to/4iAc8o1).

This concludes our SOLID series! We've covered all five principles and seen how they apply to modern React development, as well as backend and system design in Kotlin and Go. Remember, these principles aren't rules to be followed blindly, but guidelines to help you write better, more maintainable code.

> **Pro tip**: When you find yourself using the word "and" to describe what a component does, it might be violating SRP. Split it up! But also consider *why* those parts might need to change, and who would request those changes. 