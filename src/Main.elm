module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes as Attributes
import Html.Events exposing (..)
import Testimonials



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
    = Testimonials Testimonials.Model
    | None


init : String -> ( Model, Cmd Msg )
init path =
    if Testimonials.showForPath path then
        Testimonials.init ()
            |> Tuple.mapBoth Testimonials (Cmd.map TestimonialsMsg)

    else
        ( None
        , Cmd.none
        )



-- UPDATE


type Msg
    = NoOp
    | TestimonialsMsg Testimonials.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( model, msg ) of
        ( Testimonials testimonialsModel, TestimonialsMsg testimonialsMsg ) ->
            Testimonials.update testimonialsMsg testimonialsModel
                |> Tuple.mapBoth Testimonials (Cmd.map TestimonialsMsg)

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
            Testimonials testimonialsModel ->
                Testimonials.view testimonialsModel
                    |> Html.map TestimonialsMsg

            None ->
                Html.text ""
        ]
