module Content.ExampleText exposing (codeBlock, lines)

{-| Helpers for hero snippet strings so you can lay out source the way
you want it to read: `lines` for a list of rows, or `codeBlock` for a
dedented multiline paste.
-}

import String


{-| Join lines with a single newline. Write each displayed line as its
own string — no accidental indentation from the Elm record.
-}
lines : List String -> String
lines =
    String.join "\n"


{-| Paste a multiline string indented to match surrounding Elm; leading
spaces shared by every non-blank line are stripped so the result starts
at column 0 (relative indentation inside the block is kept).

Leading and trailing blank lines are removed. Blank lines in the middle
become empty strings. Only leading **spaces** count toward the common
indent (tabs are not treated as indent).

-}
codeBlock : String -> String
codeBlock raw =
    raw
        |> String.split "\n"
        |> trimBlankEdges
        |> stripCommonIndent
        |> String.join "\n"


trimBlankEdges : List String -> List String
trimBlankEdges xs =
    xs
        |> dropLeadingBlanks
        |> List.reverse
        |> dropLeadingBlanks
        |> List.reverse


dropLeadingBlanks : List String -> List String
dropLeadingBlanks list =
    case list of
        [] ->
            []

        h :: t ->
            if isBlank h then
                dropLeadingBlanks t
            else
                list


isBlank : String -> Bool
isBlank s =
    String.trim s == ""


stripCommonIndent : List String -> List String
stripCommonIndent inputLines =
    let
        indents =
            List.filterMap
                (\line ->
                    if isBlank line then
                        Nothing
                    else
                        Just (leadingSpaceCount line)
                )
                inputLines
    in
    case List.minimum indents of
        Nothing ->
            List.map (\_ -> "") inputLines

        Just n ->
            List.map (dropIndent n) inputLines


dropIndent : Int -> String -> String
dropIndent n line =
    if isBlank line then
        ""
    else
        String.dropLeft n line


leadingSpaceCount : String -> Int
leadingSpaceCount s =
    let
        step c ( count, onlySpaces ) =
            if not onlySpaces then
                ( count, False )
            else if c == ' ' then
                ( count + 1, True )
            else
                ( count, False )
    in
    Tuple.first (String.foldl step ( 0, True ) s)
