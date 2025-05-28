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
                [ Attributes.style "padding" "24px"
                , Attributes.style "border-radius" "24px"
                , Attributes.style "background" "white"
                ]
                [ Html.text "testemonials here"
                ]



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
        (Json.Decode.field "date" Json.Decode.string)
        (Json.Decode.field "image" Json.Decode.string)
        (Json.Decode.field "link" Json.Decode.string)
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "text" Json.Decode.string)
        (Json.Decode.field "title" Json.Decode.string)
