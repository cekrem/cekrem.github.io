+++
title = "C# 15: Union Types, Closed Hierarchies, and the One Value™ That Isn't Any of Them"
description = "C# 15 ships union types and closed hierarchies with .NET 11. What they get right, where default(T) sneaks through, and how they compare to F# and Elm. With code I ran on the .NET 11 SDK."
date = 2026-11-09
author = "Christian Ekrem"
tags = ["csharp", "dotnet", "fsharp", "elm", "union-types", "type-safety", "functional-programming", "domain-modeling"]
categories = ["Programming", "Functional Programming"]
+++

.NET 11 launches this week at [.NET Conf](https://dotnet.microsoft.com/en-us/conf), and with it comes C# 15. The headline feature, at least for someone like me, is [union types](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/union). People have been asking for discriminated unions in C# for years, and now there's a `union` keyword in the language.

A disclaimer before we start: **C# is not my home turf.** I write Elm on the frontend, I've done a fair bit of Kotlin, and I [hope to write a lot more F#](/posts/why-i-hope-i-get-to-write-a-lot-of-fsharp-in-2026/). So this is an outsider looking at a feature I care about, in a language I don't use daily. If I've missed some well-known C# idiom below, I'd genuinely like to hear about it.

What I _can_ do is run the code. Every snippet and every compiler message below comes from SDK `11.0.100-rc.3`, the last release candidate before GA. No preview flags needed, actually: C# 15 is the default language version for `net11.0`, and a single `.cs` file runs with `dotnet run file.cs` 🤓.

## The basics

```csharp
public record Cat(string Name);
public record Dog(string Name, int Age);

public union Pet(Cat, Dog);
```

That's it. A `Pet` is either a `Cat` or a `Dog`, and you get an implicit conversion from each:

```csharp
static string Describe(Pet pet) => pet switch
{
    Cat c => $"{c.Name} the cat",
    Dog d => $"{d.Name} the dog, age {d.Age}",
};

Pet pet = new Dog("Fido", 3);
Describe(pet);
```

```
Fido the dog, age 3
```

Note the missing `_ =>` arm. Before C# 15, a switch like this over an interface or abstract base class would give you a warning unless you added a discard at the end, because the compiler had no way of knowing nobody would add a `Hamster` somewhere. With a union it knows the full list (in other words it is _exhaustive_), so it can tell you when you've missed one.

## Forgetting a case

Let's add a pigeon (there's always a pigeon, right?):

```csharp
public record Pigeon(string Name);

public union Pet(Cat, Dog, Pigeon);
```

And leave `Describe` as it was:

```
warning CS8509: The switch expression does not handle all possible values of its input type (it is not exhaustive). For example, the pattern 'Pigeon' is not covered.
```

A _warning_, that is. Soooo close, I mean, "impossible states made impossible" was literally _right there_! The program still builds and runs, and if a `Pigeon` ever reaches `Describe` it throws at runtime.

To be fair, F# does exactly the same thing:

```fsharp
type Pet =
    | Cat of name: string
    | Dog of name: string * age: int
    | Pigeon of name: string

let describe pet =
    match pet with
    | Cat name -> $"{name} the cat"
    | Dog (name, age) -> $"{name} the dog, age {age}"
```

```
warning FS0025: Incomplete pattern matches on this expression. For example, the value 'Pigeon (_)' may indicate a case not covered by the pattern(s).
```

Elm is the only one of the three that refuses outright:

```
-- MISSING PATTERNS ----------------------------------------------- src/Main.elm

This `case` does not have branches for all possibilities:
...
Missing possibilities include:

    Pigeon _

I would have to crash if I saw one of those. Add branches for them!
```

"I would have to crash if I saw one of those." Gotta love that one. And that's kind of the whole point: The compiler _knows_ the program can crash, and in C# and F# it says so politely and lets you ship it anyway. I'm getting sidetracked here, sorry.

**So the first thing I'd do in any C# 15 codebase is turn that warning into an error.** In a `.csproj` that's `<WarningsAsErrors>CS8509</WarningsAsErrors>`; in a file-based app it's one line at the top:

```csharp
#:property WarningsAsErrors=CS8509
```

```
error CS8509: The switch expression does not handle all possible values of its input type (it is not exhaustive). For example, the pattern 'Pigeon' is not covered.

The build failed. Fix the build errors and run again.
```

Much better. (I'd do the same for FS0025 in F#, for the record.)

## Switch statements don't count

Careful now: Exhaustiveness checking applies to switch _expressions_. The good old switch _statement_ doesn't get it:

```csharp
Pet pet = new Pigeon("Kevin");

switch (pet)
{
    case Cat c:
        Console.WriteLine($"feed {c.Name} some fish");
        break;
    case Dog d:
        Console.WriteLine($"walk {d.Name}");
        break;
}

Console.WriteLine("done");
```

```
done
```

I suppose one could argue that it's consistent with how switch statements have always worked in C# (ie they're allowed to do nothing), but it means the safety net only exists if you write your code a certain way. If I were adopting unions in an existing codebase, I'd want an analyzer that nudges every `switch (someUnion)` towards a switch expression. The closest built-in rule I found, IDE0010 ("Populate switch"), doesn't help here: it fires on every switch statement, even one that covers all the union cases, because it wants a `default:` branch (which would defeat the purpose). Not too impressed here, to be perfectly honest.

## Unions of types, not tags

This is the biggest conceptual difference from F# and Elm: In F#, the cases of a DU are _tags_: `Email of string` and `Phone of string` are two different cases even though both carry a string. A C# union is a union of _types_. The [spec](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/proposals/csharp-15.0/unions) is upfront about this, and the compiler is too:

```csharp
public union ContactInfo(string, string);
```

```
error CS0111: Type 'ContactInfo' already defines a member called 'ContactInfo' with the same parameter types
```

You can't declare cases inline either, so every case has to be a type that exists somewhere. In practice that means a record per case, which is a little more ceremony than F#'s `| Email of string`. I'll admit it pushes you towards something I'd recommend anyway: wrapping primitives in proper domain types (an `EmailAddress` record rather than a raw `string`). Scott Wlaschin would approve, I think.

The same thing hits generics in a sneakier and more subtle way way. Here's your vanilla `Result`:

```csharp
public union Result<T, E>(T, E);

Result<int, string> ok = 42;                          // fine
Result<string, string> uhOh = "is this an error?";
```

```
error CS0457: Ambiguous user defined conversions 'Result<string, string>.Result(string)' and 'Result<string, string>.Result(string)' when converting from 'string' to 'Result<string, string>'
```

The declaration compiles just fine. It's only when `T` and `E` happen to be the same type that it falls apart, and the error shows up wherever you use it, not where you declared it. The fix is to wrap the cases (`Ok<T>` and `Err<E>` records), which brings us to the next point.

## Bring your own Result

There's no `Result`, `Option`, `Bind` or `Map` in the base library. Unions give you the general _shape_, and you write the rest. Here's roughly the smallest version I could make work, using C# 14 extension blocks:

```csharp
public record Ok<T>(T Value);
public record Err<E>(E Error);
public union Result<T, E>(Ok<T>, Err<E>);

public static class ResultExtensions
{
    extension<T, E>(Result<T, E> r)
    {
        public Result<U, E> Bind<U>(Func<T, Result<U, E>> f) => r switch
        {
            Ok<T> ok => f(ok.Value),
            Err<E> err => err,
        };

        public Result<U, E> Map<U>(Func<T, U> f) => r switch
        {
            Ok<T> ok => new Ok<U>(f(ok.Value)),
            Err<E> err => err,
        };
    }
}
```

With that in place, a small order flow (with its own error union) reads surprisingly close to the F# version:

```csharp
public record InvalidEmail(string Input);
public record OutOfStock(string Sku);
public record PaymentDeclined(string Reason);
public union OrderError(InvalidEmail, OutOfStock, PaymentDeclined);

static Result<Receipt, OrderError> PlaceOrder(string email, string sku, int qty) =>
    ParseEmail(email)
        .Map(e => new Order(e, sku, qty))
        .Bind(CheckStock)
        .Bind(Charge);
```

And matching on the result, nested patterns included:

```csharp
static string Show(Result<Receipt, OrderError> r) => r switch
{
    Ok<Receipt> ok => $"OK: charged {ok.Value.Charged}",
    Err<OrderError> { Error: InvalidEmail e } => $"bad email '{e.Input}'",
    Err<OrderError> { Error: OutOfStock o } => $"out of stock: {o.Sku}",
    Err<OrderError> { Error: PaymentDeclined p } => $"declined: {p.Reason}",
};
```

```
OK: charged 198
bad email 'not-an-email'
out of stock: DMMF-BOOK
declined: card expired
```

Leave out one of the `Err` arms and you get CS8509 again, so the checking goes all the way down. That's [railway-oriented programming](https://fsharpforfunandprofit.com/rop/), for you, Scott Wlaschin style.In C#! With the compiler watching your back. I like it a lot.

My guess, though, is that every C# codebase will end up with its own slightly different `Result<T, E>` for a while. (Kotlin went through the same thing with `Result` vs Arrow's `Either`, and [rich errors](/posts/kotlin-rich-errors-elm-union-types/) are partly an attempt to end that.)

## The value that isn't any of them

Now watch this:

A `union` compiles to a `struct`. And every struct in C# has a `default`:

```csharp
Pet pet = default;
Console.WriteLine(pet.Value is null);  // True

var pets = new Pet[3];
Console.WriteLine(pets[0].Value is null);  // True
```

So there's a `Pet` that's neither a `Cat` nor a `Dog`. And the `Describe` from earlier, which the compiler considers exhaustive (no warning at all), does this with it:

```
Unhandled exception. System.Runtime.CompilerServices.SwitchExpressionException: Non-exhaustive switch expression failed to match its input.
Unmatched value was Pet.
```

Same exception text as a forgotten `Pigeon`, by the way, so good luck telling the two apart in a log.

You don't even need to write `default` yourself. An uninitialized field or a fresh array will hand you an empty `Pet` just the same. In Elm this state (obviously!!) simply doesn't exist. F# isn't completely immune (a DU is a class, so `Unchecked.defaultof` or `Array.zeroCreate` will give you a null one), but you have to go a bit out of your way, to say the least.

To its credit, the [documentation](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/union#union-exhaustiveness) says this out loud ("A default union contains null"), and recommends a `null` arm whenever default contents can reach your switch:

```csharp
static string Describe(Pet pet) => pet switch
{
    Cat c => $"{c.Name} the cat",
    Dog d => $"{d.Name} the dog",
    null => "no pet",
};
```

Note that it says `null`, not `_`. A discard arm would also swallow that `Pigeon`, and then the compiler can't warn you about it anymore. A `null` arm only catches the empty case.

It's a reasonable trade-off given 25 years of C# and struct semantics. But it does mean C# unions make _some_ impossible states impossible, and this particular one very possible.

## Closed hierarchies

The other half of the feature is `closed`, which is closer to Kotlin's `sealed`:

```csharp
public closed record Shape;
public record Circle(double Radius) : Shape;
public record Square(double Side) : Shape;
public record Triangle(double Base, double Height) : Shape;

static double Area(Shape shape) => shape switch
{
    Circle c => Math.PI * c.Radius * c.Radius,
    Square s => s.Side * s.Side,
};
```

```
warning CS8509: The switch expression does not handle all possible values of its input type (it is not exhaustive). For example, the pattern 'Triangle' is not covered.
```

A `closed` class can only be derived from inside its own assembly, and it's implicitly abstract (`new Shape()` gives you CS0144). That makes it a nice fit for the "abstract base class plus a handful of records" pattern a lot of C# code already uses, and since it's a class, there's no struct `default` to worry about. (Plain old `null`, on the other hand, is still around.)

One detail from the [docs](https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-15#closed-hierarchies): it isn't transitive. A non-closed subclass of a closed class can be extended from other assemblies, so if you have a deeper hierarchy you'll want `closed` on the intermediate levels too.

(Head spin: check!)

## Boxing (yes, really)

The generated union stores whatever you put in it as a single `object?`. Reflecting over a `union IntOrString(int, string)`:

```
System.Object <Value>k__BackingField
System.Runtime.CompilerServices.IUnion
```

So an `int` case gets boxed. For records (which are reference types anyway) this doesn't matter, but if you were hoping for a zero-allocation `int | string`, the generated version sadly isn't it. The docs describe a `[Union]` attribute pattern for hand-written unions with their own storage and a non-boxing `TryGetValue` access pattern. I'd expect library authors to use that, and the rest of us to never think about it.

## And JSON?

Given [my last post](/posts/go-json-v2-finally-says-no/), I had to check:

```csharp
Pet pet = new Dog("Fido", 3);
var json = JsonSerializer.Serialize(pet);
// {"Name":"Fido","Age":3}

JsonSerializer.Deserialize<Pet>(json);
```

```
System.Text.Json.JsonException: JSON value type 'Object' is ambiguous for union type 'Pet' because multiple case types can use this value type. Specify a custom type classifier to support deserialization. Path: $ | LineNumber: 0 | BytePositionInLine: 1.
```

It serializes the case value with no tag, and then can't read it back, because an object is an object. Which is the right call! Guessing would be worse. But it does mean that if you want unions on the wire, you'll be making that decision explicitly, one way or another. (Also, if you're trying this in a file-based app: reflection-based JSON is off by default there, so you need `#:property JsonSerializerIsReflectionEnabledByDefault=true` at the top, or you get an `InvalidOperationException` before you get anywhere near the union.)

## Talking to F

Since unions are now in both languages, I tried consuming an F# DU from C#. It works, and C# 15 pattern matching on the generated case classes reads nicely. But C# doesn't treat the F# DU as closed:

```
warning CS8509: ... For example, the pattern '_' is not covered.
```

F# DUs don't implement the new `IUnion` interface, so to C# they're just a class hierarchy. Going the other way, F# sees a C# union as a struct with an `object` `Value` and has no idea it's closed either. And `closed` is only enforced by the C# compiler: an F# project can happily inherit from a closed C# record in another assembly, which C# itself would reject. So if you have a mixed solution, I'd keep the domain types (and the matching on them) on one side of the boundary.

## So is it any good?

Yes! More than I expected, actually. Coming from Elm, what I care about most is a closed set of cases and a compiler that tells me when I've missed one, and C# 15 has both (nested patterns included). Make CS8509 an error and add a `null` arm, and you get pretty close to [making impossible states impossible](/posts/making-impossible-states-impossible-with-functional-dependency-injection/).

It's not F#. Cases are types rather than tags, there's no `Result` in the box, and the struct `default` is a hole you have to remember to plug. And it's very much not Elm, where none of those caveats exist and the compiler just says no. But C# was never going to be either of those, and given where it's coming from, this is a big step in the right direction.

I still think F# is the nicer place to write a domain model. But if I do end up in a C# codebase, I know which warning I'm turning into an error first :D
