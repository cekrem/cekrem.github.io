module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes as Attributes
import Html.Events exposing (..)
import Testemonials



-- MAIN


main : Program String Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type Model
    = Testemonials Testemonials.Model
    | None


init : String -> ( Model, Cmd Msg )
init path =
    if Testemonials.showForPath path then
        Testemonials.init ()
            |> Tuple.mapBoth Testemonials (Cmd.map TestemonialsMsg)

    else
        ( None
        , Cmd.none
        )



-- UPDATE


type Msg
    = NoOp
    | TestemonialsMsg Testemonials.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( model, msg ) of
        ( Testemonials testemonialsModel, TestemonialsMsg testemonialsMsg ) ->
            Testemonials.update testemonialsMsg testemonialsModel
                |> Tuple.mapBoth Testemonials (Cmd.map TestemonialsMsg)

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [ Attributes.class "container" ]
        [ case model of
            Testemonials testemonialsModel ->
                Testemonials.view testemonialsModel
                    |> Html.map TestemonialsMsg

            None ->
                Html.text ""
        ]
