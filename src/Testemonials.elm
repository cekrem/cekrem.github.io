module Testemonials exposing (Model, Msg, init, showForPath, update, view)

import Html exposing (..)
import Html.Attributes as Attributes
import Html.Events as Events
import Http
import Json.Decode
import Set



-- MODEL


type Model
    = Failure
    | Loading
    | Success (List Testemonial)


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
    = NoOp
    | GotTestemonials (Result Http.Error (List Testemonial))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GotTestemonials (Ok testemonilals) ->
            ( Success testemonilals, Cmd.none )

        GotTestemonials (Err error) ->
            ( Failure, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    case model of
        Loading ->
            Html.text "..."

        Failure ->
            Html.div [ Events.onClick NoOp ]
                [ Html.text "something went wrong while fetching testemonials"
                ]

        Success testemonials ->
            Html.div
                [ Attributes.style "padding" "2rem 3rem"
                , Attributes.style "border-radius" "1rem"
                , Attributes.style "background" "white"
                , Attributes.style "display" "flex"
                , Attributes.style "gap" "1rem"
                ]
                (testemonials
                    |> List.take 2
                    |> List.map testemonialEntry
                )


testemonialEntry : Testemonial -> Html Msg
testemonialEntry testemonial =
    Html.div
        [ Attributes.style "border" "thin solid black"
        , Attributes.style "padding" "2rem"
        , Attributes.style "width" "50%"
        , Attributes.style "display" "flex"
        , Attributes.style "flex-direction" "column"
        , Attributes.style "gap" "1rem"
        ]
        [ flexRow
            [ Html.img
                [ Attributes.src testemonial.image
                , Attributes.style "width" "50px"
                , Attributes.style "border-radius" "50%"
                ]
                []
            , Html.div []
                [ clickableTitle testemonial.link testemonial.name
                , paragraph testemonial.title
                ]
            ]
        , flexRow
            [ Html.text "⭐⭐⭐⭐⭐"
            ]
        , flexRow
            [ paragraph testemonial.text ]
        , flexRow
            [ paragraph testemonial.date ]
        ]


flexRow : List (Html msg) -> Html msg
flexRow content =
    Html.div
        [ Attributes.style "display" "flex"
        , Attributes.style "align-items" "center"
        , Attributes.style "gap" "1rem"
        ]
        content


title : String -> Html msg
title text =
    Html.h6 [ Attributes.style "margin" "0" ] [ Html.text text ]


clickableTitle : String -> String -> Html msg
clickableTitle url text =
    Html.a [ Attributes.href url ] [ title text ]


paragraph : String -> Html msg
paragraph text =
    Html.p
        [ Attributes.style "margin" "0"
        , Attributes.style "font-size" "1.4rem"
        , Attributes.style "line-height" "1.4"
        ]
        [ Html.text text ]



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
