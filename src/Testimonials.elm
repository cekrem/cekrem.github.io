module Testimonials exposing (Model, Msg, bookEntry, init, showForPath, update, view)

import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import HtmlHelpers exposing (hideOnBreakpoint)
import Http
import Json.Decode
import Random
import Random.List exposing (shuffle)
import Set


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
        , "/hire"
        , "/posts/starting-small-with-elm-a-widget-approach"
        ]


showForPath : String -> Bool
showForPath path =
    let
        normalizedPath =
            if String.endsWith path "/" then
                String.dropRight 1 path

            else
                path
    in
    activePaths |> Set.member normalizedPath


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
    | GotShuffledTetsemonials (List Testimonial)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( model, msg ) of
        ( Success testimonials index, Right ) ->
            ( Success testimonials (modBy (List.length testimonials - 2) index + 1), Cmd.none )

        ( Success testimonials index, Left ) ->
            ( Success testimonials (modBy (List.length testimonials - 2) index - 1), Cmd.none )

        ( Loading, GotShuffledTetsemonials testimonials ) ->
            ( Success testimonials 0, Cmd.none )

        ( _, GotTestimonials (Ok testimonials) ) ->
            ( Loading, Random.generate GotShuffledTetsemonials (shuffle testimonials) )

        ( _, GotTestimonials (Err _) ) ->
            ( Failure, Cmd.none )

        _ ->
            ( model, Cmd.none )



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

                -- , Attributes.style "max-width" "80rem"
                , Attributes.style "min-height" "60rem"
                , Attributes.style "margin" "auto"
                , Attributes.style "padding" "2rem 3rem"
                , Attributes.style "display" "flex"
                , Attributes.style "align-items" "center"
                , Attributes.style "justify-content" "center"
                ]
                (HtmlHelpers.when (index > 0) leftButton
                    :: rightButton
                    :: (testimonials
                            |> List.indexedMap
                                (\i t ->
                                    testimonialEntry (i == index + 1 || i == index) t
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


carouselStyles : Bool -> List (Html.Attribute msg)
carouselStyles visible =
    -- Most of this could and should have been ish a one-liner of tailwind, but tailwind breaks the mother app
    [ Attributes.style "transition-property" "all"
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
    , Attributes.style "font-size" "1.7rem"
    , Attributes.style "interpolate-size" "allow-keywords"
    ]
        ++ (if visible then
                [ Attributes.style "width" "60rem"
                , Attributes.style "height" "min-content"
                , Attributes.style "padding" "2rem"
                , Attributes.style "margin" "0.5rem"
                , Attributes.style "flex" "1"
                ]

            else
                [ Attributes.style "width" "0"
                , Attributes.style "height" "0"
                , Attributes.style "overflow-y" "hidden"
                , Attributes.style "padding" "0"
                , Attributes.style "opacity" "0"
                , Attributes.style "font-size" "0"
                , Attributes.style "margin" "0rem"
                , Attributes.style "flex" "0"
                ]
           )


testimonialEntry : Bool -> Testimonial -> Html Msg
testimonialEntry visible testimonial =
    Html.div
        (carouselStyles visible)
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


bookEntry : Bool -> Html msg
bookEntry visible =
    Html.a
        (Attributes.href "https://leanpub.com/elm-for-react-devs"
            :: Attributes.style "text-align" "center"
            :: carouselStyles visible
        )
        [ title "Early access:"
        , Html.img
            [ Attributes.src "/images/book.png"
            , Attributes.width 200
            , Attributes.style "margin" "auto"
            ]
            []
        , Html.span
            []
            [ Html.hr [] []
            , title "eBook available now!"
            ]
        ]



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
