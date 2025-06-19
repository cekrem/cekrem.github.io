module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes as Attributes
import Html.Events exposing (..)
import Search
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


type alias Model =
    { routeModel : RouteModel
    , searchModel : Search.Model
    }


type RouteModel
    = Testimonials Testimonials.Model
    | None


init : String -> ( Model, Cmd Msg )
init path =
    let
        ( routeModel, routeCmd ) =
            if Testimonials.showForPath path then
                Testimonials.init ()
                    |> Tuple.mapBoth Testimonials (Cmd.map TestimonialsMsg)

            else
                ( None
                , Cmd.none
                )

        ( searchModel, searchCmd ) =
            Search.init ()
                |> Tuple.mapSecond (Cmd.map SearchMsg)
    in
    ( { routeModel = routeModel
      , searchModel = searchModel
      }
    , Cmd.batch
        [ routeCmd
        , searchCmd
        ]
    )



-- UPDATE


type Msg
    = NoOp
    | TestimonialsMsg Testimonials.Msg
    | SearchMsg Search.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        ( routeModel, routeCmd ) =
            updateRouteModel msg model.routeModel

        ( searchModel, searchCmd ) =
            updateSearchModel msg model.searchModel
    in
    ( { routeModel = routeModel
      , searchModel = searchModel
      }
    , Cmd.batch
        [ routeCmd
        , searchCmd
        ]
    )


updateRouteModel : Msg -> RouteModel -> ( RouteModel, Cmd Msg )
updateRouteModel msg routeModel =
    case ( routeModel, msg ) of
        ( Testimonials testimonialsModel, TestimonialsMsg testimonialsMsg ) ->
            Testimonials.update testimonialsMsg testimonialsModel
                |> Tuple.mapBoth Testimonials (Cmd.map TestimonialsMsg)

        _ ->
            ( routeModel, Cmd.none )


updateSearchModel : Msg -> Search.Model -> ( Search.Model, Cmd Msg )
updateSearchModel msg searchModel =
    case msg of
        SearchMsg searchMsg ->
            Search.update searchMsg searchModel
                |> Tuple.mapSecond (Cmd.map SearchMsg)

        _ ->
            ( searchModel, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [ Attributes.class "container" ]
        [ case model.routeModel of
            Testimonials testimonialsModel ->
                Testimonials.view testimonialsModel
                    |> Html.map TestimonialsMsg

            None ->
                Html.text ""
        , Search.view model.searchModel
            |> Html.map SearchMsg
        ]
