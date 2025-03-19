+++
title = "Building Better UI Components: Elm Ports with Web Components"
description = "How to combine Elm's type safety with the reusability of Web Components"
tags = ["elm", "web components", "frontend", "functional programming", "architecture"]
date = "2025-03-19"
draft = false
+++

One of the most common questions I get about Elm is: "How do I integrate it with existing JavaScript ecosystems?" While Elm's isolation is a strength, real-world projects often require working with external libraries, APIs, or UI components. Doing incremental migration is also the recommended way to introduce Elm, and luckily there are may ways to accomplish this.

Today, I'll show you how to combine two powerful technologies:

1. **Elm Ports**: The official way to communicate between Elm and JavaScript
2. **Web Components**: Standard, framework-agnostic UI components

This combination gives us the best of both worlds: Elm's type safety and predictable architecture alongside the reusability and interoperability of Web Components. Let's dive in!

## What we're building

You know what? Let's embed it:

<iframe src="https://ellie-app.com/embed/tW9VkcFxnMCa1" style="width:100%; height:400px; border:0; overflow:hidden;" sandbox="allow-modals allow-forms allow-popups allow-scripts allow-same-origin"></iframe>

## What Are Elm Ports?

Ports are Elm's sanctioned escape hatch to JavaScript. Or put another way: They facilitate treating JavaScript as mere IO device. Specifically they allow your Elm application to:

1. Send data out to JavaScript (outgoing port)
2. Receive data from JavaScript (incoming port)

Think of ports as message channels between Elm's pure world and JavaScript's wild west.

## What Are Web Components?

Web Components are a set of standardized browser APIs that allow you to create reusable, encapsulated components using plain JavaScript, HTML, and CSS. The key technologies include:

- **Custom Elements**: Create your own HTML tags
- **Shadow DOM**: Encapsulated DOM and styles
- **HTML Templates**: Reusable markup structures

Once defined, Web Components work in any framework (or no framework) - making them ideal for sharing UI elements across different projects.

## Why Combine Them?

1. **Use specialized UI libraries** not available in Elm
2. **Share components** across projects using different frameworks
3. **Gradually migrate** existing applications to Elm
4. **Integrate third-party tools** (maps, charts, rich text editors)

## The Example Project: A Color Picker

Let's build a simple example: an Elm application that uses a Web Component color picker. We'll:

1. Create a simple Elm app that displays the selected color
2. Integrate a color-picker Web Component
3. Use ports to communicate between them

## Step 1: Setting Up the Elm Application

First, let's create our core Elm application:

```elm
port module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode

-- PORTS

port sendColor : String -> Cmd msg
port receiveColor : (String -> msg) -> Sub msg

-- MODEL

type alias Model =
    { currentColor : String
    }

init : () -> ( Model, Cmd Msg )
init _ =
    ( { currentColor = "#3366ff" }
    , sendColor "#3366ff"  -- Initialize the color picker with our default
    )

-- UPDATE

type Msg
    = ColorChanged String

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ColorChanged newColor ->
            ( { model | currentColor = newColor }
            , Cmd.none
            )

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions _ =
    receiveColor ColorChanged

-- VIEW

view : Model -> Html Msg
view model =
    div [ style "padding" "2rem", style "font-family" "system-ui, sans-serif" ]
        [ h1 [] [ text "Elm + Web Components" ]
        , div []
            [ p [] [ text "Selected color: ", strong [] [ text model.currentColor ] ]
            , div
                [ style "width" "100px"
                , style "height" "100px"
                , style "background-color" model.currentColor
                , style "margin" "1rem 0"
                , style "border-radius" "4px"
                ]
                []
            , div []
                [ -- Our Web Component will be placed here
                  node "color-picker"
                    [ attribute "current-color" model.currentColor
                    ]
                    []
                ]
            ]
        ]

-- MAIN

main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
```

In this Elm code, we've:

1. Defined two ports: `sendColor` to send the current color to JavaScript, and `receiveColor` to receive color changes
2. Used `node` to insert our custom element (which we'll create next)
3. Set up the appropriate model, update, and subscription functions

## Step 2: The JavaScript Glue

Next, we need to initialize Elm and wire up our ports:

```javascript
// index.js

// Init Elm app
const app = Elm.Main.init({ node: document.querySelector("main") });

// Define our color-picker Web Component
class ColorPicker extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: "open" });
    this._app = null; // Will store reference to Elm app
    this._boundHandler = this._handleColorChange.bind(this);
    this.render();
  }

  // Connect to DOM - add event listeners
  connectedCallback() {
    this._attachEventListeners();
  }

  // Clean up when removed from DOM
  disconnectedCallback() {
    this._detachEventListeners();
  }

  // Add event listeners to the input
  _attachEventListeners() {
    const input = this.shadowRoot.querySelector("input");
    if (input) {
      input.addEventListener("input", this._boundHandler);
    }
  }

  // Remove event listeners from the input
  _detachEventListeners() {
    const input = this.shadowRoot.querySelector("input");
    if (input) {
      input.removeEventListener("input", this._boundHandler);
    }
  }

  // Handle color changes from the input
  _handleColorChange(event) {
    const newColor = event.target.value;
    this.setAttribute("current-color", newColor);

    // Send the color back to Elm
    if (this._app && this._app.ports && this._app.ports.receiveColor) {
      this._app.ports.receiveColor.send(newColor);
    }
  }

  // Store reference to Elm app
  setApp(app) {
    this._app = app;
  }

  // Watch for attribute changes
  static get observedAttributes() {
    return ["current-color"];
  }

  // Handle attribute changes
  attributeChangedCallback(name, oldValue, newValue) {
    if (name === "current-color" && oldValue !== newValue) {
      // Update the input value directly if possible
      const input = this.shadowRoot.querySelector("input");
      if (input && input.value !== newValue) {
        input.value = newValue;
      } else {
        // Otherwise re-render
        this.render();
        this._attachEventListeners();
      }
    }
  }

  get currentColor() {
    return this.getAttribute("current-color") || "#000000";
  }

  render() {
    this.shadowRoot.innerHTML = `
      <style>
        :host {
          display: block;
          font-family: inherit;
        }
        .picker-container {
          display: flex;
          align-items: center;
          gap: 8px;
        }
        label {
          font-weight: bold;
        }
        input[type="color"] {
          width: 50px;
          height: 30px;
          border: none;
          border-radius: 4px;
        }
      </style>
      <div class="picker-container">
        <label for="color-input">Pick a color:</label>
        <input type="color" id="color-input" value="${this.currentColor}">
      </div>
    `;
  }
}

// Register the Web Component
customElements.define("color-picker", ColorPicker);

// Set up communication from Elm to the Web Component
app.ports.sendColor.subscribe((color) => {
  // Find our color picker element
  const picker = document.querySelector("color-picker");
  if (picker) {
    // Give the Web Component a reference to the Elm app
    if (!picker._app) {
      picker.setApp(app);
    }
    // Update the color
    picker.setAttribute("current-color", color);
  }
});
```

This update ensures that the JavaScript code in the blog post matches exactly with the code from `foo.html`.

## Step 3: HTML Setup

Finally, we need a simple HTML file to bring it all together:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Elm + Web Components</title>
    <script src="index.js"></script>
    <script src="elm.js"></script>
  </head>
  <body>
    <div id="elm-app"></div>
  </body>
</html>
```

## How It Works

The data flow in our application follows this pattern:

1. **Elm → JavaScript**:

   - Elm sends the current color through the `sendColor` port
   - JavaScript receives this value and updates the Web Component's attribute

2. **Web Component → JavaScript → Elm**:
   - User interacts with the color picker
   - Web Component fires an event
   - The event handler sends the new color to Elm via the `receiveColor` port
   - Elm updates its model with the new color

This clean separation maintains Elm's purity while leveraging the native capabilities of the web platform.

## Real-World Considerations

### 1. More Complex Data

For our simple example, we're just passing strings. For complex data, you'll need to encode/decode JSON:

```elm
-- In Elm
port sendComplexData : Encode.Value -> Cmd msg
port receiveComplexData : (Decode.Value -> msg) -> Sub msg

-- Using it
sendComplexData (Encode.object
    [ ("color", Encode.string model.color)
    , ("opacity", Encode.float model.opacity)
    , ("name", Encode.string model.name)
    ])
```

```javascript
// In JavaScript
app.ports.sendComplexData.subscribe((data) => {
  console.log(data.color, data.opacity, data.name);
});
```

### 2. Error Handling

When receiving data from JavaScript, always be prepared for unexpected values:

```elm
type Msg
    = GotColorData (Result Decode.Error ColorData)

subscriptions : Model -> Sub Msg
subscriptions _ =
    receiveComplexData (decodeColorData >> GotColorData)

decodeColorData : Decode.Value -> Result Decode.Error ColorData
decodeColorData value =
    Decode.decodeValue colorDataDecoder value
```

### 3. Multiple Components

With multiple Web Components, maintain a clear naming convention for your ports:

```elm
port sendColorPickerData : Encode.Value -> Cmd msg
port receiveColorPickerData : (Decode.Value -> msg) -> Sub msg

port sendMapData : Encode.Value -> Cmd msg
port receiveMapData : (Decode.Value -> msg) -> Sub msg
```

## How This Relates to Clean Architecture

This ports + Web Components pattern aligns perfectly with Clean Architecture principles:

1. **Separation of Concerns**:

   - Elm handles application logic
   - Web Components handle specialized UI rendering
   - Ports define clear boundaries between systems

2. **Dependency Rule**:

   - Core business logic in Elm doesn't depend on the Web Component details
   - The outer layer (JavaScript) depends on the inner layer (Elm), not vice versa

3. **Testability**:
   - Elm code can be tested without Web Components
   - Ports can be mocked for testing
   - Web Components can be tested in isolation

This approach gives us the best of both worlds:

- **Elm's strengths**: Type safety, immutability, and predictable state management
- **Web Components' strengths**: Standards-based, reusable UI components

## Conclusion

The combination of Elm ports and Web Components offers a powerful way to build robust applications while still leveraging the best tools from the broader web ecosystem. This approach maintains the benefits of Elm's architecture while embracing the interoperability of web standards.

By keeping your core application logic in Elm and using Web Components only for specialized UI needs, you get a clean, maintainable architecture with clear boundaries.

Have you used Elm ports or Web Components in your projects? I'd love to hear about your experiences, feel free to add feedback using my [new feedback tool, Feedback.one](/posts/feedback-one-elm-rust-feedback-widget/).

## Resources

- [Elm Guide: JavaScript Interop](https://guide.elm-lang.org/interop/)
- [MDN Web Components Documentation](https://developer.mozilla.org/en-US/docs/Web/Web_Components)
- [WebComponents.org](https://www.webcomponents.org/)

_Note: This blog post is intended for developers with basic knowledge of both Elm and Web Components. If you're new to Elm, check out the [official guide](https://guide.elm-lang.org/) first._
