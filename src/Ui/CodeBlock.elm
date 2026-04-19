module Ui.CodeBlock exposing
    ( Language(..)
    , view
    , viewSideBySide
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
        , alignTop
        , clip
        , column
        , el
        , fill
        , height
        , htmlAttribute
        , minimum
        , padding
        , paddingXY
        , paragraph
        , rgb255
        , rgba255
        , row
        , scrollbarX
        , spacing
        , text
        , width
        , wrappedRow
        )
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import Set exposing (Set)
import Ui.Theme as Theme exposing (palette, type_)
import Ui.Viewport as Viewport



-- PUBLIC API


type Language
    = Quone
    | R


{-| A standalone code block with a language label.
-}
view : Viewport.Viewport -> Language -> String -> Element msg
view viewport lang source =
    column
        [ width fill
        , Background.color palette.codeSurface
        , Border.rounded Theme.radius.md
        , Border.width 1
        , Border.color palette.border
        , spacing 0
        ]
        [ languageBadge lang
        , block viewport lang source
        ]


{-| Two code blocks side by side: Quone on the left, R on the right.
This is the canonical "before / after" presentation used in the hero
and the longer code-example sections.

`clip` on each side prevents long monospace lines from pushing past the
50/50 split: instead the code block scrolls horizontally inside its
container.

-}
viewSideBySide : Viewport.Viewport -> { quone : String, r : String } -> Element msg
viewSideBySide viewport parts =
    let
        spacing_ =
            if Viewport.isHandset viewport then
                Theme.space.md

            else
                Theme.space.lg

        pane lang source =
            el
                [ width fill
                , alignTop
                , clip
                , htmlAttribute (Html.Attributes.style "min-width" "0")
                , htmlAttribute (Html.Attributes.style "flex" "1 1 320px")
                ]
                (view viewport lang source)
    in
    wrappedRow
        [ width fill
        , spacing spacing_
        , alignTop
        ]
        [ pane Quone parts.quone
        , pane R parts.r
        ]


{-| Inline code, used inside paragraphs.
-}
viewInline : String -> Element msg
viewInline s =
    el
        [ Font.family [ Theme.fontMono, Font.monospace ]
        , Font.size type_.codeSmallSize
        , Background.color palette.codeSurface
        , paddingXY 6 2
        , Border.rounded Theme.radius.sm
        , Font.color palette.codeKeyword
        ]
        (text s)



-- INTERNALS


languageBadge : Language -> Element msg
languageBadge lang =
    let
        label =
            case lang of
                Quone ->
                    "quone"

                R ->
                    "R"
    in
    el
        [ Font.family [ Theme.fontMono, Font.monospace ]
        , Font.size type_.codeSmallSize
        , Font.color palette.textMuted
        , paddingXY Theme.space.md Theme.space.sm
        , Border.widthEach { top = 0, right = 0, bottom = 1, left = 0 }
        , Border.color palette.border
        , width fill
        ]
        (text label)


block : Viewport.Viewport -> Language -> String -> Element msg
block viewport lang source =
    let
        renderedLines =
            source
                |> String.lines
                |> List.map (renderLine lang)
    in
    el
        [ width fill
        , clip
        , scrollbarX
        ]
        (column
            [ Font.family [ Theme.fontMono, Font.monospace ]
            , Font.size
                (if Viewport.isHandset viewport then
                    type_.codeSmallSize

                 else
                    type_.codeSize
                )
            , Font.color palette.codePlain
            , paddingXY
                (if Viewport.isHandset viewport then
                    Theme.space.md

                 else
                    Theme.space.lg
                )
                (if Viewport.isHandset viewport then
                    Theme.space.md

                 else
                    Theme.space.lg
                )
            , spacing 4
            , width fill
            , height (fill |> minimum 0)
            ]
            renderedLines
        )


renderLine : Language -> String -> Element msg
renderLine lang line =
    if String.isEmpty line then
        el [ height (Element.px 22) ] (text "\u{00A0}")

    else
        row
            [ spacing 0
            , htmlAttribute (Html.Attributes.style "white-space" "pre")
            ]
            (tokenise lang line |> List.map renderToken)



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
            if isCommentStart lang c rest then
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


isCommentStart : Language -> Char -> String -> Bool
isCommentStart lang c _ =
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


renderToken : Token -> Element msg
renderToken token =
    case token of
        Plain s ->
            el [ Font.color palette.codePlain ] (text s)

        Keyword s ->
            el [ Font.color palette.codeKeyword, Font.semiBold ] (text s)

        TypeName s ->
            el [ Font.color palette.codeType, Font.medium ] (text s)

        StringLit s ->
            el [ Font.color palette.codeString ] (text s)

        NumberLit s ->
            el [ Font.color palette.codeNumber ] (text s)

        Comment s ->
            el [ Font.color palette.codeComment, Font.italic ] (text s)

        Operator s ->
            el [ Font.color palette.codeOperator ] (text s)
