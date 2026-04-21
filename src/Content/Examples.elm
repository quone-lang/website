module Content.Examples exposing
    ( Snippet
    , heroSnippets
    , normalizeSnippet
    )

{-| The Quone code samples shown on the marketing site.

Use `Content.ExampleText.codeBlock` or `lines` so snippet text can be
indented in this file without changing how it appears on the site.

-}

import Content.ExampleText exposing (codeBlock)


{-| A short Quone snippet shown in the hero "try it" tabs.
-}
type alias Snippet =
    { filename : String
    , blurb : String
    , quone : String
    , r : String
    }


{-| The full set of snippets featured in the hero tab strip, in display
order. The first one is shown by default. Snippets are ordered by size:
the smallest, easiest-to-read example sits on the left and they grow
in length and richness as you move right.
-}
heroSnippets : List Snippet
heroSnippets =
    [ meanSnippet
    , rmseSnippet
    , topScoresSnippet
    , scoreBandsSnippet
    , adslSummarySnippet
    , siteRollupSnippet
    ]


{-| Default when a snippet index is out of range (see `Page.Home`).
-}
normalizeSnippet : Snippet
normalizeSnippet =
    case heroSnippets of
        first :: _ ->
            first

        [] ->
            meanSnippet


meanSnippet : Snippet
meanSnippet =
    { filename = "mean.Q"
    , blurb = ""
    , quone =
        codeBlock
            """
            mean : Vector Double -> Double
            mean xs <-
                sum xs / length xs
            """
    , r =
        codeBlock
            """
            mean <- function(xs) {
              sum(xs) / length(xs)
            }
            """
    }


rmseSnippet : Snippet
rmseSnippet =
    { filename = "rmse.Q"
    , blurb = ""
    , quone =
        codeBlock
            """
            rmse : Vector Double -> Vector Double -> Double
            rmse actuals predictions <-
                actuals
                    |> map2 (\\p a -> (p - a) ^ 2) predictions
                    |> mean
                    |> sqrt
            """
    , r =
        codeBlock
            """
            rmse <- function(actuals, predictions) {
              (predictions - actuals ^ 2) |>
                mean() |>
                sqrt()
            }
            """
    }


topScoresSnippet : Snippet
topScoresSnippet =
    { filename = "top_scores.Q"
    , blurb = ""
    , quone =
        codeBlock
            """
            type alias Students <-
                dataframe
                    { name  : Vector Character
                    , score : Vector Double
                    }

            top_scores : Students -> Students
            top_scores students <-
                students
                    |> filter { score >= 70.0 }
                    |> arrange { desc score }
            """
    , r =
        codeBlock
            """
            top_scores <- function(students) {
              students |>
                dplyr::filter(score >= 70.0) |>
                dplyr::arrange(dplyr::desc(score))
            }
            """
    }


scoreBandsSnippet : Snippet
scoreBandsSnippet =
    { filename = "score_bands.Q"
    , blurb = ""
    , quone =
        codeBlock
            """
            risk_band : Double -> Character
            risk_band probability <-
                if probability >= 0.8 then "high"
                else if probability >= 0.5 then "medium"
                else "low"

            type alias Scores <-
                dataframe
                    { subject_id  : Vector Character
                    , probability : Vector Double
                    }

            score_bands : Scores -> Scores
            score_bands scores <-
                scores
                    |> mutate { band = risk_band probability }
                    |> arrange { desc probability }
            """
    , r =
        codeBlock
            """
            risk_band <- function(probability) {
              if (probability >= 0.8) {
                "high"
              } else if (probability >= 0.5) {
                "medium"
              } else {
                "low"
              }
            }

            score_bands <- function(scores) {
              scores |>
                dplyr::mutate(band = risk_band(probability)) |>
                dplyr::arrange(dplyr::desc(probability))
            }
            """
    }


adslSummarySnippet : Snippet
adslSummarySnippet =
    { filename = "adsl_summary.Q"
    , blurb = ""
    , quone =
        codeBlock
            """
            type alias Adsl <-
                dataframe
                    { subject_id : Vector Character
                    , arm        : Vector Character
                    , age        : Vector Integer
                    , sex        : Vector Character
                    }

            adsl_summary :
                Adsl
                -> dataframe
                    { arm        : Vector Character
                    , n_subjects : Vector Integer
                    , mean_age   : Vector Double
                    , pct_female : Vector Double
                    }

            adsl_summary adsl <-
                adsl
                    |> group_by { arm }
                    |> summarize
                        { n_subjects = n
                        , mean_age   = mean age
                        , pct_female = mean (if sex == "F" then 1.0 else 0.0)
                        }
                    |> arrange { arm }
            """
    , r =
        codeBlock
            """
            adsl_summary <- function(adsl) {
              adsl |>
                dplyr::group_by(arm) |>
                dplyr::summarize(
                  n_subjects = dplyr::n(),
                  mean_age   = mean(age),
                  pct_female = mean(ifelse(sex == "F", 1.0, 0.0))
                ) |>
                dplyr::arrange(arm)
            }
            """
    }


siteRollupSnippet : Snippet
siteRollupSnippet =
    { filename = "site_rollup.Q"
    , blurb = ""
    , quone =
        codeBlock
            """
            disc_flag : Character -> Double
            disc_flag status <-
                if status == "DISCONTINUED" then 1.0 else 0.0

            type alias Subjects <-
                dataframe
                    { subject_id : Vector Character
                    , site_id    : Vector Character
                    , arm        : Vector Character
                    , status     : Vector Character
                    , response   : Vector Double
                    }

            site_rollup :
                Subjects
                -> dataframe
                    { site_id          : Vector Character
                    , arm              : Vector Character
                    , n_subjects       : Vector Integer
                    , mean_response    : Vector Double
                    , pct_discontinued : Vector Double
                    }

            site_rollup subjects <-
                subjects
                    |> mutate { disc = disc_flag status }
                    |> group_by { site_id, arm }
                    |> summarize
                        { n_subjects       = n
                        , mean_response    = mean response
                        , pct_discontinued = mean disc
                        }
                    |> arrange { site_id, arm }
            """
    , r =
        codeBlock
            """
            disc_flag <- function(status) {
              if (status == "DISCONTINUED") {
                1.0
              } else {
                0.0
              }
            }

            site_rollup <- function(subjects) {
              subjects |>
                dplyr::mutate(disc = disc_flag(status)) |>
                dplyr::group_by(site_id, arm) |>
                dplyr::summarize(
                  n_subjects       = dplyr::n(),
                  mean_response    = mean(response),
                  pct_discontinued = mean(disc)
                ) |>
                dplyr::arrange(site_id, arm)
            }
            """
    }