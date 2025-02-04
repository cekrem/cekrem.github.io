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
      const response = await fetch("/api/user");
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
      await fetch("/api/user", {
        method: "PUT",
        body: JSON.stringify(data),
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
      <form onSubmit={/* form logic */}>{/* Complex form fields */}</form>
      <UserStats userId={user.id} />
      <UserPosts userId={user.id} />
    </div>
  );
};
```

This component violates SRP because it's responsible for:

1. Data fetching
2. Error handling
3. Loading states
4. Form handling
5. Layout and presentation

## A Better Way: Separation of Concerns

Let's break it down into focused components:

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
  onUpdate,
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

// Container component
const UserProfileContainer = ({ userId }: { userId: string }) => {
  const { user, loading, error, refetch } = useUser(userId);

  const handleUpdate = async (data: Partial<User>) => {
    try {
      await fetch(`/api/user/${userId}`, {
        method: "PUT",
        body: JSON.stringify(data),
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

## Key Takeaways

1. **Separate data and presentation** - use hooks for data, components for UI
2. **Create focused components** - each component should do one thing well
3. **Use composition** to build complex features from simple parts
4. **Extract reusable logic** into custom hooks
5. **Think in layers** - data, business logic, presentation

## Conclusion

When each component has a single, well-defined responsibility, your entire application becomes more maintainable, testable, and flexible.

As Uncle Bob emphasizes in [Clean Architecture](https://amzn.to/4iAc8o1), it's about having a single _reason to change_. This subtle distinction is crucial:

- A component might do several related things, but if they all change for the same reason (like updating the user profile UI), they probably belong together
- Conversely, two seemingly simple operations might need to be separated if they change for different reasons (like user preferences vs. authentication logic)

> **Pro tip**: When you find yourself using the word "and" to describe what a component does, it might be violating SRP. Split it up! But also consider _why_ those parts might need to change, and who would request those changes.

## The end

This concludes the Clean Architecture and SOLID design principles series. I hope you've enjoyed it and learned something, I'm quite sure I have at least.

## Update: Friendly Disclaimer and Reminder

If you're looking for a comprehensive guide to software architecture, this is not it. The purpose of my recent posts about software architecture is to explore some some principles in a practical way, principles I've previously been too quick to dismiss or too lazy to apply. I'm neither claiming mastery of these concepts, nor am I suggesting that these principles should be rigidly applied in every situation. I'm not even proposing that my brief examples are the best way to implement or even explain these principles. Rather, I'm documenting my attempts to bridge classical software engineering principles with contemporary development practices. In fact, I have yet to decide for my self how close to "Clean Architecture" I want to get in the end vs how pragmatic I want to be. But for now I'm (mostly) enjoying the learning and exploration. Keep that in mind before you harass me, Uncle Bob or anyone else on Reddit about it 😅

And to all of you who have disagreed with me in a meaningful and respectful way, thank you. It's been a great learning experience for me.

Thanks :)
