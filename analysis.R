# =============================================================================
# Title: Invisible Wall
# File: analysis.R
# Author: Jack Terwilliger (University of California, San Diego)
# Date Created: 2025-10-08
# Last Modified: 2025-10-08
# Description:
#   Statistical analysis & (raw) figures.
#
# Data Sources:
#   data/
#   ├── experiment_1.csv
#   ├── experiment_2.csv
#   ├── experiment_3.csv
#   ├── experiment_4.csv
#   └── environment_shapes
#       ├── mural_shape.csv
#       └── patio_shape.csv
#
# Internal Dependencies:
#   src/
#   ├── plotting.R
#   ├── preprocessing.R
#   └── saveresults.R
#
# External Dependencies:
#   - bridgesampling
#   - brms
#   - broom.mixed
#   - data.table
#   - dplyr
#   - forcats
#   - ggbeeswarm
#   - ggplot2
#   - grid
#   - emmeans
#   - lme4
#   - lmerTest
#   - lubridate
#   - optimx
#   - patchwork
#   - png
#   - svglite
#
# =============================================================================

library(bridgesampling)
library(brms)
library(data.table)
library(dplyr)
library(emmeans)
library(forcats)
library(grid)
library(lme4)
library(lmerTest)
library(lubridate)
library(optimx)
library(png)

source("src/plotting.R")
source("src/preprocessing.R")
source("src/saveresults.R")

# =============================================================================
# Experiment 1
#
# Analyze breaching probabilities
#   1. load data
#   2. fit a binomial glmm to model breaches
#   3. estimate marginal means
#   4. plot estimated marginal breach probabilities
#   5. save model results
# =============================================================================

df_experiment_1_raw <- data.table::fread("data/experiment_1.csv") |>
  mutate(
    distance              = fct_relevel(distance, "5 ft"),
    location              = fct_relevel(location, "PC"),
    transportation        = fct_relevel(transportation, "Walking"),
    actor_gender          = fct_relevel(actor_gender, "MM"),
    pedestrian_gender     = fct_relevel(pedestrian_gender, "Man"),
    date                  = as.Date(date, "%y-%m-%d")
  )

df_experiment_1 <- df_experiment_1_raw |>
  dplyr::filter(
    outcome != "Within Bounds No Divergence",
    pedestrian_gender != "Other/Uncertain"
  )

model_breaching_experiment_1 <- glmer(
  breach ~ gaze * talk + distance + pedestrian_gender * actor_gender +
           group_lead_pedestrian +
           transportation + (1 | location : date),
  df_experiment_1,
  family = binomial,
  control = glmerControl(optimizer = "bobyqa")
)

model_breaching_experiment_1_full_random_effects <- glmer(
  breach ~ gaze * talk + distance + pedestrian_gender * actor_gender +
           group_lead_pedestrian +
           transportation + (1 | location / date),
  df_experiment_1,
  family = binomial,
  control = glmerControl(optimizer = "bobyqa")
)

model_breaching_experiment_1_simple <- glm(
  breach ~ gaze * talk + distance + pedestrian_gender * actor_gender +
           group_lead_pedestrian +
           transportation,
  df_experiment_1,
  family = binomial
)

model_1_log_likelihood_ratio_test <- anova(
  model_breaching_experiment_1,
  model_breaching_experiment_1_full_random_effects,
  model_breaching_experiment_1_simple
)

figure_2_c <- generate_figure_experiment_1_emmeans(
  model_breaching_experiment_1, df_experiment_1,
  "figures/output/figure_2_c_experiment_1_emmean_breaching_probabilities_gaze_distance_talk"
)

emmeans_breaching_experiment_1 <- emmeans(
  model_breaching_experiment_1,
  ~ distance * gaze * talk,
  at = list(
    transportation = "Walking"
  ),
  type = "response"
)

pairs(emmeans_breaching_experiment_1)

emmeans_breaching_experiment_1_distance_contrast <- pairs(
  emmeans(
    model_breaching_experiment_1,
    ~ distance,
    type = "response"
  )
)

# emmeans will spit out a well intentioned warning
# "NOTE: Results may be misleading due to involvement in interaction"
# We can ignore that here.
# (1) We actually are interested in the effect of actor gender: the average effect.
#     We want to aggregated over pedestrian gender.
# (2) The interaction is effectively 0.
emmeans_breaching_experiment_1_actor_gender_contrast <- contrast(
  emmeans(
    model_breaching_experiment_1,
    ~ actor_gender,
    type = "response"
  ),
  method = list(
    "Both women vs. Both men" = c(-1, 1, 0)
  )
)

  pairs(emmeans(
    model_breaching_experiment_1,
    ~ pedestrian_gender,
    type = "response"
  ))

  pairs(emmeans(
    model_breaching_experiment_1,
    ~ pedestrian_gender * actor_gender,
    type = "response",
    at = list(actor_gender = c("WW", "MM"))
  ))

emmeans_breaching_experiment_1_gaze_talk_interaction_contrast <- contrast(
  emmeans(
    model_breaching_experiment_1,
    ~ gaze*talk,
    type = "response"
  ),
  method = list(
    "Gaze AND Talk vs. Just Gaze" = c(0, -1, 0, 1),
    "Gaze AND Talk vs. Just Talk" = c(0, 0, -1, 1),
    "Gaze AND Talk vs. Nothing" = c(-1, 0, 0, 1)
  )
)

emmeans_breaching_experiment_1_gaze_talk_interaction_odds <- contrast(
  emmeans(
    model_breaching_experiment_1,
    ~ gaze * talk,
    type = "response"
  ),
  interaction = "pairwise"
)

write_experiment_1_results_to_file(
  model_breaching_experiment_1,
  emmeans_breaching_experiment_1,
  emmeans_breaching_experiment_1_distance_contrast,
  emmeans_breaching_experiment_1_actor_gender_contrast,
  emmeans_breaching_experiment_1_gaze_talk_interaction_contrast,
  emmeans_breaching_experiment_1_gaze_talk_interaction_odds
)

# =============================================================================
# Experiment 2 Part A
#
# Analyze breaching probabilities
#   1. load trajectory data
#   2. preprocess relevant crowd behavior occuring 5 seconds
#      before each pedestrian either breached/avoided our
#      research actors
#   4. fit a binomial glmm to model breaches
#   5. estimate marginal means
#   6. plot estimated marginal breach probabilities
#
# =============================================================================

EXPERIMENT_2_WALL_X_COORD_CM = -280
EXPERIMENT_2_TIME_WINDOW_FOR_BREACH_CONTAGION_FRAMES = 30 * 5

df_experiment_2_trajectory <- left_join(
  data.table::fread("data/experiment_2.csv"),
  data.table::fread("data/experiment_2_trajectory.csv"),
  by = c("video", "person_id")
)

df_experiment_2_row_when_pedestrian_passes_wall <- get_row_when_pedestrian_passes_wall(
  EXPERIMENT_2_WALL_X_COORD_CM, df_experiment_2_trajectory
)

df_experiment_2_crowd_aggregations <- get_crowd_aggregations(
  EXPERIMENT_2_WALL_X_COORD_CM, EXPERIMENT_2_TIME_WINDOW_FOR_BREACH_CONTAGION_FRAMES,
  df_experiment_2_trajectory, df_experiment_2_row_when_pedestrian_passes_wall
)

df_experiment_2 <- data.table::fread("data/experiment_2.csv") |>
  mutate(video = as.character(video)) |>
  left_join(
    df_experiment_2_row_when_pedestrian_passes_wall |>
      select(-c(pedestrian_passes_wall_area, breach)) |>
      mutate(video = as.character(video)),
      by = c("video", "person_id")
  ) |>
  left_join(
    df_experiment_2_crowd_aggregations |>
      mutate(video = as.character(video)),
    by = c("video", "person_id")
  ) |>
  mutate(
    pedestrian_gender             = fct_relevel(pedestrian_gender, "Man"),
    body_orientation              = fct_relevel(body_orientation, "Baseline"),
    pedestrian_direction          = fct_relevel(pedestrian_direction, "Left"),
    entry_location                = fct_relevel(entry_location, "top"),
    exit_location                 = fct_relevel(exit_location, "top"),
    transportation                = fct_relevel(transportation, "Walking"),
    outerside_of_pedestrian_group = if_else(is.na(outerside_of_pedestrian_group), 0, outerside_of_pedestrian_group),
    crowd_size                    = as.numeric(if_else(is.na(crowd_size), 0, crowd_size)),
    crowd_size                    = sqrt(crowd_size),
    breach_before                 = as.numeric(if_else(is.na(breach_before), 0, breach_before)),
    breach_before                 = sqrt(breach_before),
    mid_min10                     = mid_minute %/% 10
  )

df_experiment_2_passes_wall_area <- df_experiment_2 |> filter(pedestrian_passes_wall_area == 1)

model_breaching_experiment_2 <- glmer(
  breach ~ body_orientation*pedestrian_direction + pedestrian_gender +
           pedestrian_headphones + pedestrian_on_phone +
           transportation + motor_powered +
           pedestrian_group_size + outerside_of_pedestrian_group + lead_pedestrian +
           entry_location + exit_location + breach_before + crowd_size +
           (1 | video : mid_min10),
  df_experiment_2_passes_wall_area,
  family = binomial,
  control = glmerControl(optimizer = "bobyqa")
)

model_breaching_experiment_2_full_random_effects <- glmer(
  breach ~ body_orientation*pedestrian_direction + pedestrian_gender +
           pedestrian_headphones + pedestrian_on_phone +
           transportation + motor_powered +
           pedestrian_group_size + outerside_of_pedestrian_group + lead_pedestrian +
           entry_location + exit_location + breach_before + crowd_size +
           (1 | mid_min10 / video),
  df_experiment_2_passes_wall_area,
  family = binomial,
  control = glmerControl(optimizer = "bobyqa")
)

model_breaching_experiment_2_more_random_effects <- glmer(
  breach ~ body_orientation*pedestrian_direction + pedestrian_gender +
           pedestrian_headphones + pedestrian_on_phone +
           transportation + motor_powered +
           pedestrian_group_size + outerside_of_pedestrian_group + lead_pedestrian +
           entry_location + exit_location + breach_before + crowd_size +
           (1 | mid_min10) + (1 | video),
  df_experiment_2_passes_wall_area,
  family = binomial,
  control = glmerControl(optimizer = "bobyqa")
)

model_breaching_experiment_2_simple <- glm(
  breach ~ body_orientation*pedestrian_direction + pedestrian_gender +
           pedestrian_headphones + pedestrian_on_phone +
           transportation + motor_powered +
           pedestrian_group_size + outerside_of_pedestrian_group +
           entry_location + exit_location + breach_before + crowd_size,
  df_experiment_2_passes_wall_area,
  family = binomial
)

model_2_log_likelihood_ratio_test <- anova(
  model_breaching_experiment_2,
  model_breaching_experiment_2_simple,
  model_breaching_experiment_2_full_random_effects,
  model_breaching_experiment_2_more_random_effects
)

figure_2_d <- generate_figure_experiment_2_emmeans(
  model_breaching_experiment_2, df_experiment_2_passes_wall_area,
  "figures/output/figure_2_d_experiment_2_emmean_breaching_probabilities_body_orientation"
)

emmeans_breaching_experiment_2 <- emmeans(
  model_breaching_experiment_2,
  ~ pedestrian_direction * body_orientation,
  at = list(
    transportation = "Walking",
    entry_location = "top",
    exit_location = "top",
    crowd_size = 0,
    breach_before = 0,
    motor_powered = FALSE
  ),
  type = "response"
)

# emmeans will spit out a well intentioned warning
# "NOTE: Results may be misleading due to involvement in interaction"
# We can ignore that here.
# (1) We are actually interested in the average effect of body orientations.
#     We want to aggregated over pedestrian gender.
# (2) We already report and account for the effect above.
contrast_body_orientation_experiment_2 <- contrast(
  emmeans(
    model_breaching_experiment_2,
    ~ body_orientation,
    type = "response"
  ),
  method = list(
    "FaceToFace vs. 45OffsetFacing" = c(0, 0, 1, -1),
    "FaceToFace vs. BackToBack" = c(0, -1, 1, 0),
    "FaceToFace vs Baseline" = c(-1, 0, 1, 0)
  ),
)

contrast_phone_experiment_2 <- pairs(
  emmeans(
    model_breaching_experiment_2,
    ~ pedestrian_on_phone,
    type = "response"
  ),
  reverse = TRUE
)

# =============================================================================
# Experiment 2 Part B
#
# Plot pedestrian trajectories
#   1. load trajectory data
#   2. load map of physical environment
#   4. plot trajectories on map of environment by body orientation condition
#   5. filter only data from one illustrative example of breaching contagion
#   6. visualize illustrative example by plotting trajectories on environment
#   7. visualize modeled estimated marginal breaching rate as function of
#      how many pedestrians have breached 5 seconds prior and the crowd size
#
# =============================================================================

df_experiment_2_trajectory <- left_join(
  data.table::fread("data/experiment_2.csv"),
  data.table::fread("data/experiment_2_trajectory.csv"),
  by = c("video", "person_id")
)

df_mural_shape <- data.table::fread("data/environment_shapes/mural_shape.csv")

figure_2_e <- generate_figure_experiment_2_trajectories(
  df_experiment_2_trajectory,
  df_mural_shape,
  "figures/output/figure_2_e_experiment_2_trajectories"
)

contagion_example_pedestrians <- data.table::fread("data/misc/contagion_example_pedestrians.csv")$person_id

df_experiment_2_trajectory_contagion_case_study <- df_experiment_2_trajectory |>
  dplyr::filter(pedestrian_passes_wall_area == 1) |>
  dplyr::filter(video == "2023-12-07") |>
  dplyr::filter(person_id %in% contagion_example_pedestrians) |>
  dplyr::group_by(video, person_id) |>
  dplyr::mutate(
    video = as.character(video),
    max_sync_frame = max(sync_frame)
  ) |>
  dplyr::ungroup() |>
  dplyr::left_join(
    df_experiment_2_row_when_pedestrian_passes_wall |>
      mutate(video = as.character(video)) |>
      select(video, person_id, pass_frame),
    by = c("video", "person_id")
  ) |>
  dplyr::mutate(
    person_id = forcats::fct_shuffle(as.factor(person_id)),
    video = forcats::fct_shuffle(as.factor(video)),
    before_trigger = (pass_frame <= 41680) | person_id %in% c(121, 123, 127),
    trigger_people = dplyr::case_when(
      person_id %in% c(121, 123, 127) ~ "t",
      person_id == 147 ~ "o",
      .default = "f"
    )
  ) |>
  dplyr::filter(
    (before_trigger & sync_frame < 41680 & sync_frame < max_sync_frame) |
    (!before_trigger & sync_frame < 42290)
  )

contrast_breach_before_experiment_2 <- pairs(
  emmeans(
    model_breaching_experiment_2,
    ~ breach_before,
    type = "response"
  ),
  reverse=TRUE
)

figure_5_b_and_supp <- generate_figure_experiment_2_collective_breaching_trajectories(
  EXPERIMENT_2_TIME_WINDOW_FOR_BREACH_CONTAGION_FRAMES,
  df_experiment_2,
  df_experiment_2_trajectory_contagion_case_study,
  df_mural_shape,
  contagion_example_pedestrians,
  model_breaching_experiment_2,
  "figures/output/figure_5"
)

write_experiment_2_results_to_file(
  model_breaching_experiment_2,
  emmeans_breaching_experiment_2,
  contrast_body_orientation_experiment_2,
  contrast_breach_before_experiment_2
)

# =============================================================================
# Experiment 3
#
# Analyze breaching probabilities
#   1. load data from experiment 3
#   2. combine it with data from experiment 1
#   3. fit a binomial glmm to model breaches
#   4. estimate marginal means
#   5. plot estimated marginal breach probabilities
#   6. save model results
# =============================================================================

df_experiment_3_raw <- data.table::fread("data/experiment_3.csv") |>
  mutate(
    distance              = fct_relevel(distance, "5 ft"),
    location              = fct_relevel(location, "PC"),
    type_of_interaction   = fct_relevel(type_of_interaction, "Mural"),
    transportation        = fct_relevel(transportation, "Walking"),
    pedestrian_gender     = fct_relevel(pedestrian_gender, "Man"),
    actor_gender          = fct_relevel(actor_gender, "M"),
    date                  = as.Date(date, "%y-%m-%d")
  )

df_experiment_3 <- df_experiment_3_raw |>
  dplyr::filter(
    outcome != "Within Bounds No Divergence",
    pedestrian_gender != "Other/Uncertain"
  )

model_breaching_experiment_3 <- glmer(
  breach ~ type_of_interaction * gaze + distance + pedestrian_gender * actor_gender +
           group_lead_pedestrian +
           transportation + (1 | location : date),
  data = df_experiment_3,
  family = binomial,
  control = glmerControl(optimizer = "bobyqa")
)

model_breaching_experiment_3_simple <- glm(
  breach ~ type_of_interaction * gaze + distance + pedestrian_gender * actor_gender +
           group_lead_pedestrian +
           transportation,
  data = df_experiment_3,
  family = binomial
)

model_3_log_likelihood_ratio_test <- anova(
  model_breaching_experiment_3,
  model_breaching_experiment_3_simple
)

emmeans_breaching_experiment_3 <- emmeans(
  model_breaching_experiment_3,
  ~ gaze * type_of_interaction,
  at = list(
    transportation = "Walking",
    talk = FALSE,
    distance = "5 ft"
  ),
  type = "response"
)

# emmeans will spit out a well intentioned warning
# "NOTE: Results may be misleading due to involvement in interaction"
# We can ignore that here.
# (1) We actually are interested in the effect of actor gender: the average effect.
#     We want to aggregated over pedestrian gender.
# (2) The interaction is effectively 0.
emmeans_breaching_experiment_3_actor_gender_contrast <- contrast(
  emmeans(
    model_breaching_experiment_3,
    ~ actor_gender,
    type = "response"
  ),
  method = list(
    "Woman vs. Man" = c(-1, 1)
  )
)

df_experiment_1_and_3 <- bind_rows(
    df_experiment_1 |>
      mutate(
        type_of_interaction = "Human",
        actor_gender = if_else(actor_gender == "WW", "W", "M")
      ),
    df_experiment_3 |>
      mutate(talk = FALSE)
  ) |>
  mutate(
    distance              = fct_relevel(distance, "5 ft"),
    location              = fct_relevel(location, "PC"),
    type_of_interaction   = fct_relevel(type_of_interaction, "Human"),
    transportation        = fct_relevel(transportation, "Walking"),
    pedestrian_gender     = fct_relevel(pedestrian_gender, "Man"),
    actor_gender          = fct_relevel(actor_gender, "M"),
    date                  = as.Date(date, "%y-%m-%d")
  )

model_breaching_experiment_1_and_3 <- glmer(
  breach ~ type_of_interaction * gaze + talk + distance + pedestrian_gender * actor_gender +
           group_lead_pedestrian +
           transportation + (1 | location : date),
  data = df_experiment_1_and_3,
  family = binomial,
  control = glmerControl(optimizer = "bobyqa")
)

model_breaching_experiment_1_and_3_simple <- glm(
  breach ~ type_of_interaction * gaze + talk + distance + pedestrian_gender * actor_gender +
           group_lead_pedestrian +
           transportation,
  data = df_experiment_1_and_3,
  family = binomial
)

model_1_and_3_log_likelihood_ratio_test <- anova(
  model_breaching_experiment_1_and_3,
  model_breaching_experiment_1_and_3_simple
)

emmeans_breaching_experiment_1_and_3 <- emmeans(
  model_breaching_experiment_1_and_3,
  ~ gaze * type_of_interaction,
  at = list(
    transportation = "Walking",
    talk = FALSE,
    distance = "5 ft"
  ),
  type = "response"
)

emmeans_breaching_experiment_1_and_3_gaze_type_of_interaction_interaction_odds <- contrast(
  emmeans_breaching_experiment_1_and_3,
  interaction = "pairwise"
)

emmeans_breaching_experiment_1_and_3_compare_human_sign_gaze <- contrast(
  emmeans_breaching_experiment_1_and_3,
  method = list(
    "Sign & Gaze vs. Human & Gaze" = c(0, -1, 0, 0, 0, 1),
    "Sign & no Gaze vs. Human & no Gaze" = c(-1, 0, 0, 0, 1, 0)
  )
)

# emmeans will spit out a well intentioned warning
# "NOTE: Results may be misleading due to involvement in interaction"
# We can ignore that here.
# (1) Without inspecting the interaction, this one is actually quite misleading.
#     There is no statististical difference between sign and human actors gaze.
# (2) We do report the interaction and discuss the interaction in the paper.
contrast_type_of_interaction_experiment_1_and_3 <- contrast(
  emmeans(
    model_breaching_experiment_1_and_3,
    ~ type_of_interaction,
    type = "response"
  ),
  method = list(
    "Sign vs. Human" = c(-1, 0, 1),
    "Mural vs. Human" = c(-1, 1, 0)
  )
)

figure_3_b <- generate_figure_experiment_1_and_3_emmeans(
  model_breaching_experiment_1_and_3, df_experiment_1_and_3,
  "figures/output/figure_3_b_experiment_3_emmean_breaching_probabilities_type_of_interaction"
)

emmeans_breaching_by_gender_experiment_1_and_3 <- emmeans(
  model_breaching_experiment_1_and_3,
  ~ pedestrian_gender * actor_gender,
  type = "response"
)

# emmeans will spit out a well intentioned warning
# "NOTE: Results may be misleading due to involvement in interaction"
# We can ignore that here.
# (1) We actually are interested in the effect of actor gender: the average effect.
#     We want to aggregated over pedestrian gender.
# (2) The interaction is effectively 0.
emmeans_breaching_experiment_1_and_3_actor_gender_contrast <- contrast(
  emmeans(
    model_breaching_experiment_1_and_3,
    ~ actor_gender,
    type = "response"
  ),
  method = list(
    "Woman vs. Man" = c(-1, 1)
  )
)

write_experiment_3_results_to_file(
  model_breaching_experiment_3,
  emmeans_breaching_experiment_3,
  model_breaching_experiment_1_and_3,
  emmeans_breaching_experiment_1_and_3,
  emmeans_breaching_by_gender_experiment_1_and_3,
  contrast_type_of_interaction_experiment_1_and_3,
  emmeans_breaching_experiment_1_and_3_compare_human_sign_gaze,
  emmeans_breaching_experiment_1_and_3_gaze_type_of_interaction_interaction_odds
)

# =============================================================================
# Experiment 4
# Breaching Probabilities
# =============================================================================

df_experiment_4_trajectory <- data.table::fread("data/experiment_4_trajectory.csv") |>
  dplyr::mutate(
    proximity_to_oc = sqrt((187 - rts_x)^2 + (20.4 - rts_y)^2)
  )

df_experiment_4_trajectory_turning_point <- df_experiment_4_trajectory |>
  filter(
    (participant_id != 68 | participant_id != 87) |
    (participant_id == 68 & sync_frame >= 6830) |
    (participant_id == 87 & sync_frame >= 16019)
  ) |>
  filter(rts_orients_away == 1 & breach != 1) |>
  group_by(participant_id) |>
  slice_tail(n = 1) |>
  ungroup()

df_cogsci_building_patio_shape <- data.table::fread("data/environment_shapes/patio_shape.csv")

df_experiment_4 <- data.table::fread("data/experiment_4.csv")

# Priors needed to wrangle the model to deal with ceiling effects
model_breaching_experiment_4_priors <- c(
  prior(normal(4, 1), class = "Intercept"),
  prior(normal(0, 1), class = "b", coef = "conditionChairs"),
  prior(normal(-5.5, 1), class = "b", coef = "conditionHumans")
)

model_breaching_experiment_4 <- brm(
  formula = breach ~ condition + pedestrian_gender + (1 | date),
  data = df_experiment_4,
  family = bernoulli(link = "logit"),
  chains = 4,
  cores = 4,
  iter = 10000,
  prior = prior(normal(0, 2), class = "b"),
  control = list(adapt_delta = 0.99, max_treedepth = 20),
  save_pars = save_pars(all = TRUE)
)

model_breaching_experiment_4_simple <- brm(
  formula = breach ~ condition + pedestrian_gender,
  data = df_experiment_4,
  family = bernoulli(link = "logit"),
  chains = 4,
  cores = 4,
  iter = 10000,
  prior = prior(normal(0, 2), class = "b"),
  control = list(adapt_delta = 0.99, max_treedepth = 20),
  save_pars = save_pars(all = TRUE)
)

model_4_bayes_factor_test <- bayes_factor(
  model_breaching_experiment_4,
  model_breaching_experiment_4_simple
)

model_4_condition_effect <- hypothesis(
    model_breaching_experiment_4,
    "conditionHumans - conditionChairs < 0"
  )$hypothesis |>
  as_tibble()

emmeans_breaching_experiment_4 <- emmeans(
  model_breaching_experiment_4,
  ~ condition,
  at = list(),
  type = "response"
)

contrast_condition_experiment_4 <- contrast(
  emmeans_breaching_experiment_4,
  method = list(
    "Human vs. Chairs" = c(0, 1, -1)
  )
)

df_experiment_4_orients_away <- df_experiment_4_trajectory |>
  filter(rts_orients_away == 1 & condition == "Humans")

model_orients_away_distance_experiment_4 <- lmer(
  formula = rts_distance_to_wall_middle ~ pedestrian_gender + (1 | date),
  data = df_experiment_4_orients_away
)

model_orients_away_distance_experiment_4_simple <- lm(
  formula = rts_distance_to_wall_middle ~ pedestrian_gender,
  data = df_experiment_4_orients_away
)

model_1_log_likelihood_ratio_test <- anova(
  model_orients_away_distance_experiment_4,
  model_orients_away_distance_experiment_4_simple
)

emmeans(
  model_orients_away_distance_experiment_4_simple,
  ~ pedestrian_gender
)

figure_4_b <- generate_figure_experiment_4_trajectories(
  df_experiment_4_trajectory,
  df_experiment_4_trajectory_turning_point,
  df_cogsci_building_patio_shape,
  "figures/output/experiment_4_chairs_and_human_trajctories"
)

figure_s2_b <- generate_figure_experiment_4_trajectories_all(
  df_experiment_4_trajectory,
  df_experiment_4_trajectory_turning_point,
  df_cogsci_building_patio_shape,
  "figures/output/supplementary_experiment_4_trajectories"
)

write_experiment_4_results_to_file(
  model_orients_away_distance_experiment_4_simple,
  model_4_condition_effect,
  contrast_condition_experiment_4,
  model_orients_away_distance_experiment_4
)

# =============================================================================
# Descriptive Statistics
# =============================================================================

data.frame(
  size = c(
    nrow(df_experiment_1_raw), nrow(df_experiment_1),
    nrow(df_experiment_2), nrow(df_experiment_2_passes_wall_area),
    nrow(df_experiment_3_raw), nrow(df_experiment_3),
    nrow(df_experiment_4), nrow(df_experiment_4)),
  what = c(
    "total_experiment_1", "modeled_experiment_1",
    "total_experiment_2", "modeled_experiment_2",
    "total_experiment_3", "modeled_experiment_3",
    "total_experiment_4", "modeled_experiment_4")
) |>
  data.table::fwrite("results/descriptive_stats_experiment_size.csv")

size_modeled_1 <- df_experiment_1 |>
  group_by(pedestrian_gender) |>
  summarise(n = n(), .groups = "drop") %>%
  bind_rows(summarise(., pedestrian_gender = "All", n = sum(n))) |>
  mutate(experiment=1)

size_modeled_2 <- df_experiment_2 |>
  group_by(pedestrian_gender) |>
  summarise(n = n(), .groups = "drop") %>%
  bind_rows(summarise(., pedestrian_gender = "All", n = sum(n))) |>
  mutate(experiment=2)

size_modeled_3 <- df_experiment_2_passes_wall_area |>
  group_by(pedestrian_gender) |>
  summarise(n = n(), .groups = "drop") %>%
  bind_rows(summarise(., pedestrian_gender = "All", n = sum(n))) |>
  mutate(experiment=3)

size_modeled_4 <- df_experiment_4 |>
  group_by(pedestrian_gender) |>
  summarise(n = n(), .groups = "drop") %>%
  bind_rows(summarise(., pedestrian_gender = "All", n = sum(n))) |>
  mutate(experiment=4)

bind_rows(size_modeled_1, size_modeled_2, size_modeled_3, size_modeled_4) |>
  data.table::fwrite("results/descriptive_stats_modeled_size.csv")

condition_size_experiment_1 <- df_experiment_1 |>
  group_by(gaze, distance, talk) |>
  summarise(n = n(), .groups = "drop") |>
  mutate(experiment=1)

condition_size_experiment_2 <- df_experiment_2_passes_wall_area |>
  group_by(body_orientation) |>
  summarise(n = n(), .groups = "drop") |>
  mutate(experiment=2)

condition_size_experiment_3 <- df_experiment_3 |>
  group_by(gaze, type_of_interaction) |>
  summarise(n = n(), .groups = "drop") |>
  mutate(experiment=3)

condition_size_experiment_4 <- df_experiment_4 |>
  group_by(condition, pedestrian_gender) |>
  summarise(n = n(), .groups = "drop") |>
  mutate(experiment=4)

bind_rows(
    condition_size_experiment_1, condition_size_experiment_2,
    condition_size_experiment_3, condition_size_experiment_4
  ) |>
  data.table::fwrite("results/descriptive_stats_modeled_size_by_condition.csv")

# =============================================================================
# Paper figures
# =============================================================================
img1 <- rasterGrob(png::readPNG("figures/placeholders/156x117.png"), interpolate = TRUE)
img2 <- rasterGrob(png::readPNG("figures/placeholders/156x117.png"), interpolate = TRUE)

figure_2_a <- ggplot() +
  # First image on the left (x from 0 to 1)
  annotation_custom(img1, xmin = 0, xmax = 1, ymin = 0, ymax = 1) +
  # Second image on the right (x from 1 to 2)
  annotation_custom(img2, xmin = 1, xmax = 2, ymin = 0, ymax = 1) +
  coord_cartesian(xlim = c(0, 2), ylim = c(0, 1), expand = FALSE) +
  theme_void()

figure_2 <-generate_figure_2(
  figure_2_a, figure_2_a,
  figure_2_c, figure_2_d,
  figure_3_e,
  "figures/output/figure_2"
)

figure_3 <- generate_figure_3(
  figure_2_a,
  figure_3_b,
  "figures/output/figure_3"
)

img1 <- rasterGrob(png::readPNG("figures/placeholders/142x106.png"), interpolate = TRUE)
img2 <- rasterGrob(png::readPNG("figures/placeholders/142x106.png"), interpolate = TRUE)
img3 <- rasterGrob(png::readPNG("figures/placeholders/142x106.png"), interpolate = TRUE)

figure_4_a <- ggplot() +
  annotation_custom(img2, xmin = 0, xmax = 1, ymin = 0, ymax = 1) +
  annotation_custom(img3, xmin = 1, xmax = 2, ymin = 0, ymax = 1) +
  coord_cartesian(xlim = c(0, 2), ylim = c(0, 1), expand = FALSE) +
  theme_void()

figure_4 <- generate_figure_4(
  figure_4_a,
  figure_4_b,
  "figures/output/figure_4"
)

figure_s2_a <- ggplot() +
  annotation_custom(img1, xmin = 0, xmax = 1, ymin = 0, ymax = 1) +
  annotation_custom(img2, xmin = 1, xmax = 2, ymin = 0, ymax = 1) +
  annotation_custom(img3, xmin = 2, xmax = 3, ymin = 0, ymax = 1) +
  coord_cartesian(xlim = c(0, 3), ylim = c(0, 1), expand = FALSE) +
  theme_void()

figure_s2_c <- generate_figure_experiment_4_orients_away_violin(
  df_experiment_4_orients_away,
  "figures/output/supplementary_figure_3_experiment_4_orients_away"
)

figure_s2 <- generate_figure_s2(
  figure_s2_a,
  figure_s2_b,
  figure_s2_c,
  "figures/output/figure_s2"
)


img1 <- rasterGrob(png::readPNG("figures/placeholders/206x206.png"), interpolate = TRUE)
img2 <- rasterGrob(png::readPNG("figures/placeholders/206x206.png"), interpolate = TRUE)
img3 <- rasterGrob(png::readPNG("figures/placeholders/206x206.png"), interpolate = TRUE)

figure_5_a <- ggplot() +
  annotation_custom(img1, xmin = 0, xmax = 1, ymin = 0, ymax = 1) +
  annotation_custom(img2, xmin = 1, xmax = 2, ymin = 0, ymax = 1) +
  annotation_custom(img3, xmin = 2, xmax = 3, ymin = 0, ymax = 1) +
  coord_cartesian(xlim = c(0, 3), ylim = c(0, 1), expand = FALSE) +
  theme_void()

figures_5 <- generate_figure_5(
  figure_5_a,
  figure_5_b_and_supp[["top"]],
  "figures/output/figure_5"
)

figure_s4 <- generate_figure_s4(
  figure_5_a,
  figure_5_b_and_supp[["top"]],
  figure_5_b_and_supp[["bottom"]],
  "figures/output/figure_s4"
)

# =============================================================================
# Methods and Materials
# =============================================================================

# exclusions
df_experiment_1_raw |>
  summarise(
    ex_outcome = sum(outcome == "Within Bounds No Divergence"),
    ex_gend = sum(pedestrian_gender == "Other/Uncertain")
  )
nrow(df_experiment_1_raw) - nrow(df_experiment_1)

nrow(data.table::fread("data/experiment_2.csv")) - nrow(df_experiment_2_passes_wall_area)

df_experiment_3_raw |>
  summarise(
    ex_outcome = sum(outcome == "Within Bounds No Divergence"),
    ex_gend = sum(pedestrian_gender == "Other/Uncertain")
  )
nrow(df_experiment_3_raw) - nrow(df_experiment_3)

# =============================================================================
# Supplementary Analyses
# =============================================================================

emmeans_breaching_by_gender_experiment_1_and_3 <- emmeans(
  model_breaching_experiment_1_and_3,
  ~ pedestrian_gender * actor_gender,
  type = "response",
  at = list(
    transportation = "Walking",
    talk = FALSE,
    distance = "5 ft"
  ),
)

figure_s1 <- generate_figure_gender_breaching_probabilities(
  emmeans_breaching_by_gender_experiment_1_and_3, df_experiment_1_and_3,
  "figures/output/supplementary_figure_1_experiment_3_emmean_breaching_probabilities_by_gender"
)
