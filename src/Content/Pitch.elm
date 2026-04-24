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
    "Typed data pipelines that compile to"


subtagline : String
subtagline =
    "Quone is an early typed language for R users: write checked dataframe pipelines, then compile them to readable, maintainable R."



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
    [ { title = "Typed data at the boundary"
      , body =
            "Validate CSV columns, missingness, and types before a dataframe enters the rest of your analysis."
      , glyph = "R"
      , accent = AccentPrimary
      }
    , { title = "Statically checked dplyr"
      , body =
            "Keep the familiar filter/mutate/summarize workflow while Quone checks columns, joins, and result shapes."
      , glyph = "\u{03BB}"
      , accent = AccentSecondary
      }
    , { title = "Readable tidyverse R"
      , body =
            "Hand collaborators ordinary R built from dplyr, readr, purrr, and stringr. Low lock-in is part of the design."
      , glyph = "\u{2713}"
      , accent = AccentNeutral
      }
    ]



-- LONGER PITCH (used on the home page below the feature grid)


whyQuone : List String
whyQuone =
    [ "Quone is for R users who want compiler help without giving up readable R. It focuses first on the work where scripts get brittle: CSV decoding, dplyr-style transforms, grouped summaries, joins, and explicit Maybe-based missingness."
    , "The initial release is intentionally small and honest. APIs may change, VS Code is the supported editor target, and deferred features are left out so the happy path can be reliable."
    ]
