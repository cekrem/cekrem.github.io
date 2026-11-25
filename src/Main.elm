module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes as Attributes
import Search



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
    { searchModel : Search.Model
    }


init : String -> ( Model, Cmd Msg )
init _ =
    let
        ( searchModel, searchCmd ) =
            Search.init ()
                |> Tuple.mapSecond (Cmd.map SearchMsg)
    in
    ( { searchModel = searchModel
      }
    , searchCmd
    )



-- UPDATE


type Msg
    = SearchMsg Search.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        ( searchModel, searchCmd ) =
            updateSearchModel msg model.searchModel
    in
    ( { searchModel = searchModel
      }
    , searchCmd
    )


updateSearchModel : Msg -> Search.Model -> ( Search.Model, Cmd Msg )
updateSearchModel msg searchModel =
    case msg of
        SearchMsg searchMsg ->
            Search.update searchMsg searchModel
                |> Tuple.mapSecond (Cmd.map SearchMsg)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Search.subscriptions model.searchModel |> Sub.map SearchMsg



-- VIEW


view : Model -> Html Msg
view model =
    Html.div [ Attributes.class "elm-app" ]
        [ Search.view model.searchModel
            |> Html.map SearchMsg
        ]
