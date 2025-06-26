module Search exposing (Model, Msg, Post, init, update, view)

import Browser.Dom as Dom
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Html.Lazy as Lazy
import HtmlHelpers exposing (nothing)
import Http
import Maybe exposing (Maybe)
import Task



-- MODEL


type alias Model =
    { searchTerm : String
    , content : Maybe (List Post)
    , open : Bool
    }


type alias Post =
    { raw : String
    , title : String
    , link : String
    }


init : () -> ( Model, Cmd Msg )
init () =
    ( { searchTerm = ""
      , content = Nothing
      , open = False
      }
    , getXmlFeed
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleSearch ->
            let
                open : Bool
                open =
                    not model.open

                cmd : Cmd Msg
                cmd =
                    if open then
                        Dom.focus inputId |> Task.attempt (\_ -> Noop)

                    else
                        Cmd.none
            in
            ( { model | open = open }, cmd )

        ChangeTerm term ->
            ( { model | searchTerm = term }, Cmd.none )

        GotXmlFeed (Ok feed) ->
            ( { model | content = feed |> transformFeed |> Just }, Cmd.none )

        GotXmlFeed (Err _) ->
            ( { model | content = Nothing }, Cmd.none )

        Noop ->
            ( model, Cmd.none )


type Msg
    = ChangeTerm String
    | GotXmlFeed (Result Http.Error String)
    | ToggleSearch
    | Noop


transformFeed : String -> List Post
transformFeed =
    String.split "<item>\n"
        >> List.drop 1
        >> List.map String.trim
        >> List.map
            (\entry ->
                { raw = entry |> lowerCaseAndRemoveWhitespace
                , title = entry |> parseProp "title"
                , link = entry |> parseProp "link"
                }
            )


parseProp : String -> String -> String
parseProp prop =
    String.split (prop ++ ">")
        >> List.drop 1
        >> List.head
        >> Maybe.withDefault ""
        >> String.dropRight 2



-- VIEW


inputId : String
inputId =
    "search-input"


view : Model -> Html Msg
view model =
    let
        searchPosition : String
        searchPosition =
            if not model.open then
                "-34rem"

            else
                "0"
    in
    Html.node "search"
        [ Attributes.style "position" "fixed"
        , Attributes.style "bottom" "0"
        , Attributes.style "left" searchPosition
        , Attributes.style "margin" "4rem 2rem"
        , Attributes.style "flex-direction" "column"
        , Attributes.style "justify-content" "center"
        , Attributes.style "align-items" "center"
        , Attributes.style "transition" "0.4s ease left"
        ]
        [ Html.input
            [ Attributes.style "padding" "1rem"
            , Attributes.style "border" "none"
            , Attributes.style "outline" "none"
            , Attributes.style "border-radius" "1rem"
            , Attributes.style "width" "32rem"
            , Attributes.id inputId

            -- update
            , Attributes.placeholder "Search in realtime"
            , Attributes.value model.searchTerm
            , Events.onInput ChangeTerm
            ]
            []
        , if not model.open then
            Html.div
                [ Attributes.style "cursor" "pointer"
                , Attributes.style "float" "right"
                , Attributes.style "padding" "0.8rem"
                , Attributes.style "border-radius" "0 2rem 2rem 0"
                , Attributes.style "backdrop-filter" "blur(5rem)"
                , Attributes.style "transition" "0.4s ease opacity"
                , Events.onClick ToggleSearch
                ]
                [ Html.text "Search?" ]

          else
            Html.div
                [ Attributes.style "position" "fixed"
                , Attributes.style "top" "0"
                , Attributes.style "bottom" "0"
                , Attributes.style "left" "0"
                , Attributes.style "right" "0"
                , Attributes.style "z-index" "-1"
                , Events.onClick ToggleSearch
                ]
                []
        , searchResults model
        ]


searchResults : Model -> Html Msg
searchResults model =
    Lazy.lazy3
        (\show term posts ->
            if show then
                Html.div
                    [ Attributes.style "position" "absolute"
                    , Attributes.style "bottom" "5rem"
                    , Attributes.style "left" "0rem"
                    , Attributes.style "border-radius" "1rem"
                    , Attributes.style "border" "thin solid"
                    , Attributes.style "border-collapse" "collapse"
                    , Attributes.style "backdrop-filter" "blur(5rem)"
                    , Attributes.style "max-width" "100vw"
                    , Attributes.style "transition" "opacity 0.4s ease"
                    , Attributes.style "opacity" <|
                        if term == "" then
                            "0"

                        else
                            "1"
                    ]
                    (if term /= "" then
                        posts
                            |> List.filterMap (weightPost term)
                            |> sortByWeight
                            |> List.map resultEntry
                            |> orEmptyEntry

                     else
                        []
                    )

            else
                nothing
        )
        model.open
        (model.searchTerm |> lowerCaseAndRemoveWhitespace)
        (model.content |> Maybe.withDefault [])


entryStyle : List (Html.Attribute msg)
entryStyle =
    [ Attributes.style "overflow" "hidden"
    , Attributes.style "text-wrap" "nowrap"
    , Attributes.style "max-width" "calc(100vw - 5rem)"
    , Attributes.style "text-overflow" "ellipsis"
    , Attributes.style "margin" "0.5rem"
    ]


resultEntry : Post -> Html Msg
resultEntry post =
    Html.div
        entryStyle
        [ Html.a
            [ Attributes.href post.link
            ]
            [ Html.text post.title ]
        ]


orEmptyEntry : List (Html msg) -> List (Html msg)
orEmptyEntry list =
    case list of
        [] ->
            [ Html.div entryStyle [ Html.text "No results (searched through titles && descriptions)" ] ]

        nonEmpty ->
            nonEmpty



-- HELPERS


lowerCaseAndRemoveWhitespace : String -> String
lowerCaseAndRemoveWhitespace =
    String.toLower >> String.replace " " ""


sortByWeight : List ( comparable, a ) -> List a
sortByWeight =
    List.sortWith flippedComparison
        >> List.take 10
        >> List.map Tuple.second


flippedComparison : ( comparable, a ) -> ( comparable, a ) -> Order
flippedComparison ( a, _ ) ( b, _ ) =
    case compare a b of
        LT ->
            GT

        EQ ->
            EQ

        GT ->
            LT


{-| Veeeery simplified weighting based on number of matches
-}
weightPost : String -> Post -> Maybe ( Int, Post )
weightPost term post =
    let
        weight : Int
        weight =
            post.raw
                |> String.indices term
                |> List.length
    in
    if weight > 0 then
        Just ( weight, post )

    else
        Nothing



-- CMD


getXmlFeed : Cmd Msg
getXmlFeed =
    Http.get
        { url = "/index.xml"
        , expect = Http.expectString GotXmlFeed
        }
