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
    "Typed dataframe workflows for"


subtagline : String
subtagline =
    "Quone is an early language for technically inclined R users: typed CSV decoders, dplyr-style pipelines, explicit missing values, and readable R output."



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
            "Read CSVs through decoders that validate columns, missingness, and types before the dataframe enters your pipeline."
      , glyph = "R"
      , accent = AccentPrimary
      }
    , { title = "dplyr-shaped, statically checked"
      , body =
            "Use familiar verbs like filter, mutate, summarize, group_by, joins, and arrange while Quone checks columns and result shapes."
      , glyph = "\u{03BB}"
      , accent = AccentSecondary
      }
    , { title = "Readable tidyverse R"
      , body =
            "Generated code favors dplyr, readr, purrr, and stringr, so collaborators can inspect and run ordinary R."
      , glyph = "\u{2713}"
      , accent = AccentNeutral
      }
    ]



-- LONGER PITCH (used on the home page below the feature grid)


whyQuone : List String
whyQuone =
    [ "Quone is for R users who want compiler help without giving up readable R. It focuses first on typed dataframe workflows: CSV decoding, dplyr-style transforms, grouped summaries, joins, and explicit Maybe-based missingness."
    , "The initial release is intentionally small and early. APIs may change, VS Code is the supported editor target, and deferred features are left out so the core workflow can be coherent."
    ]
