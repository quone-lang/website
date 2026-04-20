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
    "A typed functional language for"


subtagline : String
subtagline =
    "Quone adds static guarantees to R workflows. Install the pre-release R package, call quone::compile() on a .Q file, and ship the readable R it emits."



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
    [ { title = "Lives inside R"
      , body =
            "Install the quone R package, call quone::compile() from your usual R session, and source the result. No new toolchain to manage."
      , glyph = "R"
      , accent = AccentPrimary
      }
    , { title = "Typed pipelines"
      , body =
            "Dataframe verbs stay dplyr-shaped, but column references and pipeline stages are checked before you ship."
      , glyph = "\u{03BB}"
      , accent = AccentSecondary
      }
    , { title = "Hand off plain R"
      , body =
            "The output is ordinary R - no runtime wrapper - so collaborators who never touch Quone can still read, run, and package it."
      , glyph = "\u{2713}"
      , accent = AccentNeutral
      }
    ]



-- LONGER PITCH (used on the home page below the feature grid)


whyQuone : List String
whyQuone =
    [ "Quone is for R users who want compiler help without leaving R. The quone package installs from GitHub today and exposes a single quone::compile() function; everything else is R."
    , "v0.0.1 is early, but already useful for teams that want more confidence around pipelines, functions, and package-ready output."
    ]
