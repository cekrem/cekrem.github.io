module Search exposing (Model, Msg, init, update, view)

import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Html.Lazy as Lazy
import HtmlHelpers exposing (nothing)
import Http
import Maybe exposing (Maybe)



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
            ( { model | open = not model.open }, Cmd.none )

        ChangeTerm term ->
            ( { model | searchTerm = term }, Cmd.none )

        GotXmlFeed (Ok feed) ->
            ( { model | content = feed |> transformFeed |> Just }, Cmd.none )

        GotXmlFeed (Err _) ->
            ( { model | content = Nothing }, Cmd.none )


type Msg
    = ChangeTerm String
    | GotXmlFeed (Result Http.Error String)
    | ToggleSearch


transformFeed : String -> List Post
transformFeed rawFeed =
    rawFeed
        |> String.split "<item>\n"
        >> List.drop 1
        >> List.map String.trim
        >> List.map
            (\entry ->
                { raw = entry |> String.toLower >> String.replace " " ""
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


view : Model -> Html Msg
view model =
    let
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
        , Attributes.style "margin" "2rem"
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

            -- update
            , Attributes.placeholder "Search in realtime"
            , Attributes.value model.searchTerm
            , Events.onInput ChangeTerm
            ]
            []
        , Html.div
            [ Attributes.style "cursor" "pointer"
            , Attributes.style "float" "right"
            , Attributes.style "margin" "1rem"
            , Events.onClick ToggleSearch
            ]
            [ Html.text "Search?" ]
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
                    , Attributes.style "backdrop-filter" "blur(100rem)"
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
                            >> List.sortBy Tuple.first
                            -- TODO: just use sortWith properly
                            >> List.reverse
                            >> List.take 10
                            >> List.map Tuple.second
                            >> List.map resultEntry
                            >> orEmptyEntry

                     else
                        []
                    )

            else
                nothing
        )
        model.open
        (model.searchTerm |> String.toLower >> String.replace " " "")
        (model.content |> Maybe.withDefault [])


{-| Veeeery simplified weighting based on number of matches
-}
weightPost : String -> Post -> Maybe ( Int, Post )
weightPost term post =
    let
        weight =
            post.raw
                |> String.indices term
                >> List.length
    in
    if weight > 0 then
        Just ( weight, post )

    else
        Nothing


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



-- CMD


getXmlFeed : Cmd Msg
getXmlFeed =
    Http.get
        { url = "/index.xml"
        , expect = Http.expectString GotXmlFeed
        }
