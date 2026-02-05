---
title: "An Elm Primer: Declarative Dialogs with MutationObserver"
description: "How to control HTML's native dialog element from Elm without sacrificing declarative purity"
date: 2026-02-03
tags: [elm, javascript, interop, book]
---

Here's a small problem that says something bigger about Elm's architecture.

HTML's native `<dialog>` element is genuinely useful. You get proper focus trapping, the Escape key works automatically, backdrop handling is built in. But there's a catch: to open a dialog as a modal, you _have_ to call `dialog.showModal()`. There's no HTML attribute for "make this a modal." It's imperative all the way down.

So what happens when your entire view layer is a pure function of state?

## The Problem

In Elm, your view function produces HTML based on your model. If the dialog should be open, you render it open. If it should be closed, you render it closed. Simple.

```elm
viewDialog : Bool -> Html msg
viewDialog isOpen =
    Html.node "dialog"
        [ Attr.id "my-dialog" ]
        [ Html.text "Dialog content here" ]
```

But here's the thing: the `<dialog>` element doesn't care about your philosophical commitments. Setting `open` as an attribute works for non-modal dialogs, but if you want the modal behavior (backdrop, focus trap, Escape key), you need to call `showModal()`. And Elm views don't call methods. They return data structures.

You could use a port to tell JavaScript to open the dialog. But then you're managing state in two places: Elm knows the dialog _should_ be open, and JavaScript knows whether it _actually_ is. That's a bug waiting to happen.

![Kevin Malone with few words](/images/kevin-few-words.gif)

## The MutationObserver Bridge

Here's a pattern I've come to appreciate: let Elm do what it does best (declarative state), and use JavaScript to translate that into imperative API calls.

The trick is to make JavaScript _watch_ the DOM for changes Elm makes, then respond accordingly. A `MutationObserver` does exactly this.

First, the Elm side stays purely declarative. We just toggle a class:

```elm
view : Model -> Html Msg
view model =
    Html.node "dialog"
        [ Attr.id "wizard-dialog"
        , Attr.class <|
            if model.dialogOpen then
                "open"
            else
                "closed"
        ]
        [ viewDialogContent model ]
```

That's it. Elm's job is done. The view reflects the model.

Now the JavaScript side observes that class and handles the imperative stuff:

```javascript
const dialog = document.getElementById("wizard-dialog");

const dialogObserver = () => {
  if (!dialog) return;

  if (dialog.classList.contains("open") && !dialog.open) {
    dialog.showModal();
  } else if (dialog.classList.contains("closed") && dialog.open) {
    dialog.close();
  }
};

new MutationObserver(dialogObserver).observe(dialog, {
  attributes: true,
  attributeFilter: ["class"],
});
```

The observer watches for class changes. When it sees `open` but the dialog isn't actually showing, it calls `showModal()`. When it sees `closed` but the dialog is still open, it calls `close()`. The checks for `dialog.open` prevent redundant calls.

**Small but important note**: As a fellow Elm enthusiast pointed out, simply using the class name "open" might be a bit brittle in a large app (because of potential collisions). A data prop, or a more unique class name will be safer!

## Handling Escape

One more piece: the native dialog fires a `cancel` event when the user presses Escape. We want Elm to handle this, maybe showing a confirmation prompt before actually closing. Ports handle this nicely:

```elm
port dialogCancel : (() -> msg) -> Sub msg
```

And the JavaScript:

```javascript
dialog.addEventListener("cancel", (e) => {
  // Let Elm handle cancel!
  e.stopPropagation();
  e.preventDefault();

  app.ports.dialogCancel.send(null);
});
```

We prevent the default behavior (which would close the dialog immediately) and instead tell Elm "hey, the user tried to close this." Elm can then decide what to do: close immediately, show a confirmation, whatever makes sense for your application.

## Why This Works

I like this pattern because it keeps concerns cleanly separated:

- **Elm owns the state.** The model says whether the dialog should be open. Period.
- **Elm owns the view.** The view function produces HTML that reflects the model. No side effects.
- **JavaScript handles browser APIs.** The MutationObserver bridges the gap between declarative intent and imperative reality.

There's no state synchronization to worry about. Elm sets a class and JavaScript responds. The causality flows one direction.

This is a small example of a bigger idea: Elm's constraints push you toward architectures that are easier to reason about. You _can't_ just call `showModal()` from your view function, so you find a pattern that separates what something _is_ from how it _behaves_. And that separation turns out to be useful regardless of whether you're working in Elm.

---

This pattern appears in Chapter 12 of my book, [An Elm Primer for React Developers](https://leanpub.com/elm-for-react-devs), where we build a complete feedback wizard with modal dialogs, the OutMsg pattern for parent-child communication, and state-dependent subscriptions. The full code is available in the [example repository](https://github.com/cekrem/elm-primer-code-examples/tree/main/12_wizard-full-page).

If you're curious about Elm, or about functional programming more generally, the book is written specifically for React developers who want to learn without wading through academic theory. Check it out!
