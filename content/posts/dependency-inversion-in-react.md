---
title: "Dependency Inversion in React: Building Truly Testable Components"
date: 2025-05-09
description: "Learn how to apply the Dependency Inversion Principle in React to create more testable, maintainable, and flexible components. A practical guide to writing better React code."
tags: ["react", "clean-architecture", "testing", "solid-principles"]
draft: false
---

In the world of React development, we often find ourselves writing components that are tightly coupled to their dependencies. This makes testing difficult, maintenance a challenge, and change nearly impossible. The Dependency Inversion Principle (DIP) offers a way out of this mess, but how do we apply it effectively **in React**?

**Note:** For a more backend-oriented take on Dependency Inversion, check out my previous post on [Dependency Inversion in Go Using Plugins](https://cekrem.github.io/posts/clean-architecture-and-plugins-in-go/).

## The Problem: Tight Coupling in React

Consider this common scenario:

```tsx
const UserProfile = () => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/user")
      .then((res) => res.json())
      .then((data) => {
        setUser(data);
        setLoading(false);
      });
  }, []);

  if (loading) return <LoadingSpinner />;
  return <UserDetails user={user} />;
};
```

This component has several problems:

- It's tightly coupled to the fetch API
- It's difficult to test because of the direct API call
- It's hard to change the data source
- It's impossible to test loading states easily

![Michael Scott sad](https://media0.giphy.com/media/v1.Y2lkPTc5MGI3NjExejNkMWJuengyMnJ4MGw2eHkwNTJyNjhrZXJndTZxcjExNXBuMDltciZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/ZHnKJsXLI6ZClYFwzH/giphy.gif)

## The Solution: Dependency Inversion

The Dependency Inversion Principle states that high-level modules should not depend on low-level modules. Both should depend on abstractions. In React, this means our components should depend on interfaces, not concrete implementations.

Let's see how we can refactor this:

```tsx
interface UserRepository {
  getUser: () => Promise<User>;
}

const UserProfile = ({
  userRepository,
}: {
  userRepository: UserRepository;
}) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    userRepository.getUser().then((data) => {
      setUser(data);
      setLoading(false);
    });
  }, [userRepository]);

  if (loading) return <LoadingSpinner />;
  return <UserDetails user={user} />;
};
```

(You could of course consider extracting all this state + useEffect stuff into a custom hook, but that's beside the point at this point.)

## Implementing the Repository

Now we can create concrete implementations of our repository:

```tsx
class ApiUserRepository implements UserRepository {
  async getUser(): Promise<User> {
    const response = await fetch("/api/user");
    return response.json();
  }
}

class MockUserRepository implements UserRepository {
  private resolveUser: (user: User) => void = () => {};
  private rejectUserPromise: (error: Error) => void = () => {};

  getUser(): Promise<User> {
    return new Promise((resolve, reject) => {
      this.resolveUser = resolve;
      this.rejectUserPromise = reject;
    });
  }

  // Helper method to resolve the promise
  resolveWithUser(user: User) {
    this.resolveUser(user);
  }

  // Helper method to reject the promise
  rejectUser(error: Error) {
    this.rejectUserPromise(error);
  }
}
```

## Testing Made Easy

With this structure, testing becomes straightforward:

```tsx
describe("UserProfile", () => {
  it("shows loading state initially", () => {
    const mockRepo = new MockUserRepository();
    render(<UserProfile userRepository={mockRepo} />);
    expect(screen.getByTestId("loading-spinner")).toBeInTheDocument();
  });

  it("displays user data when loaded", async () => {
    const mockRepo = new MockUserRepository();
    render(<UserProfile userRepository={mockRepo} />);

    // Simulate data fetching
    mockRepo.resolveWithUser({
      id: 1,
      name: "Test User",
      email: "test@example.com",
    });

    const userData = await screen.findByText("Test User");
    expect(userData).toBeInTheDocument();
  });

  // Testing exceptions would be equally stragihtforward, but excluded for brevity
});
```

## Best Practices

1. **Define Clear Interfaces**: Create interfaces that represent your dependencies
2. **Inject Dependencies**: Pass dependencies as props or through context, or better yet using [TSyringe](#note-on-dependency-injection)
3. **Test in Isolation**: Each component should be testable without its dependencies

## Conclusion

Applying the Dependency Inversion Principle in React leads to:

- More testable components
- Easier maintenance
- Better separation of concerns
- More flexible and reusable code

Remember: The goal isn't to add complexity, but to make your code more maintainable and testable. Start small, and apply these principles where they make the most sense.

![Michael Scott happy](https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExcjRvMndpZnp5dnZldGZ5am8xc3E3dzk2aGd5dnEyN3E1aHZ6MXMybyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/xMGh0bajSyNdC/giphy.gif)

## Further Reading

- [Clean Architecture](https://amzn.to/4jOTM2M) by Robert C. Martin
- [React Testing Library](https://testing-library.com/docs/react-testing-library/intro/) (official docs)
- [Single Responsibility Principle in React](/posts/single-responsibility-principle-in-react) (a previous post)

## Note on Dependency _Injection_

While this guide focuses on applying the Dependency Inversion Principle in React, we won't delve into the specifics of implementing dependency injection in a clean and scalable manner. However, if you're interested in exploring this further, libraries like [TSyringe](https://github.com/microsoft/tsyringe) provide a good starting point for managing dependencies effectively in your React applications.
