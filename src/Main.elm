port module Main exposing (main)

import Browser
import Browser.Events
import Element exposing (fill, height, layout, map, width)
import Element.Background as Background
import Element.Font as Font
import Json.Encode as Encode
import Page.Home as Home
import Ui.Layout as Layout
import Ui.Theme as Theme exposing (type_)
import Ui.Viewport as Viewport


type alias Flags =
    { width : Int
    , height : Int
    , prefersDark : Bool
    }


main : Program Flags Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { heroState : Home.HeroState
    , viewport : Viewport.Viewport
    , isMenuOpen : Bool
    , systemPrefersDark : Bool
    , themePreference : ThemePreference
    , themeMode : Theme.Mode
    }


type ThemePreference
    = FollowSystem
    | Manual Theme.Mode


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { heroState = Home.initHeroState
      , viewport = Viewport.fromSize flags.width flags.height
      , isMenuOpen = False
      , systemPrefersDark = flags.prefersDark
      , themePreference = FollowSystem
      , themeMode = Theme.modeFromPrefersDark flags.prefersDark
      }
    , applyThemePreference FollowSystem
    )


type Msg
    = HomeMsg Home.Msg
    | ToggleMenu
    | ToggleTheme
    | ViewportChanged Int Int
    | SystemThemeChanged Bool


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HomeMsg subMsg ->
            let
                ( newHeroState, heroCmd ) =
                    Home.updateHero subMsg model.heroState
            in
            ( { model | heroState = newHeroState }
            , Cmd.map HomeMsg heroCmd
            )

        ToggleMenu ->
            ( { model | isMenuOpen = not model.isMenuOpen }, Cmd.none )

        ToggleTheme ->
            let
                nextMode =
                    if model.themeMode == Theme.Dark then
                        Theme.Light

                    else
                        Theme.Dark

                nextPreference =
                    if nextMode == Theme.modeFromPrefersDark model.systemPrefersDark then
                        FollowSystem

                    else
                        Manual nextMode
            in
            ( { model
                | themePreference = nextPreference
                , themeMode = resolveThemeMode model.systemPrefersDark nextPreference
              }
            , applyThemePreference nextPreference
            )

        ViewportChanged width height ->
            let
                newViewport =
                    Viewport.fromSize width height
            in
            ( { model
                | viewport = newViewport
                , isMenuOpen =
                    if Viewport.isCompact newViewport then
                        model.isMenuOpen

                    else
                        False
              }
            , Cmd.none
            )

        SystemThemeChanged prefersDark ->
            ( { model
                | systemPrefersDark = prefersDark
                , themeMode = resolveThemeMode prefersDark model.themePreference
              }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Browser.Events.onResize ViewportChanged
        , systemThemeChanged SystemThemeChanged
        ]


port systemThemeChanged : (Bool -> msg) -> Sub msg


port setThemePreference : Encode.Value -> Cmd msg


applyThemePreference : ThemePreference -> Cmd msg
applyThemePreference preference =
    setThemePreference
        (Encode.string
            (case preference of
                FollowSystem ->
                    "system"

                Manual Theme.Light ->
                    "light"

                Manual Theme.Dark ->
                    "dark"
            )
        )


resolveThemeMode : Bool -> ThemePreference -> Theme.Mode
resolveThemeMode systemPrefersDark preference =
    case preference of
        FollowSystem ->
            Theme.modeFromPrefersDark systemPrefersDark

        Manual mode ->
            mode


view : Model -> Browser.Document Msg
view model =
    let
        colors =
            Theme.paletteFor model.themeMode
    in
    { title = "Quone - typed dataframe pipelines for R"
    , body =
        [ layout
            [ width fill
            , height fill
            , Background.color colors.background
            , Font.family Theme.fontSans
            , Font.size type_.bodySize
            , Font.color colors.textPrimary
            ]
            (Layout.page
                { themeMode = model.themeMode
                , isFollowingSystem = model.themePreference == FollowSystem
                , viewport = model.viewport
                , currentPath = "/"
                , isMenuOpen = model.isMenuOpen
                , onToggleMenu = ToggleMenu
                , onToggleTheme = ToggleTheme
                , content =
                    map HomeMsg
                        (Home.view model.themeMode model.viewport model.heroState)
                }
            )
        ]
    }

