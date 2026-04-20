module Ui.CodeBlock exposing
    ( Language(..)
    , view
    , viewBare
    , viewInline
    )

{-| Syntax-highlighted code blocks for Quone and R.

Highlighting is hand-rolled rather than pulled from a library: Quone's
keyword set is small (LANGUAGE.md section 3.4) and the entire site's
syntax-highlighting needs are covered by a few hundred lines of pure
Elm. R highlighting follows the same shape, with R-specific tokens
(`<-`, `%%`, `%/%`, `TRUE`/`FALSE`/`NULL`, etc.).

-}

import Element
    exposing
        ( Element
        , alignRight
        , centerY
        , clip
        , column
        , el
        , fill
        , height
        , html
        , htmlAttribute
        , paddingXY
        , row
        , scrollbarX
        , shrink
        , spacing
        , text
        , width
        )
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html
import Html.Attributes
import Set exposing (Set)
import Ui.Theme as Theme exposing (type_)
import Ui.Viewport as Viewport



-- PUBLIC API


type Language
    = Quone
    | R


{-| A standalone code block with a language label.
-}
view : Theme.Mode -> Viewport.Viewport -> Language -> String -> Element msg
view themeMode viewport lang source =
    let
        colors =
            Theme.paletteFor themeMode
    in
    column
        [ width fill
        , height shrink
        , htmlAttribute (Html.Attributes.style "flex-basis" "auto")
        , htmlAttribute (Html.Attributes.style "flex-shrink" "0")
        , Background.color colors.codeSurface
        , Border.rounded Theme.radius.md
        , Border.width 1
        , Border.color colors.border
        , spacing 0
        ]
        [ languageBadge themeMode lang source
        , block themeMode viewport lang source
        ]


{-| A bare list of syntax-highlighted lines with no card chrome,
suitable for embedding inside another container (the hero REPL renders
its compiled output this way so the R looks like printed terminal
output, not a nested code card).
-}
viewBare : Theme.Mode -> Viewport.Viewport -> Language -> String -> Element msg
viewBare themeMode viewport lang source =
    let
        colors =
            Theme.paletteFor themeMode

        renderedLines =
            source
                |> String.lines
                |> List.map (renderLine themeMode lang)
    in
    column
        [ Font.family Theme.fontMono
        , Font.size
            (if Viewport.isHandset viewport then
                type_.codeSmallSize

             else
                type_.codeSize
            )
        , Font.color colors.codePlain
        , spacing 4
        , width fill
        ]
        renderedLines


{-| Inline code, used inside paragraphs.
-}
viewInline : Theme.Mode -> String -> Element msg
viewInline themeMode s =
    let
        colors =
            Theme.paletteFor themeMode
    in
    el
        [ Font.family Theme.fontMono
        , Font.size type_.codeSmallSize
        , Background.color colors.codeSurface
        , paddingXY 6 2
        , Border.rounded Theme.radius.sm
        , Font.color colors.codeKeyword
        ]
        (text s)



-- INTERNALS


languageBadge : Theme.Mode -> Language -> String -> Element msg
languageBadge themeMode lang source =
    let
        colors =
            Theme.paletteFor themeMode

        label =
            languageLabel lang
    in
    row
        [ Font.family Theme.fontMono
        , Font.size type_.codeSmallSize
        , paddingXY Theme.space.md Theme.space.sm
        , Border.widthEach { top = 0, right = 0, bottom = 1, left = 0 }
        , Border.color colors.border
        , width fill
        , centerY
        ]
        [ el [ Font.color colors.textMuted ] (text label)
        , el [ alignRight ] (copyButton lang source)
        ]


languageLabel : Language -> String
languageLabel lang =
    case lang of
        Quone ->
            "quone"

        R ->
            "R"


copyButton : Language -> String -> Element msg
copyButton lang source =
    html
        (Html.button
            [ Html.Attributes.class "code-copy-button"
            , Html.Attributes.type_ "button"
            , Html.Attributes.attribute "aria-label" ("Copy " ++ languageLabel lang ++ " code")
            , Html.Attributes.attribute "data-copy-text" source
            ]
            [ Html.text "Copy" ]
        )


block : Theme.Mode -> Viewport.Viewport -> Language -> String -> Element msg
block themeMode viewport lang source =
    el
        [ width fill
        , clip
        , scrollbarX
        , htmlAttribute (Html.Attributes.style "-webkit-overflow-scrolling" "touch")
        , htmlAttribute (Html.Attributes.style "flex-basis" "auto")
        , htmlAttribute (Html.Attributes.style "flex-shrink" "0")
        ]
        (html (blockHtml themeMode viewport lang source))


blockHtml : Theme.Mode -> Viewport.Viewport -> Language -> String -> Html.Html msg
blockHtml themeMode viewport lang source =
    Html.pre
        [ Html.Attributes.class "code-block-pre"
        , Html.Attributes.style "margin" "0"
        , Html.Attributes.style "padding"
            (String.fromInt (codePaddingY viewport)
                ++ "px "
                ++ String.fromInt (codePaddingX viewport)
                ++ "px"
            )
        , Html.Attributes.style "font-family" "\"JetBrains Mono\", \"JetBrains Mono Fallback\", ui-monospace, SFMono-Regular, Menlo, Consolas, monospace"
        , Html.Attributes.style "font-size" (String.fromInt (codeFontSize viewport) ++ "px")
        , Html.Attributes.style "line-height" "1.55"
        , Html.Attributes.style "color" (plainColor themeMode)
        , Html.Attributes.style "white-space" "pre"
        ]
        [ Html.code [] (htmlCodeLines themeMode lang source) ]


codePaddingX : Viewport.Viewport -> Int
codePaddingX viewport =
    if Viewport.isHandset viewport then
        Theme.space.md

    else
        Theme.space.lg


codePaddingY : Viewport.Viewport -> Int
codePaddingY =
    codePaddingX


codeFontSize : Viewport.Viewport -> Int
codeFontSize viewport =
    if Viewport.isHandset viewport then
        type_.codeSmallSize

    else
        type_.codeSize


htmlCodeLines : Theme.Mode -> Language -> String -> List (Html.Html msg)
htmlCodeLines themeMode lang source =
    source
        |> String.lines
        |> List.map (renderHtmlLine themeMode lang)
        |> intersperseHtml (Html.text "\n")


intersperseHtml : Html.Html msg -> List (Html.Html msg) -> List (Html.Html msg)
intersperseHtml separator items =
    case items of
        [] ->
            []

        first :: rest ->
            first
                :: List.concatMap (\item -> [ separator, item ]) rest


renderHtmlLine : Theme.Mode -> Language -> String -> Html.Html msg
renderHtmlLine themeMode lang line =
    Html.span [] (tokenise lang line |> List.map (renderHtmlToken themeMode))


renderHtmlToken : Theme.Mode -> Token -> Html.Html msg
renderHtmlToken themeMode token =
    case token of
        Plain s ->
            Html.text s

        Keyword s ->
            styledToken "code-token-keyword" (tokenColor themeMode token) [ Html.text s ]

        TypeName s ->
            styledToken "code-token-type" (tokenColor themeMode token) [ Html.text s ]

        StringLit s ->
            styledToken "code-token-string" (tokenColor themeMode token) [ Html.text s ]

        NumberLit s ->
            styledToken "code-token-number" (tokenColor themeMode token) [ Html.text s ]

        Comment s ->
            styledToken "code-token-comment" (tokenColor themeMode token) [ Html.text s ]

        Operator s ->
            styledToken "code-token-operator" (tokenColor themeMode token) [ Html.text s ]


styledToken : String -> String -> List (Html.Html msg) -> Html.Html msg
styledToken cls color children =
    Html.span
        [ Html.Attributes.class cls
        , Html.Attributes.style "color" color
        ]
        children


plainColor : Theme.Mode -> String
plainColor themeMode =
    case themeMode of
        Theme.Light ->
            "#1a1a1a"

        Theme.Dark ->
            "#f2f5f8"


tokenColor : Theme.Mode -> Token -> String
tokenColor themeMode token =
    case ( themeMode, token ) of
        ( Theme.Light, Keyword _ ) ->
            "#b03a28"

        ( Theme.Light, TypeName _ ) ->
            "#0d9488"

        ( Theme.Light, StringLit _ ) ->
            "#a16207"

        ( Theme.Light, NumberLit _ ) ->
            "#6d28d9"

        ( Theme.Light, Comment _ ) ->
            "#8a8a8a"

        ( Theme.Light, Operator _ ) ->
            "#b03a28"

        ( Theme.Dark, Keyword _ ) ->
            "#ff907a"

        ( Theme.Dark, TypeName _ ) ->
            "#54d1c8"

        ( Theme.Dark, StringLit _ ) ->
            "#e8b763"

        ( Theme.Dark, NumberLit _ ) ->
            "#bc9cff"

        ( Theme.Dark, Comment _ ) ->
            "#8d97a7"

        ( Theme.Dark, Operator _ ) ->
            "#ff907a"

        _ ->
            plainColor themeMode


renderLine : Theme.Mode -> Language -> String -> Element msg
renderLine themeMode lang line =
    if String.isEmpty line then
        el [ height (Element.px 22) ] (text "\u{00A0}")

    else
        row
            [ spacing 0
            , htmlAttribute (Html.Attributes.style "white-space" "pre")
            ]
            (tokenise lang line |> List.map (renderToken themeMode))



-- TOKENISER


type Token
    = Plain String
    | Keyword String
    | TypeName String
    | StringLit String
    | NumberLit String
    | Comment String
    | Operator String


tokenise : Language -> String -> List Token
tokenise lang line =
    let
        kw =
            keywordSet lang

        ty =
            typeSet lang
    in
    tokeniseHelp lang kw ty line []
        |> List.reverse


tokeniseHelp : Language -> Set String -> Set String -> String -> List Token -> List Token
tokeniseHelp lang kw ty input acc =
    case String.uncons input of
        Nothing ->
            acc

        Just ( c, rest ) ->
            if isCommentStart lang c then
                Comment input :: acc

            else if c == '"' then
                let
                    ( s, after ) =
                        takeString rest
                in
                tokeniseHelp lang kw ty after (StringLit ("\"" ++ s) :: acc)

            else if Char.isDigit c then
                let
                    ( n, after ) =
                        takeNumber input
                in
                tokeniseHelp lang kw ty after (NumberLit n :: acc)

            else if isIdentStart c then
                let
                    ( word, after ) =
                        takeIdent input
                in
                if Set.member word kw then
                    tokeniseHelp lang kw ty after (Keyword word :: acc)

                else if Set.member word ty then
                    tokeniseHelp lang kw ty after (TypeName word :: acc)

                else if isPascalCase word then
                    tokeniseHelp lang kw ty after (TypeName word :: acc)

                else
                    tokeniseHelp lang kw ty after (Plain word :: acc)

            else if isOperatorChar c then
                let
                    ( op, after ) =
                        takeOperator input
                in
                tokeniseHelp lang kw ty after (Operator op :: acc)

            else
                tokeniseHelp lang kw ty rest (Plain (String.fromChar c) :: acc)



-- TOKENISER PRIMITIVES


isCommentStart : Language -> Char -> Bool
isCommentStart lang c =
    case lang of
        Quone ->
            c == '#'

        R ->
            c == '#'


isIdentStart : Char -> Bool
isIdentStart c =
    Char.isAlpha c || c == '_' || c == '.'


isIdentChar : Char -> Bool
isIdentChar c =
    Char.isAlphaNum c || c == '_' || c == '.'


isOperatorChar : Char -> Bool
isOperatorChar c =
    String.contains (String.fromChar c) "+-*/%^<>=!|:&"


isPascalCase : String -> Bool
isPascalCase s =
    case String.uncons s of
        Just ( c, _ ) ->
            Char.isUpper c

        Nothing ->
            False


takeIdent : String -> ( String, String )
takeIdent input =
    let
        ident =
            takeWhile isIdentChar input

        len =
            String.length ident
    in
    ( ident, String.dropLeft len input )


takeNumber : String -> ( String, String )
takeNumber input =
    let
        digits =
            takeWhile (\c -> Char.isDigit c || c == '.' || c == 'L' || c == 'e' || c == 'E') input

        len =
            String.length digits
    in
    ( digits, String.dropLeft len input )


takeOperator : String -> ( String, String )
takeOperator input =
    let
        op =
            takeWhile isOperatorChar input

        len =
            String.length op
    in
    ( op, String.dropLeft len input )


takeString : String -> ( String, String )
takeString input =
    let
        body =
            takeWhile (\c -> c /= '"') input

        len =
            String.length body
    in
    case String.uncons (String.dropLeft len input) of
        Just ( '"', rest ) ->
            ( body ++ "\"", rest )

        _ ->
            ( body, "" )


takeWhile : (Char -> Bool) -> String -> String
takeWhile pred input =
    String.foldl
        (\c ( acc, stopped ) ->
            if stopped then
                ( acc, True )

            else if pred c then
                ( acc ++ String.fromChar c, False )

            else
                ( acc, True )
        )
        ( "", False )
        input
        |> Tuple.first



-- LANGUAGE-SPECIFIC TOKEN SETS


keywordSet : Language -> Set String
keywordSet lang =
    case lang of
        Quone ->
            Set.fromList
                -- Framework keywords (LANGUAGE.md section 3.4)
                [ "module"
                , "exporting"
                , "type"
                , "alias"
                , "import"
                , "if"
                , "then"
                , "else"
                , "case"
                , "of"
                , "let"
                , "in"

                -- Dataframe DSL keywords
                , "dataframe"
                , "select"
                , "filter"
                , "mutate"
                , "summarize"
                , "group_by"
                , "ungroup"
                , "arrange"
                , "rename"
                , "distinct"
                , "distinct_all"
                , "count"
                , "slice"
                , "pull"
                , "relocate"
                , "transmute"
                , "mutate_each"
                , "summarize_each"
                , "left_join"
                , "right_join"
                , "inner_join"
                , "full_join"
                , "anti_join"
                , "semi_join"
                , "cross_join"

                -- Modifier keywords
                , "desc"
                , "asc"
                , "on"
                , "as"
                , "where"
                , "cols"
                ]

        R ->
            Set.fromList
                [ "if"
                , "else"
                , "for"
                , "while"
                , "function"
                , "return"
                , "in"
                , "TRUE"
                , "FALSE"
                , "NULL"
                , "NA"
                , "NA_integer_"
                , "NA_real_"
                , "NA_character_"
                , "Inf"
                , "NaN"
                , "library"
                ]


typeSet : Language -> Set String
typeSet lang =
    case lang of
        Quone ->
            Set.fromList
                [ "Integer"
                , "Double"
                , "Character"
                , "Logical"
                , "Vector"
                , "Maybe"
                , "Result"
                , "True"
                , "False"
                , "Just"
                , "Nothing"
                , "Ok"
                , "Err"
                ]

        R ->
            Set.empty



-- TOKEN RENDERING


renderToken : Theme.Mode -> Token -> Element msg
renderToken themeMode token =
    let
        colors =
            Theme.paletteFor themeMode
    in
    case token of
        Plain s ->
            el [ Font.color colors.codePlain ] (text s)

        Keyword s ->
            el [ Font.color colors.codeKeyword, Font.semiBold ] (text s)

        TypeName s ->
            el [ Font.color colors.codeType, Font.medium ] (text s)

        StringLit s ->
            el [ Font.color colors.codeString ] (text s)

        NumberLit s ->
            el [ Font.color colors.codeNumber ] (text s)

        Comment s ->
            el [ Font.color colors.codeComment, Font.italic ] (text s)

        Operator s ->
            el [ Font.color colors.codeOperator ] (text s)
