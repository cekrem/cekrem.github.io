module Testemonials exposing (Model, Msg, init, showForPath, update, view)

import Html exposing (..)
import Html.Attributes as Attributes
import Html.Events as Events
import Http
import Json.Decode
import Set


{-| This view renders a testemonials carousel (only on wide screens, for now).

Also (again, for now) it relies only on inline styling, as the stylesheet of the mother app
this widget is rendered in is subject to complete replacement.

Testemonials are found in /static/testemonials.json (which hugo moves to root `/` on deploy).

-}



-- MODEL


type Model
    = Failure
    | Loading
    | Success (List Testemonial) Int


init : () -> ( Model, Cmd Msg )
init () =
    ( Loading, getTestemonials )


activePaths : Set.Set String
activePaths =
    Set.fromList [ "", "/", "/hire", "/hire/" ]


showForPath : String -> Bool
showForPath path =
    activePaths |> Set.member path


type alias Testemonial =
    { name : String
    , title : String
    , text : String
    , date : String
    , link : String
    , image : String
    }



-- UPDATE


type Msg
    = Right
    | Left
    | GotTestemonials (Result Http.Error (List Testemonial))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( model, msg ) of
        ( Success testemonials index, Right ) ->
            ( Success testemonials (changeOrRollover testemonials (index + 1)), Cmd.none )

        ( Success testemonials index, Left ) ->
            ( Success testemonials (changeOrRollover testemonials (index - 1)), Cmd.none )

        ( _, GotTestemonials (Ok testemonials) ) ->
            ( Success testemonials 0, Cmd.none )

        ( _, GotTestemonials (Err _) ) ->
            ( Failure, Cmd.none )

        _ ->
            ( model, Cmd.none )


{-| either set to targetIndex, or rollover if it's out of bounds.
Also: make sure never to set last index on odd numbered testemonials (ie always show two in slider!)
-}
changeOrRollover : List a -> Int -> Int
changeOrRollover list targetIndex =
    let
        threshold =
            List.length list
                |> (\length -> length - modBy 2 length)
    in
    modBy threshold targetIndex



-- VIEW


view : Model -> Html Msg
view model =
    case model of
        Loading ->
            Html.text "..."

        Failure ->
            Html.div []
                [ Html.text ""
                ]

        Success testemonials index ->
            Html.div
                [ Attributes.style "position" "relative"
                , Attributes.style "width" "100%"
                , Attributes.style "min-height" "60rem"
                , Attributes.style "padding" "2rem 3rem"
                , Attributes.style "display" "flex"
                , Attributes.style "align-items" "center"
                , Attributes.style "justify-content" "center"
                ]
                (leftButton
                    :: rightButton
                    :: (testemonials
                            |> List.indexedMap
                                (\i t ->
                                    testemonialEntry (i == index || i == index + 1) t
                                )
                       )
                )
                |> hideOnBreakpoint "600px"


{-| This hacky wrapper essentialy sets max-height and -width to 0px at a given breakpoint
-}
hideOnBreakpoint : String -> Html msg -> Html msg
hideOnBreakpoint breakpoint content =
    let
        clampStyle =
            "clamp(10px, calc((100vw - " ++ breakpoint ++ ") * 1000), 10000px)"
    in
    Html.div
        [ Attributes.style "max-width" clampStyle
        , Attributes.style "max-height" clampStyle
        , Attributes.style "overflow" "hidden"
        ]
        [ content ]


leftButton : Html Msg
leftButton =
    button True


rightButton : Html Msg
rightButton =
    button False


button : Bool -> Html Msg
button isLeft =
    let
        ( side, content, msg ) =
            if isLeft then
                ( "left", "◂", Left )

            else
                ( "right", "▸", Right )
    in
    Html.div
        [ Attributes.style "position" "absolute"
        , Attributes.style "align-self" "center"
        , Attributes.style side "0"
        , Attributes.style "font-size" "3em"
        , Attributes.style "cursor" "pointer"
        , Attributes.style "user-select" "none"
        , Events.onClick msg
        ]
        [ Html.text content ]


testemonialEntry : Bool -> Testemonial -> Html Msg
testemonialEntry visible testemonial =
    -- Most of this could and should have been ish a one-liner of tailwind, but tailwind breaks the mother app
    let
        conditionalStyles =
            if visible then
                [ Attributes.style "width" "50rem"
                , Attributes.style "max-height" "55rem"
                , Attributes.style "padding" "2rem"
                , Attributes.style "margin" "0.5rem"
                , Attributes.style "flex" "1"
                ]

            else
                [ Attributes.style "width" "0"
                , Attributes.style "max-height" "0"
                , Attributes.style "overflow-y" "hidden"
                , Attributes.style "padding" "0"
                , Attributes.style "opacity" "0"
                , Attributes.style "font-size" "0"
                , Attributes.style "margin" "0rem"
                , Attributes.style "flex" "0"
                ]
    in
    Html.div
        ([ Attributes.style "transition-property" "all"
         , Attributes.style "transition-timing-function" "ease-out"
         , Attributes.style "transition-duration" "0.4s"
         , Attributes.style "margin" "0.5rem"
         , Attributes.style "border-radius" "2rem"
         , Attributes.style "background" "rgba(255,255,255,0.8)"
         , Attributes.style "overflow-x" "hidden"
         , Attributes.style "display" "flex"
         , Attributes.style "white-space" "nowrap"
         , Attributes.style "flex-direction" "column"
         , Attributes.style "gap" "1rem"
         ]
            ++ conditionalStyles
        )
        [ flexRow
            [ Html.img
                [ Attributes.src testemonial.image
                , Attributes.style "width" "4em"
                , Attributes.style "border-radius" "50%"
                ]
                []
            , Html.div []
                [ clickableTitle testemonial.link testemonial.name
                , subtitle testemonial.title
                ]
            ]
        , flexRow
            [ stars ]
        , flexRow
            [ paragraph testemonial.text ]
        , flexRow
            [ subtitle testemonial.date ]
        ]


flexRow : List (Html msg) -> Html msg
flexRow content =
    Html.div
        [ Attributes.style "display" "flex"
        , Attributes.style "flex-wrap" "nowrap"
        , Attributes.style "align-items" "center"
        , Attributes.style "gap" "1rem"
        ]
        content


title : String -> Html msg
title text =
    Html.h6
        [ Attributes.style "margin" "0"
        ]
        [ Html.text text ]


stars : Html msg
stars =
    Html.span
        [ Attributes.style "color" "gold"
        ]
        [ Html.text "★ ★ ★ ★ ★"
        ]


clickableTitle : String -> String -> Html msg
clickableTitle url text =
    Html.a [ Attributes.href url ] [ title text ]


paragraph : String -> Html msg
paragraph text =
    Html.p
        [ Attributes.style "margin" "0"
        , Attributes.style "font-size" "1em"
        , Attributes.style "line-height" "1.4"
        ]
        [ Html.text text ]


subtitle : String -> Html msg
subtitle text =
    Html.p
        [ Attributes.style "margin" "0"
        , Attributes.style "font-size" "1em"
        , Attributes.style "line-height" "1.4"
        , Attributes.style "white-space" "pre"
        , Attributes.style "font-weight" "200"
        , Attributes.style "opacity" "0.8"
        ]
        [ Html.text (text |> String.replace "@ " "@\n") ]



-- CMD


getTestemonials : Cmd Msg
getTestemonials =
    Http.get
        { url = "/testemonials.json"
        , expect = Http.expectJson GotTestemonials testemonialsDecoder
        }


testemonialsDecoder : Json.Decode.Decoder (List Testemonial)
testemonialsDecoder =
    Json.Decode.list testemonialDecoder


testemonialDecoder : Json.Decode.Decoder Testemonial
testemonialDecoder =
    Json.Decode.map6 Testemonial
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "title" Json.Decode.string)
        (Json.Decode.field "text" Json.Decode.string)
        (Json.Decode.field "date" Json.Decode.string)
        (Json.Decode.field "link" Json.Decode.string)
        (Json.Decode.field "image" Json.Decode.string)
