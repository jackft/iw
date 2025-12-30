# =============================================================================
# Title: Invisible Wall
# File: saveresults.R
# Author: Jack Terwilliger (University of California, San Diego)
# Date Created: 2025-10-08
# Last Modified: 2025-10-08
# Description:
#   Functions for saving results to files to keep analysis.R readable
#
# Dependencies:
#   - broom.mixed
#   - data.table
#
# =============================================================================

library(broom.mixed)
library(data.table)

write_experiment_1_results_to_file <- function(
  model_breaching_experiment_1,
  emmeans_breaching_experiment_1,
  emmeans_breaching_experiment_1_distance_contrast,
  emmeans_breaching_experiment_1_actor_gender_contrast,
  emmeans_breaching_experiment_1_gaze_interaction_contrast,
  emmeans_breaching_experiment_1_gaze_interaction_odds
) {

  # ===========================================================================
  broom.mixed::tidy(model_breaching_experiment_1, effects = "fixed") |>
    data.table::fwrite("results/breaching_experiment_1_glmer_summary.csv")

  cat(
    "===============================================================================
  Experiment 1 breach probabilities
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = FALSE
  )
  capture.output(
    summary(model_breaching_experiment_1),
    file = "results/model_summaries.txt",
    append = TRUE
  )

  # ===========================================================================
  broom.mixed::tidy(emmeans_breaching_experiment_1, effects = "fixed") |>
    data.table::fwrite("results/breaching_experiment_1_emmeans_summary.csv")

  cat(
    "
  ===============================================================================
  Experiment 1 marginal breach probabilities
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )
  capture.output(
    summary(emmeans_breaching_experiment_1),
    file = "results/model_summaries.txt",
    append = TRUE
  )

  # ===========================================================================
  broom.mixed::tidy(emmeans_breaching_experiment_1_distance_contrast, effects = "fixed") |>
    data.table::fwrite("results/breaching_experiment_1_emmeans_distance_contrast_summary.csv")
  cat(
    "
  ===============================================================================
  Experiment 1 distance contrast
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )
  capture.output(
    summary(emmeans_breaching_experiment_1_distance_contrast),
    file = "results/model_summaries.txt",
    append = TRUE
  )

  # ===========================================================================
  broom.mixed::tidy(emmeans_breaching_experiment_1_actor_gender_contrast, effects = "fixed") |>
    data.table::fwrite("results/breaching_experiment_1_emmeans_experiment_1_actor_gender_contrast_summary.csv")
  cat(
    "
  ===============================================================================
  Experiment 1 actor gender contrast
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )
  capture.output(
    summary(pairs(emmeans_breaching_experiment_1_actor_gender_contrast, reverse=TRUE)),
    file = "results/model_summaries.txt",
    append = TRUE
  )

  # ===========================================================================
  broom.mixed::tidy(emmeans_breaching_experiment_1_gaze_talk_interaction_contrast, effects = "fixed") |>
    data.table::fwrite("results/breaching_experiment_1_emmeans_gaze_talk_interaction_contrast_summary.csv")
  cat(
    "
  ===============================================================================
  Experiment 1 gaze:talk interaction contrast
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )
  capture.output(
    summary(pairs(emmeans_breaching_experiment_1_gaze_talk_interaction_contrast, reverse=TRUE)),
    file = "results/model_summaries.txt",
    append = TRUE
  )

  # ===========================================================================
  broom.mixed::tidy(emmeans_breaching_experiment_1_gaze_talk_interaction_odds, effects = "fixed") |>
    data.table::fwrite("results/breaching_experiment_1_emmeans_gaze_talk_interaction_oods_summary.csv")
  cat(
    "
  ===============================================================================
  Experiment 1 gaze:talk interaction odds
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )
  capture.output(
    summary(pairs(emmeans_breaching_experiment_1_gaze_talk_interaction_odds, reverse=TRUE)),
    file = "results/model_summaries.txt",
    append = TRUE
  )
}

write_experiment_2_results_to_file <- function(
  model_breaching_experiment_2,
  emmeans_breaching_experiment_2,
  contrast_body_orientation_experiment_2,
  contrast_breach_before_experiment_2
) {
  # ===========================================================================
  broom.mixed::tidy(model_breaching_experiment_2, effects = "fixed") |>
    data.table::fwrite("results/breaching_experiment_2_glmer_summary.csv")

  cat(
    "
  ===============================================================================
  Experiment 2 breach probabilities
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )

  capture.output(
    summary(model_breaching_experiment_2),
    file = "results/model_summaries.txt",
    append = TRUE
  )

  # ===========================================================================
  broom.mixed::tidy(emmeans_breaching_experiment_2, effects = "fixed") |>
    data.table::fwrite("results/breaching_experiment_2_emmeans_summary.csv")

  cat(
    "
  ===============================================================================
  Experiment 2 marginal breach probabilities
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )

  capture.output(
    summary(emmeans_breaching_experiment_2),
    file = "results/model_summaries.txt",
    append = TRUE
  )

  # ===========================================================================
  broom.mixed::tidy(contrast_body_orientation_experiment_2, effects = "fixed") |>
    data.table::fwrite("results/contrast_body_orientation_experiment_2.csv")

  cat(
    "
  ===============================================================================
  Experiment 2 body orientation contrasts
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )
  capture.output(
    summary(contrast_body_orientation_experiment_2),
    file = "results/model_summaries.txt",
    append = TRUE
  )

  # ===========================================================================
  broom.mixed::tidy(contrast_breach_before_experiment_2, effects = "fixed") |>
    data.table::fwrite("results/contrast_breach_before_experiment_2.csv")

  cat(
    "
  ===============================================================================
  Experiment 2 breach before (collective-rule breacking) contrasts
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )
  capture.output(
    summary(contrast_breach_before_experiment_2),
    file = "results/model_summaries.txt",
    append = TRUE
  )
}

write_experiment_3_results_to_file <- function(
  model_breaching_experiment_3,
  emmeans_breaching_experiment_3,
  model_breaching_experiment_1_and_3,
  emmeans_breaching_experiment_1_and_3,
  emmeans_breaching_by_gender_experiment_1_and_3,
  contrast_type_of_interaction_experiment_1_and_3,
  emmeans_breaching_experiment_1_and_3_compare_human_sign_gaze,
  emmeans_breaching_experiment_1_and_3_gaze_type_of_interaction_interaction_odds
) {
  # ===========================================================================
  broom.mixed::tidy(model_breaching_experiment_3, effects = "fixed") |>
    data.table::fwrite("results/breaching_experiment_3_glmer_summary.csv")

  cat(
    "
  ===============================================================================
  Experiment 3 breach probabilities
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )

  capture.output(
    summary(model_breaching_experiment_3),
    file = "results/model_summaries.txt",
    append = TRUE
  )

  # ===========================================================================
  broom.mixed::tidy(emmeans_breaching_experiment_3, effects = "fixed") |>
    data.table::fwrite("results/breaching_experiment_3_emmeans_summary.csv")

  cat(
    "
  ===============================================================================
  Experiment 3 marginal breach probabilities
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )

  capture.output(
    summary(emmeans_breaching_experiment_3),
    file = "results/model_summaries.txt",
    append = TRUE
  )

  # ===========================================================================
  broom.mixed::tidy(model_breaching_experiment_1_and_3, effects = "fixed") |>
    data.table::fwrite("results/breaching_experiment_1_and_3_glmer_summary.csv")

  cat(
    "
  ===============================================================================
  Experiment 3 breach probabilities
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )

  capture.output(
    summary(model_breaching_experiment_1_and_3),
    file = "results/model_summaries.txt",
    append = TRUE
  )

  # ===========================================================================
  broom.mixed::tidy(emmeans_breaching_experiment_1_and_3, effects = "fixed") |>
    data.table::fwrite("results/breaching_experiment_1_and_3_emmeans_summary.csv")

  cat(
    "
  ===============================================================================
  Experiment 3 marginal breach probabilities
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )

  capture.output(
    summary(emmeans_breaching_experiment_1_and_3),
    file = "results/model_summaries.txt",
    append = TRUE
  )

  # ===========================================================================
  broom.mixed::tidy(emmeans_breaching_by_gender_experiment_1_and_3, effects = "fixed") |>
    data.table::fwrite("results/breaching_by_gender_experiment_1_and_3_emmeans_summary.csv")

  cat(
    "
  ===============================================================================
  Experiment 1 & 3 marginal breach probabilities by gender
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )
  capture.output(
    summary(emmeans_breaching_by_gender_experiment_1_and_3),
    file = "results/model_summaries.txt",
    append = TRUE
  )

  # ===========================================================================
  broom.mixed::tidy(contrast_type_of_interaction_experiment_1_and_3, effects = "fixed") |>
    data.table::fwrite("results/contrast_type_of_interaction_experiment_1_and_3.csv")

  cat(
    "
  ===============================================================================
  Experiment 1 & 3 contrast type of interaction experiment 1 and 3
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )
  capture.output(
    summary(contrast_type_of_interaction_experiment_1_and_3),
    file = "results/model_summaries.txt",
    append = TRUE
  )
emmeans_breaching_experiment_1_and_3_compare_human_sign_gaze

  # ===========================================================================
  broom.mixed::tidy(emmeans_breaching_experiment_1_and_3_compare_human_sign_gaze, effects = "fixed") |>
    data.table::fwrite("results/emmeans_compare_human_sign_gaze_experiment_1_and_3.csv")

  cat(
    "
  ===============================================================================
  Experiment 1 & 3 compare gaze in human & sign condition
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )
  capture.output(
    summary(emmeans_breaching_experiment_1_and_3_compare_human_sign_gaze),
    file = "results/model_summaries.txt",
    append = TRUE
  )

  # ===========================================================================
  broom.mixed::tidy(emmeans_breaching_experiment_1_and_3_gaze_type_of_interaction_interaction_odds, effects = "fixed") |>
    data.table::fwrite("results/gaze_type_of_interaction_interaction_odds_experiment_1_and_3.csv")

  cat(
    "
  ===============================================================================
  Experiment 1 & 3 contrast type of interaction and gaze
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )
  capture.output(
    summary(emmeans_breaching_experiment_1_and_3_gaze_type_of_interaction_interaction_odds),
    file = "results/model_summaries.txt",
    append = TRUE
  )
}

write_experiment_4_results_to_file <- function(
  model_breaching_experiment_4,
  model_4_condition_effect,
  contrast_condition_experiment_4,
  model_orients_away_distance_experiment_4
) {

  # ===========================================================================
  broom.mixed::tidy(model_breaching_experiment_4, effects = "fixed") |>
    data.table::fwrite("results/breaching_experiment_4_brm_summary.csv")

  cat(
    "
  ===============================================================================
  Experiment 4 breach probabilities
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )

  capture.output(
    summary(model_breaching_experiment_4),
    file = "results/model_summaries.txt",
    append = TRUE
  )

  # ===========================================================================
  model_4_condition_effect |>
    data.table::fwrite("results/breaching_experiment_4_effect.csv")

  cat(
    "
  ===============================================================================
  Experiment 4 breach effect
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )

  capture.output(
    model_4_condition_effect,
    file = "results/model_summaries.txt",
    append = TRUE
  )

  # ===========================================================================
  broom.mixed::tidy(contrast_condition_experiment_4, effects = "fixed") |>
    data.table::fwrite("results/breaching_experiment_4_contrast.csv")

  cat(
    "
  ===============================================================================
  Experiment 4 contrast breach probabilities
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )

  capture.output(
    contrast_condition_experiment_4,
    file = "results/model_summaries.txt",
    append = TRUE
  )


  # ===========================================================================
  broom.mixed::tidy(model_orients_away_distance_experiment_4, effects = "fixed") |>
    data.table::fwrite("results/orients_away_experiment_4_lmer_summary.csv")

  cat(
    "
  ===============================================================================
  Experiment 4 orients away gender effects
  ===============================================================================\n",
    file = "results/model_summaries.txt",
    append = TRUE
  )

  capture.output(
    model_orients_away_distance_experiment_4,
    file = "results/model_summaries.txt",
    append = TRUE
  )
  
}
