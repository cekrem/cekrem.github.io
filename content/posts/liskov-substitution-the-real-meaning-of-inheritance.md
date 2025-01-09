---
title: "Liskov Substitution: The Real Meaning of Inheritance"
description: "Part 3 of our Clean Architecture series, exploring the 'L' in SOLID"
tags: ["architecture", "SOLID", "clean architecture", "kotlin", "inheritance"]
date: 2025-01-21
---

## Introduction

After exploring [Dependency Inversion](/posts/clean-architecture-and-plugins-in-go) and [Interface Segregation](/posts/interface-segregation-in-practice), let's tackle perhaps the most misunderstood principle of SOLID: The Liskov Substitution Principle (LSP).

Again, kudos to Uncle Bob for reminding me about the importance of good **software architecture** in his classic [Clean Architecture](https://amzn.to/4iAc8o1)! That book is my primary inspiration for this series. Without clean architecture, we'll all be building firmware (my paraphrased summary).

> The Liskov Substitution Principle states that if S is a subtype of T, then objects of type T may be replaced with objects of type S without altering any of the desirable properties of the program.

In simpler terms: subtypes must be substitutable for their base types. Let's see what this really means in practice.

## The Classic Rectangle-Square Problem

This is the canonical example of LSP violation:

```kotlin
open class Rectangle {
    open var width: Int = 0
    open var height: Int = 0

    fun area() = width * height
}

// This seems logical, but violates LSP
class Square : Rectangle() {
    override var width: Int = 0
        set(value) {
            field = value
            height = value
        }

    override var height: Int = 0
        set(value) {
            field = value
            width = value
        }
}

// This code will fail for Square
fun resizeRectangle(rectangle: Rectangle) {
    rectangle.width = 4
    rectangle.height = 5
    assert(rectangle.area() == 20) // Fails for Square!
}
```

The problem? While mathematically a square is a rectangle, in terms of behavior substitutability, it isn't. The `Square` class violates LSP because it changes the behavior that clients of `Rectangle` expect.

## A Better Approach

Instead of inheritance, we can use composition and interfaces:

```kotlin
interface Shape {
    fun area(): Int
}

class Rectangle(
    var width: Int,
    var height: Int
) : Shape {
    override fun area() = width * height
}

class Square(
    var side: Int
) : Shape {
    override fun area() = side * side
}
```

## Real-World Example: Payment Processing

Let's look at a more practical example involving payment processing:

```kotlin
interface PaymentProcessor {
    fun processPayment(amount: Money): Result<Transaction>
}

class CreditCardProcessor : PaymentProcessor {
    override fun processPayment(amount: Money): Result<Transaction> {
        // Process credit card payment
        return Result.success(Transaction(amount))
    }
}

class DebitCardProcessor : PaymentProcessor {
    override fun processPayment(amount: Money): Result<Transaction> {
        // Process debit card payment
        return Result.success(Transaction(amount))
    }
}

// This works with any PaymentProcessor
class CheckoutService(
    private val paymentProcessor: PaymentProcessor
) {
    fun checkout(cart: ShoppingCart) {
        val amount = cart.total()
        paymentProcessor.processPayment(amount)
            .onSuccess { transaction ->
                // Handle success
            }
            .onFailure { error ->
                // Handle failure
            }
    }
}
```

## Common LSP Violations

### 1. Throwing Unexpected Exceptions

```kotlin
interface UserRepository {
    fun findById(id: String): User?
}

// LSP Violation: Throws instead of returning null
class CachedUserRepository : UserRepository {
    override fun findById(id: String): User? {
        throw NotImplementedError("Cache not initialized")
        // Should return null if not found
    }
}
```

### 2. Returning Null When Base Type Doesn't

```kotlin
interface DataFetcher {
    fun fetchData(): List<String>
}

// LSP Violation: Returns null when base contract promises List
class RemoteDataFetcher : DataFetcher {
    override fun fetchData(): List<String> {
        return if (isConnected()) {
            listOf("data")
        } else {
            null // Violation! Should return empty list
        }
    }
}
```

## How to Ensure LSP Compliance

1. **Use Contract Tests**

```kotlin
abstract class PaymentProcessorTest {
    abstract fun createProcessor(): PaymentProcessor

    @Test
    fun `should process valid payment`() {
        val processor = createProcessor()
        val result = processor.processPayment(Money(100))
        assert(result.isSuccess)
    }

    @Test
    fun `should handle zero amount`() {
        val processor = createProcessor()
        val result = processor.processPayment(Money(0))
        assert(result.isSuccess)
    }
}

class CreditCardProcessorTest : PaymentProcessorTest() {
    override fun createProcessor() = CreditCardProcessor()
}

class DebitCardProcessorTest : PaymentProcessorTest() {
    override fun createProcessor() = DebitCardProcessor()
}
```

2. **Document Preconditions and Postconditions**

```kotlin
interface AccountService {
    /**
     * Withdraws money from account
     *
     * Preconditions:
     * - Amount must be positive
     * - Account must exist
     * - Account must have sufficient balance
     *
     * Postconditions:
     * - Account balance is reduced by amount
     * - Returns success with transaction details
     * - Never throws exceptions (uses Result)
     */
    fun withdraw(accountId: String, amount: Money): Result<Transaction>
}
```

## Key Takeaways

1. **Inheritance isn't always the answer** - prefer composition when behavior differs
2. **Think in terms of contracts** - subtypes must fulfill the base type's contract
3. **Use contract tests** to verify LSP compliance
4. **Document pre/postconditions** clearly
5. **Return types matter** - be consistent with null/non-null, exceptions, etc.

## Conclusion

Liskov Substitution Principle is about more than just inheritance - it's about behavioral compatibility and meeting expectations. When followed properly, it leads to more reliable and maintainable code by ensuring that components are truly interchangeable.

Stay tuned for our next post in the series, where we'll explore the Open-Closed Principle!

> **Pro tip**: If you find yourself writing comments like "don't use X in Y way" or "this override behaves differently", you might be violating LSP.
