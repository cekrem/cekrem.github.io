module Testimonials exposing (Model, Msg, init, showForPath, update, view)

import Html exposing (..)
import Html.Attributes as Attributes
import Html.Events as Events
import HtmlHelpers exposing (hideOnBreakpoint)
import Http
import Json.Decode
import Set
import Task
import Time


{-| This view renders a testimonials carousel (only on wide screens, for now).

Also (again, for now) it relies only on inline styling, as the stylesheet of the mother app
this widget is rendered in is subject to complete replacement.

Testimonials are found in /static/testimonials.json (which hugo moves to root `/` on deploy).

-}



-- MODEL


type Model
    = Failure
    | Loading
    | Success (List Testimonial) Int


init : () -> ( Model, Cmd Msg )
init () =
    ( Loading, getTestimonials )


activePaths : Set.Set String
activePaths =
    Set.fromList
        [ ""
        , "/"
        , "/hire"
        , "/hire/"
        , "/posts/starting-small-with-elm-a-widget-approach"
        , "/posts/starting-small-with-elm-a-widget-approach/"
        ]


showForPath : String -> Bool
showForPath path =
    activePaths |> Set.member path


type alias Testimonial =
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
    | GotTestimonials (Result Http.Error (List Testimonial))
    | SetRandomizedIndex Time.Posix


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( model, msg ) of
        ( Success testimonials index, Right ) ->
            ( Success testimonials (changeOrRollover testimonials (index + 1)), Cmd.none )

        ( Success testimonials index, Left ) ->
            ( Success testimonials (changeOrRollover testimonials (index - 1)), Cmd.none )

        ( Success testimonials _, SetRandomizedIndex time ) ->
            ( Success testimonials (changeOrRollover testimonials (time |> Time.posixToMillis)), Cmd.none )

        ( _, GotTestimonials (Ok testimonials) ) ->
            ( Success testimonials 0, Task.perform SetRandomizedIndex Time.now )

        ( _, GotTestimonials (Err _) ) ->
            ( Failure, Cmd.none )

        _ ->
            ( model, Cmd.none )


{-| either set to targetIndex, or rollover if it's out of bounds.
Also: make sure never to set last index on odd numbered testimonials (ie always show two in slider!)
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

        Success testimonials index ->
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
                    :: (testimonials
                            |> List.indexedMap
                                (\i t ->
                                    testimonialEntry (i == index || i == index + 1) t
                                )
                       )
                )
                |> hideOnBreakpoint "600px"


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


testimonialEntry : Bool -> Testimonial -> Html Msg
testimonialEntry visible testimonial =
    -- Most of this could and should have been ish a one-liner of tailwind, but tailwind breaks the mother app
    let
        conditionalStyles =
            if visible then
                [ Attributes.style "width" "60rem"
                , Attributes.style "max-height" "60rem"
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
         , Attributes.style "background" "rgba(127,127,127,0.05)"
         , Attributes.style "overflow-x" "hidden"
         , Attributes.style "display" "flex"
         , Attributes.style "white-space" "nowrap"
         , Attributes.style "flex-direction" "column"
         , Attributes.style "gap" "1rem"
         , Attributes.style "font-size" "1.8rem"
         ]
            ++ conditionalStyles
        )
        [ flexRow
            [ Html.img
                [ Attributes.src testimonial.image
                , Attributes.style "width" "4em"
                , Attributes.style "border-radius" "50%"
                ]
                []
            , Html.div []
                [ clickableTitle testimonial.link testimonial.name
                , subtitle testimonial.title
                ]
            ]
        , flexRow
            [ stars ]
        , flexRow
            [ paragraph testimonial.text ]
        , flexRow
            [ subtitle testimonial.date ]
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
        ]
        [ Html.text text ]


subtitle : String -> Html msg
subtitle text =
    Html.p
        [ Attributes.style "margin" "0"
        , Attributes.style "font-size" "1em"
        , Attributes.style "white-space" "pre"
        , Attributes.style "font-weight" "200"
        , Attributes.style "opacity" "0.8"
        ]
        [ Html.text (text |> String.replace "@ " "@\n") ]



-- CMD


getTestimonials : Cmd Msg
getTestimonials =
    Http.get
        { url = "/testimonials.json"
        , expect = Http.expectJson GotTestimonials testimonialsDecoder
        }


testimonialsDecoder : Json.Decode.Decoder (List Testimonial)
testimonialsDecoder =
    Json.Decode.list testimonialDecoder


testimonialDecoder : Json.Decode.Decoder Testimonial
testimonialDecoder =
    Json.Decode.map6 Testimonial
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "title" Json.Decode.string)
        (Json.Decode.field "text" Json.Decode.string)
        (Json.Decode.field "date" Json.Decode.string)
        (Json.Decode.field "link" Json.Decode.string)
        (Json.Decode.field "image" Json.Decode.string)
