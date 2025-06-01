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
            ( Success testemonials (modBy (List.length testemonials) (index + 1)), Cmd.none )

        ( Success testemonials index, Left ) ->
            ( Success testemonials (modBy (List.length testemonials) (index - 1)), Cmd.none )

        ( _, GotTestemonials (Ok testemonials) ) ->
            ( Success testemonials 0, Cmd.none )

        ( _, GotTestemonials (Err _) ) ->
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
                [ Html.text "something went wrong while fetching testemonials :("
                ]

        Success testemonials index ->
            Html.div
                [ Attributes.style "position" "relative"
                , Attributes.style "width" "100%"
                , Attributes.style "padding" "2rem 3rem"
                , Attributes.style "margin" "1rem"
                , Attributes.style "border-radius" "1rem"
                , Attributes.style "background" "white"
                , Attributes.style "display" "flex"
                , Attributes.style "align-items" "start"
                , Attributes.style "justify-content" "center"
                , Attributes.style "flex-wrap" "wrap"
                ]
                ((if index > 0 then
                    leftButton

                  else
                    Html.text ""
                 )
                    :: (if index < List.length testemonials - 2 then
                            rightButton

                        else
                            Html.text ""
                       )
                    :: (testemonials
                            |> List.indexedMap
                                (\i t ->
                                    testemonialEntry (i == index || i == index + 1) t
                                )
                       )
                )


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
        , Attributes.style "align-self" "start"
        , Attributes.style side "0"
        , Attributes.style "margin" "20rem 1rem"
        , Attributes.style "font-size" "5rem"
        , Attributes.style "cursor" "pointer"
        , Attributes.style "user-select" "none"
        , Events.onClick msg
        ]
        [ Html.text content ]


testemonialEntry : Bool -> Testemonial -> Html Msg
testemonialEntry visible testemonial =
    let
        ( width, height, padding ) =
            if visible then
                ( "40rem", "50rem", "2rem" )

            else
                ( "0%", "0", "0" )
    in
    Html.div
        [ Attributes.style "transition" "all .5s ease"
        , Attributes.style "padding" padding
        , Attributes.style "width" width
        , Attributes.style "max-height" height
        , Attributes.style "overflow-x" "hidden"
        , Attributes.style "display" "flex"
        , Attributes.style "white-space" "nowrap"
        , Attributes.style "flex-direction" "column"
        , Attributes.style "gap" "1rem"
        ]
        [ flexRow
            [ Html.img
                [ Attributes.src testemonial.image
                , Attributes.style "width" "75px"
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
        , Attributes.style "flex-wrap" "wrap"
        , Attributes.style "align-items" "center"
        , Attributes.style "gap" "1rem"
        ]
        content


title : String -> Html msg
title text =
    Html.h6 [ Attributes.style "margin" "0" ] [ Html.text text ]


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
        , Attributes.style "font-size" "1.6rem"
        , Attributes.style "line-height" "1.4"
        ]
        [ Html.text text ]


subtitle : String -> Html msg
subtitle text =
    Html.p
        [ Attributes.style "margin" "0"
        , Attributes.style "font-size" "1.6rem"
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
