---
title: "Interface Segregation: Why Your Interfaces Should Be Small and Focused"
description: "Part 2 of our Clean Architecture series, exploring the 'I' in SOLID"
tags:
  ["architecture", "SOLID", "clean architecture", "go", "golang", "interfaces"]
date: 2025-01-14
---

## Introduction

In our [previous post](/posts/clean-architecture-and-plugins-in-go), we explored the Dependency Inversion Principle and how it enables clean, modular architectures. Today, let's dive into another crucial SOLID principle: Interface Segregation.

Again, kudos to Uncle Bob for reminding me about the importance of good **software architecture** in his classic [Clean Architecture](https://amzn.to/4iAc8o1)! That book is my primary inspiration for this series. Without clean architecture, we'll all be building firmware (my paraphrased summary).

> The Interface Segregation Principle (ISP) states that clients should not be forced to depend on interfaces they don't use.

This principle might sound obvious, but its violation is surprisingly common. Let's explore why it matters and how to apply it effectively.

## The Problem with "Fat" Interfaces

Consider this common anti-pattern in many codebases:

```go
// DON'T DO THIS
type UserService interface {
    CreateUser(user User) error
    GetUser(id string) (User, error)
    UpdateUser(user User) error
    DeleteUser(id string) error
    ValidatePassword(password string) bool
    SendWelcomeEmail(user User) error
    GenerateAuthToken(user User) (string, error)
    ResetPassword(email string) error
    UpdateLastLogin(id string) error
}
```

This interface violates ISP because:

1. Most clients only need a subset of these methods
2. Changes to any method affect all implementations
3. Testing becomes unnecessarily complex

## Better: Small, Focused Interfaces

Instead, we should break this down into cohesive interfaces:

```go
type UserReader interface {
    GetUser(id string) (User, error)
}

type UserWriter interface {
    CreateUser(user User) error
    UpdateUser(user User) error
    DeleteUser(id string) error
}

type UserAuthenticator interface {
    ValidatePassword(password string) bool
    GenerateAuthToken(user User) (string, error)
    UpdateLastLogin(id string) error
}

type UserNotifier interface {
    SendWelcomeEmail(user User) error
}
```

Now clients can depend only on what they need:

```go
type UserProfileHandler struct {
    reader UserReader
}

type UserRegistrationHandler struct {
    writer  UserWriter
    auth    UserAuthenticator
    notifier UserNotifier
}
```

## The Power of Composition

Go's interface composition makes this pattern particularly elegant:

```go
// When you do need everything
type CompleteUserService interface {
    UserReader
    UserWriter
    UserAuthenticator
    UserNotifier
}
```

This approach gives us several benefits:

1. **Flexibility**: Implementations can be mixed and matched
2. **Testability**: Mocking becomes trivial
3. **Maintainability**: Changes affect fewer components
4. **Clarity**: Interfaces document their purpose through focus

## Real-World Example: HTTP Handlers

Let's see how this applies to a typical web service:

```go
type UserHandler struct {
    reader UserReader
    writer UserWriter
}

func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
    // Only needs UserReader
    id := chi.URLParam(r, "id")
    user, err := h.reader.GetUser(id)
    // ... handle response
}

func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
    // Only needs UserWriter
    var user User
    if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }

    if err := h.writer.CreateUser(user); err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    w.WriteHeader(http.StatusCreated)
}
```

## Testing Benefits

Small interfaces make testing much simpler:

```go
type mockUserReader struct {
    users map[string]User
}

func (m *mockUserReader) GetUser(id string) (User, error) {
    if user, ok := m.users[id]; ok {
        return user, nil
    }
    return User{}, errors.New("user not found")
}

func TestGetUser(t *testing.T) {
    mock := &mockUserReader{
        users: map[string]User{
            "123": {ID: "123", Name: "Test User"},
        },
    }

    handler := &UserHandler{reader: mock}
    // Test your handler with a simple mock
}
```

## Key Takeaways

1. **Keep interfaces small and focused** - they should do one thing well
2. **Let clients define interfaces** - don't force unnecessary dependencies
3. **Use composition** when you need to combine functionality
4. **Think in terms of roles** rather than objects

## Conclusion

Interface Segregation might seem like extra work initially, but it pays dividends in maintainability, testability, and flexibility. Combined with Dependency Inversion from our previous post, these principles form a powerful foundation for clean, maintainable architectures.

Stay tuned for our next post in the series, where we'll explore the Liskov Substitution Principle!

> **Pro tip**: When in doubt about interface size, err on the side of making them too small. It's easier to compose small interfaces than to break apart large ones.
