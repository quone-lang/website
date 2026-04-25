module Content.Pitch exposing
    ( Accent(..)
    , Feature
    , taglinePrefix
    , subtagline
    , features
    , whyQuone
    )

{-| Marketing copy for the home page. Kept as plain Elm strings so the
home-page module stays focused on layout.

The voice is direct, technical, and respectful of the R audience: no
breathless adjectives, no claims of being "better than" R - the pitch
is that Quone gives R users static checks and a uniform syntax while
producing code they could have written themselves.

-}


{-| Stable portion of the hero headline; the trailing letter is rendered
separately so it can crossfade between R and Q on hover.
-}
taglinePrefix : String
taglinePrefix =
    "Typed data pipelines that"


subtagline : String
subtagline =
    "Write typed dataframe pipelines for R: decode CSVs into known shapes, use dplyr-style verbs, model missing values with Maybe, and compile to readable tidyverse code."



-- FEATURE CARDS


type Accent
    = AccentPrimary
    | AccentSecondary
    | AccentNeutral


type alias Feature =
    { title : String
    , body : String
    , glyph : String
    , accent : Accent
    }


features : List Feature
features =
    [ { title = "Typed CSV schemas"
      , body =
            "Describe incoming columns once, then let Quone check names, types, and missingness before data reaches the rest of your analysis."
      , glyph = "T"
      , accent = AccentPrimary
      }
    , { title = "Checked dataframe verbs"
      , body =
            "Use filter, mutate, summarize, joins, grouping, and ordering with compiler feedback about columns and result shapes."
      , glyph = "\u{2713}"
      , accent = AccentSecondary
      }
    , { title = "Readable R output"
      , body =
            "Compile to ordinary tidyverse code built from dplyr, readr, purrr, and stringr, so collaborators can inspect and run the result."
      , glyph = "R"
      , accent = AccentNeutral
      }
    ]



-- LONGER PITCH (used on the home page below the feature grid)


whyQuone : List String
whyQuone =
    [ "Quone combines Hindley-Milner inference, custom types, typed dataframe shapes, and explicit Maybe-based missingness with a pipeline syntax that should feel familiar to R users."
    , "It focuses first on the brittle parts of analysis scripts: validating CSV inputs, keeping column names and types in sync through transforms, checking grouped summaries and joins, and producing R that stays close to the source."
    ]
