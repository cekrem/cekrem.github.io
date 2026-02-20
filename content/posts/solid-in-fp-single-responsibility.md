+++
title = "SOLID in FP: Single Responsibility, or How Pure Functions (Almost) Solved It Already"
description = "Revisiting SRP through a functional programming lens – turns out constraints are liberating, but not quite enough"
tags = ["elm", "functional-programming", "SOLID", "architecture"]
date = 2026-02-17
draft = false
+++

About a year ago I wrote a [whole series on SOLID](/posts/single-responsibility-principle-in-react/). It was fun. Some people on Reddit were less than thrilled. But I learned a lot, and it sent me down a rabbit hole of software architecture that I'm still happily stuck in.

Since then I've spent _way_ more time in Elm. And looking back at those React (++; some where Kotlin and Go as well) examples with FP-tinted glasses, I keep having the same reaction: **most of these problems just don't exist in functional programming.**

Not because FP developers are smarter, but because the _language_ won't let you make certain mistakes in the first place. SRP is the principle where this is most obvious — though the full picture is a bit more nuanced than "pure functions fix everything."

## Quick refresher

Uncle Bob's Single Responsibility Principle says a module should have only _one reason to change_. And it's worth stressing what "reason to change" actually means here, because this is where SRP gets misunderstood (even [my earlier React post](/posts/single-responsibility-principle-in-react/) could perhaps have been even clearer on the matter!). Uncle Bob has [clarified this](https://blog.cleancoder.com/uncle-bob/2014/05/08/SingleReponsibilityPrinciple.html) repeatedly: it's about _who requests the change_. A module should be responsible to one actor or stakeholder. His classic example: an `Employee` class with `calculatePay` (CFO's domain), `reportHours` (COO's domain), and `save` (CTO's domain) violates SRP not because it does three things, but because three different groups of people might request changes to it, and those changes risk breaking each other.

With that in mind, let's look at the classic monolith component from my [React SRP post](/posts/single-responsibility-principle-in-react/) — the one that fetches data, manages loading states, handles form submissions, and renders UI, all in one place:

```tsx
// The classic anti-pattern from the original post
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

  // ... plus form handling, rendering, the whole kitchen sink
};
```

The fix in React was to split this into hooks, container components, and presentation components. Discipline and patterns to achieve what _should_ be natural separation.

## This can't happen in Elm

I mean that literally. You _cannot_ write the above in Elm. Not because of some linting rule or team convention, but because the language won't let you.

Side effects (like HTTP requests) aren't something your view function _does_. They're values your update function _returns_. The view is a pure function from model to HTML. It can't fetch data. It can't mutate state. All it can do is describe what the UI looks like for a given state.

Here's the same user profile in Elm:

```elm
type alias Model =
    { user : RemoteData Http.Error User
    }


type Msg
    = GotUser (Result Http.Error User)


init : ( Model, Cmd Msg )
init =
    ( { user = Loading }
    , fetchUser
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotUser result ->
            ( { model | user = RemoteData.fromResult result }
            , Cmd.none
            )


view : Model -> Html Msg
view model =
    case model.user of
        NotAsked ->
            text ""

        Loading ->
            text "Loading..."

        Failure err ->
            text "Something went wrong"

        Success user ->
            div []
                [ h1 [] [ text user.name ]
                , p [] [ text user.email ]
                ]


fetchUser : Cmd Msg
fetchUser =
    Http.get
        { url = "/api/user"
        , expect = Http.expectJson GotUser userDecoder
        }
```

Those five concerns from the React anti-pattern? They got separated by the architecture itself. Data fetching is a `Cmd` value. Loading states are modeled in the `RemoteData` type (which I [wrote about before](/posts/functors-applicatives-monads-elm/) in a different context). State transitions and presentation are in different functions by definition. I didn't have to _choose_ to separate these. TEA made that decision for me.

Now, to be fair: this is really _separation of concerns_, which is related to but not identical with SRP. You could have beautifully separated concerns and still violate SRP if your neatly organized module serves both the marketing team's landing page needs _and_ the support team's dashboard needs. But Elm keeping your concerns separated by default is a long way towards SRP — when your code is already untangled, organizing it around actors becomes a much smaller step.

## Pure functions and SRP

A pure function takes input and returns output. That's it. It can't secretly fire off a database call or send an email. Which means it tends to have a pretty narrow scope by nature.

Compare:

```typescript
// TypeScript: this function has hidden responsibilities
async function processOrder(order: Order) {
  const validated = validateOrder(order);
  await saveToDatabase(validated);
  await sendConfirmationEmail(validated);
  logger.info(`Order ${order.id} processed`);
}
```

```elm
-- Elm: each function does one thing
validateOrder : UnvalidatedOrder -> Result (List ValidationError) ValidOrder
validateOrder order =
    -- just validates, returns a Result


processOrder : ValidOrder -> List (Cmd Msg)
processOrder order =
    [ saveOrder order
    , sendConfirmation order
    ]
```

The TypeScript version does four different things with side effects tangled together. The Elm version? `validateOrder` validates. `processOrder` describes what effects should happen. Neither function _does_ the side effects; they're descriptions that the runtime handles.

When your functions can't _do_ things, only _describe_ things, separation of concerns takes care of itself. And while that's not _quite_ the same as SRP in the Uncle Bob sense, it makes it much harder to accidentally couple things that serve different actors. If `validateOrder` changes because the product team wants different business rules, that change can't ripple into `processOrder` where the backend team's persistence logic lives. The boundaries are explicit in the types.

## "But what about big update functions?"

You can write a 500-line `update` function in Elm. I have. It's fine.

A long `update` function is still a pure function — no hidden side effects, no tangled concerns. That's already better than a monolith React component. But can it violate SRP? Sure. If your page's form validation serves the product owner, the navigation behavior serves the UX team, and the search filtering serves the data team, then a single `update` handling all of that _is_ responsible to multiple actors. Being pure doesn't change that.

This is where Elm gives you a really nice tool for _actually_ achieving SRP, not just accidentally approximating it: extensible record types.

Say you've got a page with a form, a sidebar, search results, and user preferences. Instead of passing the full `Model` to every helper, you constrain each one to just the fields it needs using extensible record types:

```elm
clearFormInput : { a | formInput : String } -> { a | formInput : String }

toggleSidebar : { a | sidebarOpen : Bool } -> { a | sidebarOpen : Bool }

applySearchFilter : String -> { a | results : List Item, activeFilter : String } -> { a | results : List Item, activeFilter : String }

resetFeedback : { a | rating : Maybe Int, comment : String } -> { a | rating : Maybe Int, comment : String }
```

Each of these accepts your full `Model` (because `Model` has all those fields), but can only read and modify the fields in its signature. `clearFormInput` can't accidentally mess with your sidebar state. `toggleSidebar` can't touch the search results. The compiler enforces this.

I love this. One glance at the type signature and you know which fields a function can touch. And this _does_ connect to the real SRP: if the product team changes form behavior, that change is isolated from the sidebar (maybe the UX team's domain) and the search results (maybe the data team cares about those). The type system draws boundaries for you, and those boundaries tend to line up with who-changes-what.

Is any of this _required_? No. A big case expression in a single update function works perfectly well, and it's what the Elm guide recommends you start with. But when things grow, partial records are a great way to keep things tidy without introducing the kind of indirection that makes code harder to follow. Richard Feldman's ["Scaling Elm Apps"](https://www.youtube.com/watch?v=DoA4Txr4GUs) talk covers this pattern and other scaling strategies really well.

## Constraints that free you

I keep coming back to this: constraints are liberating. (I know, I know, it sounds like a motivational poster. Bear with me.)

In React, your component can do anything. Fetch data, manage state, trigger side effects, render UI, all in the same function body. You need discipline and team conventions to keep things separated, and in my experience those conventions are the first thing to go when deadlines hit.

Elm doesn't give you that option. The view can't perform side effects. State changes go through `update`. Effects are return values. You _can't_ tangle things together even if you're in a hurry at 11pm trying to ship something before the sprint ends. (Not that I would know anything about that.)

Does FP "solve" SRP? Not entirely. SRP in the Uncle Bob sense is about people and organizational structure, and no type system can automate that for you. But pure functions and explicit type signatures make coupling _visible_. When you can see the coupling, it's a lot easier to organize around your actors. You still need to _think_ about who those actors are — the language just makes it harder to ignore when you haven't.

There's a lot more to SRP than I've covered here — I've really just given a few pointers on how FP rigs you for thinking in SRP terms. If this piqued your interest, go read Uncle Bob's [actual clarification](https://blog.cleancoder.com/uncle-bob/2014/05/08/SingleReponsibilityPrinciple.html). It's short, it's clear, and it might change how you think about the principle the same way it did for me.

## What's next

This is the first post in what I'm calling "SOLID in FP," revisiting each principle through a functional lens. Some principles (like SRP) turn out to be more nuanced than I expected. Others (like [Liskov Substitution](/posts/liskov-substitution-the-real-meaning-of-inheritance/), which was all about inheritance, a thing Elm doesn't even _have_) get really interesting when you reframe them.

I have no idea if I'll manage to make all five compelling. But I just might.

Up next: [the Open-Closed Principle](/posts/solid-in-fp-open-closed/), where union types and pattern matching change the game completely compared to the composition-and-props approach we used in React.
