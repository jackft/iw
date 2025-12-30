# =============================================================================
# Title: Invisible Wall
# File: plotting.R
# Author: Jack Terwilliger (University of California, San Diego)
# Date Created: 2025-10-08
# Last Modified: 2025-10-08
# Description:
#   Functions and configurations for plotting figures
#
# Dependencies:
#   - broom.mixed
#   - dplyr
#   - ggbeeswarm
#   - ggplot2
#   - patchwork
#   - svglite
#
# =============================================================================

library(broom.mixed)
library(dplyr)
library(ggbeeswarm)
library(ggplot2)
library(patchwork)
library(svglite)

# =============================================================================
# Plotting Configurations
# =============================================================================

cmap_gender <- c(
  "Man" = "#01a087",
  "Woman" = "#641979",
  "MM" = "#3c5487",
  "WW" = "#e44c37",
  "M" = "#3c5487",
  "W" = "#e44c37"
)

cmap_gaze <- c(
    "gaze" = "#00a087",
    "no gaze" = "black",
      values = c("#00a087", "black"),
      labels = c("gaze", "no gaze")
)

PATIO_GROUND_COLOR = "#f6f3ec"
PATIO_GREEN_COLOR = "#1f662a"
PATIO_GARDEN_COLOR = "#876542"

MURAL_GROUND_COLOR = "#f6f3ec"
MURAL_GREEN_COLOR = "#1f662a"
MURAL_GARDEN_COLOR = "#876542"
ARROWLEN = 1/3

theme_ccl <- function(base_size = 9, base_family = "Helvetica") {
  theme_classic(base_size = base_size, base_family = base_family) %+replace%
    theme(
      # Grid and panel
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      plot.background = element_rect(fill = "white", colour = NA),
      panel.background = element_rect(fill = "white", colour = NA),

      # Facet strips
      strip.background = element_rect(
        fill = NA,
        colour = NA
      ),
      strip.text = element_text(
        family = base_family,
        face = "bold",
        size = base_size * 0.9
      ),

      plot.title = element_blank(),
      plot.subtitle = element_blank(),
      plot.caption = element_blank(),

      # Axes
      axis.title = element_text(
        family = base_family,
        size = base_size
      ),
      axis.text = element_text(
        family = base_family,
        size = base_size * 0.9
      ),
      axis.text.x = element_text(
        margin = margin(t = 5),
        vjust = 1
      ),
      axis.text.y = element_text(
        margin = margin(r = 5)
      ),

      # Legends
      legend.title = element_text(
        family = base_family,
        size = base_size
      ),
      legend.text = element_text(
        family = base_family,
        size = base_size * 0.9
      ),
      legend.background = element_blank(),
      legend.key = element_blank()
    )
}

# =============================================================================
# Plotting Functions
# =============================================================================

generate_figure_2 <- function(
  figure_2_a, figure_2_b,
  figure_2_c, figure_2_d,
  figure_3_e,
  basename
) {
  figure <- (
    free( (figure_2_a | figure_2_c) ) / # row of images
          (figure_2_b | figure_2_d)   / # row of emmeans plots
      free(figure_2_e)
  ) +
  plot_layout(heights = c(1.5, 1, 2.75)) +
  plot_annotation(tag_levels = 'A')

  ggsave(
    paste0(basename, ".png"),
    figure, dpi = 300,
    units = "in", width = 7, height = 5.25
  )

  ggplot2::ggsave(
    paste0(basename, ".svg"),
    figure,
    units = "in", width = 7, height = 5.25
  )

  return(figure)
}

generate_figure_3 <- function(
  figure_3_a,
  figure_3_b,
  basename
) {
  figure <- (
    free(figure_3_a) /
    figure_3_b
  ) +
  plot_layout(heights = c(1.7, 1)) +
  plot_annotation(tag_levels = 'A')

  ggsave(
    paste0(basename, ".png"),
    figure, dpi = 300,
    units = "in", width = 3.4, height = 2.7
  )

  ggplot2::ggsave(
    paste0(basename, ".svg"),
    figure,
    units = "in", width = 3.4, height = 2.7
  )

  return(figure)
}

generate_figure_4 <- function(
  figure_4_a,
  figure_4_b,
  basename
) {
  figure <- (
    figure_4_a /
    figure_4_b
  ) +
  plot_layout(heights = c(1.5, 2.8)) +
  plot_annotation(tag_levels = 'A')

  ggsave(
    paste0(basename, ".png"),
    figure, dpi = 300,
    units = "in", width = 3.4, height = 4
  )

  ggplot2::ggsave(
    paste0(basename, ".svg"),
    figure,
    units = "in", width = 3.4, height = 4
  )

  return(figure)
}

generate_figure_5 <- function(
  figure_5_a,
  figure_5_b,
  basename
) {
  figure <- (
    figure_5_a /
    figure_5_b
  ) +
  plot_layout(heights = c(2.25,1)) +
  plot_annotation(tag_levels = 'A')

  ggsave(
    paste0(basename, ".png"),
    figure, dpi = 300,
    units = "in", width = 7, height = 4
  )

  ggplot2::ggsave(
    paste0(basename, ".svg"),
    figure,
    units = "in", width = 7, height = 4
  )

  return(figure)
}

generate_figure_s4 <- function(
  figure_s4_a,
  figure_s4_b,
  figure_s4_c,
  basename
) {
  figure <- (
    figure_s4_a /
    figure_s4_b /
    free(figure_s4_c)
  ) +
  plot_layout(heights = c(2.25,1,1)) +
  plot_annotation(tag_levels = 'A')

  ggsave(
    paste0(basename, ".png"),
    figure, dpi = 300,
    units = "in", width = 7, height = 5.2
  )

  ggplot2::ggsave(
    paste0(basename, ".svg"),
    figure,
    units = "in", width = 7, height = 5.2
  )

  return(figure)
}

generate_figure_s2 <- function(
  figure_s2_a,
  figure_s2_b,
  figure_s2_c,
  basename
) {
  figure <- (
    (figure_s2_a /
    figure_s2_b) | (figure_s2_c + theme(legend.position = "none"))
  ) +
  plot_layout(
    heights = c(1, 1.1),
    widths  = c(6, 1)
  ) +
  plot_annotation(tag_levels = 'A')

  ggsave(
    paste0(basename, ".png"),
    figure, dpi = 300,
    units = "in", width = 7, height = 5
  )

  ggplot2::ggsave(
    paste0(basename, ".svg"),
    figure,
    units = "in", width = 7, height = 5
  )

  return(figure)
}

generate_figure_experiment_1_emmeans <- function(
  model_breaching_experiment_1,
  df_experiment_1,
  basename
) {

  emmeans_breaching_experiment_1 <- emmeans(
    model_breaching_experiment_1,
    ~ distance * gaze * talk,
    at = list(
      transportation = "Walking",
      actor_gender = c("WW", "MM")
    ),
    type = "response"
  )

  empirical_breaching_frequency_experiment_1 <- df_experiment_1 |>
    filter(
      transportation == "Walking" & actor_gender != "MW"
    ) |>
    group_by(distance, talk, gaze) |>
    summarise(estimate = mean(breach), .groups = "keep") |>
    mutate(
      variable = paste(talk, gaze, sep = ":"),
      variable = factor(
        variable,
        levels = rev(c("TRUE:TRUE", "FALSE:TRUE", "TRUE:FALSE", "FALSE:FALSE"))
      ),
      distance = factor(distance, levels = c("10 ft", "5 ft"))
    )

  figure <- emmeans_breaching_experiment_1 |>
    broom::tidy(conf.int = TRUE) |>
    mutate(
      variable = paste(talk, gaze, sep = ":"),
      variable = factor(
        variable,
        levels = rev(c("TRUE:TRUE", "FALSE:TRUE", "TRUE:FALSE", "FALSE:FALSE"))
      ),
      distance = factor(distance, levels = c("10 ft", "5 ft"))
    ) |>
    ggplot(aes(x = prob, xmin = conf.low, xmax = conf.high, y = variable, color = distance)) +
    geom_pointrange(size = 0.25, alpha = 1.0) +
    geom_point(
      data = empirical_breaching_frequency_experiment_1,
      mapping = aes(y = variable, x = estimate),
      shape = 23, color = "black", fill = "white", size = 1.5, inherit.aes = FALSE
    ) +
    scale_color_manual(
      name = "actor\ndistance",
      values = c(
        "10 ft" = "#888888",
        "5 ft" = "#000000"
        ),
    ) +
    xlim(0, 0.65) +
    scale_y_discrete(
      labels = c("FALSE:FALSE" = "Neither", "TRUE:FALSE" = "Talk", "FALSE:TRUE" = "Gaze", "TRUE:TRUE" = "Both")
    ) +
    xlab("Breach Probability") +
    theme_ccl() +
    theme(
        strip.text = element_blank(),
        strip.background = element_blank(),
        plot.margin = margin(0, 0, 0, 0, "pt"),
        axis.title.y = element_blank(),
        legend.position = c(.75, .3),
        legend.justification = c("left", "bottom"),
        legend.background = element_rect(fill = alpha("white", 1), color = "black"),
        legend.text  = element_text(size = 8),
        legend.spacing = unit(1, "mm"),
        legend.margin  = margin(0, 3, 0, 3),
        legend.key.size = unit(5, 'mm'),
        legend.title = element_text(
            size = 8,
            margin = margin(b = 0)
          )
    )

  ggsave(
    paste0(basename, ".png"),
    figure, dpi = 300, width = 3.4, height = 1.25, units="in"
  )
  ggplot2::ggsave(
    paste0(basename, ".svg"),
    figure, width = 3.4, height = 1.25, units="in"
  )
  return(figure)
}

generate_figure_experiment_2_emmeans <- function(
  model_breaching_experiment_2,
  df_experiment_2,
  basename
) {

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

  empirical_breaching_frequency_experiment_2 <- df_experiment_2 |>
    filter(
      (pedestrian_passes_wall_area == 1) &
      (entry_location == "top") &
      (exit_location == "top") &
      (transportation == "Walking") &
      (motor_powered == FALSE) &
      (breach_before == 0)
    ) |>
    group_by(body_orientation) |>
    summarise(estimate = mean(breach), num=n()) |>
    mutate(
      body_orientation=factor(body_orientation, levels=c("Baseline", "OffsetFacing", "BackToBack", "FaceToFace"))
    )

  figure <- emmeans_breaching_experiment_2 |>
    broom::tidy(conf.int = TRUE) |>
    mutate(
      body_orientation=factor(body_orientation, levels=c("Baseline", "OffsetFacing", "BackToBack", "FaceToFace")),
      pedestrian_direction=factor(
        pedestrian_direction,
        levels=c("Right", "Left")
      )
    ) |>
    ggplot(
      aes(
        x = prob, xmin = conf.low, xmax = conf.high, y = body_orientation,
        group = pedestrian_direction, color = pedestrian_direction
      )
    ) +
    geom_point(
      data = empirical_breaching_frequency_experiment_2,
      mapping = aes(y = body_orientation, x = estimate),
      shape = 23, color = "black", fill = "white", size = 1.5, inherit.aes = FALSE
    ) +
    geom_pointrange(
      position = position_dodge(width = 0.75),
      size = 0.25,
      alpha = 1.0
    ) +
    scale_color_manual(
      name = "pedestrian direction",
      values = c(
        "Left" = "#070817",
        "Right" = "#00a087"
      ),
      breaks = c("Left", "Right")
    ) +
    xlim(0, 1.0) +
    xlab("Breach Probability") +
    theme_ccl() +
    theme(
      axis.title.y = element_blank(),
      strip.text = element_blank(),
      strip.background = element_blank(),
      plot.margin = margin(0, 0, 0, 0, "pt"),
      legend.position = c(.5, .75),
      legend.justification = c("left", "bottom"),
      legend.background = element_rect(fill = alpha("white", 1), color = "black"),
      legend.text  = element_text(size = 8),
      legend.spacing = unit(1, "mm"),
      legend.margin  = margin(0, 3, 0, 3),
      legend.key.size = unit(5, 'mm'),
      legend.title = element_text(
          size = 8,
          margin = margin(b = 0)   # bottom margin in pt (default is larger)
        )
    ) +
    guides(color = guide_legend(nrow = 1))

  ggsave(
    paste0(basename, ".png"),
    figure, dpi = 300, width = 3.4, height = 2, units = "in"
  )

  ggplot2::ggsave(
    paste0(basename, ".svg"),
    figure, width = 3.4, height = 2, units = "in"
  )
  return(figure)
}

generate_figure_experiment_2_trajectories <- function(
  df_experiment_2_trajectory,
  df_mural_shape,
  basename
) {
  figure <- df_experiment_2_trajectory |>
    filter(pedestrian_passes_wall_area == 1) |>
    filter(!((video == "2023-12-01") & (person_id %in% c(44, 85, 87)))) |>
    mutate(
      person_id = forcats::fct_shuffle(as.factor(person_id)),
      video = forcats::fct_shuffle(as.factor(video)),
      body_orientation = factor(body_orientation, levels = c("FaceToFace", "BackToBack", "Baseline", "OffsetFacing")),
    ) |>
    ggplot(mapping=aes(alpha=body_orientation)) +
    geom_polygon(
      data = df_mural_shape |> filter(i == 0),
      mapping = aes(x = x, y = y, group = i),
      alpha=1,
      fill = MURAL_GROUND_COLOR
    ) +
    geom_polygon(
      data = df_mural_shape |> dplyr::filter(i == 1),
      mapping = aes(x = x, y = y, group = i),
      alpha=1, fill = "#e7d9b5"
    ) +
    geom_polygon(
      data = df_mural_shape |> dplyr::filter(i == 2),
      mapping = aes(x = x, y = y, group = i),
      alpha=1, fill = "#e7d9b5"
    ) +
    geom_polygon(
      data = df_mural_shape |> dplyr::filter(i == 3),
      mapping = aes(x = x,y = y,group = i),
      alpha=1, fill = "#e7d9b5", linewidth = 1.0, color = "black",
    ) +
    geom_path(
      aes(
        x = (rts_x / 100),
        y = (rts_y / 100),
        group = interaction(person_id, video),
        color = pedestrian_direction
      ),
      linewidth=1.5/ggplot2::.pt
    ) +
    geom_text(
      data = data.frame(
        x = c(-6),
        y = c(-0.15),
        body_orientation = c("Baseline", "FaceToFace", "OffsetFacing", "BackToBack"),
        label = c("Baseline", "Face to face", "Offset facing", "Back to back")
      ),
      mapping = aes(x, y, label = label),
      vjust = -0.5, size = 12 / 2.845, color = "#717171", family = "Helvetica", alpha = 1
    ) +
    scale_alpha_manual(
      values = c("Baseline"  = 0.09, "FaceToFace" = 0.1, "OffsetFacing" = 0.17, "BackToBack" = 0.16),
      labels = NULL
    ) +
    scale_color_manual(
      values = c(
        "Left" = "#070817",
        "Right" = "#00a087"
      ),
    ) +
    geom_segment(
      data = data.frame(
        x     = c(-2.8, -2.8, -2.8, -2.8, -2.8 + ARROWLEN/sqrt(2), -2.8 + ARROWLEN/sqrt(2)),
        y     = c(0 - ARROWLEN, 3.26 + ARROWLEN, 0 + ARROWLEN, 3.26 - ARROWLEN, 3.26 + ARROWLEN/sqrt(2), 0 - ARROWLEN/sqrt(2)),
        xend  = c(-2.8, -2.8, -2.8, -2.8, -2.8 - ARROWLEN/sqrt(2), -2.8 - ARROWLEN/sqrt(2)),
        yend  = c(0 + ARROWLEN, 3.26 - ARROWLEN, 0 - ARROWLEN, 3.26 + ARROWLEN, 3.26 - ARROWLEN/sqrt(2), 0 + ARROWLEN/sqrt(2)),
        body_orientation = c("FaceToFace", "FaceToFace", "BackToBack", "BackToBack", "OffsetFacing", "OffsetFacing")
      ),
      aes(x = x, y = y, xend = xend, yend = yend),
      arrow = arrow(length = unit(1.25, "mm")),  # arrowhead size
      color = "#e44c37",
      linewidth = 0.5, alpha = 1
    ) +
    facet_wrap(
      ~factor(body_orientation, c("Baseline", "FaceToFace", "BackToBack", "OffsetFacing")),
      ncol = 2
    ) +
    coord_fixed(ratio = 1, ylim = c(5.7, -2.0), xlim = c(-15, 11)) +
    scale_y_reverse() +
    scale_x_continuous(
      name = "feet",
      breaks = seq(-40 / 3.28, 50 / 3.28, by = 10 / 3.28) - (2.8),
      labels = function(x) round((x + 2.8) * 3.28)
    ) +
    theme_ccl() +
    theme(
      legend.position = "none",
      panel.border = element_rect(colour = "black", fill = NA, linewidth = 1),
      panel.background=element_rect(fill="#c1c1c1"),
      plot.margin = margin(0, 0, 0, 0, "in"),
      panel.spacing = unit(3, "pt"),
      strip.text = element_blank(),  # optional: remove facet titles
      axis.text.y  = element_blank(),
      axis.title.y  = element_blank(),
      axis.ticks.y = element_blank()
    )

  ggsave(
    paste0(basename, ".png"),
    figure, dpi = 300, width = 7, height = 2.75, units="in"
  )
  ggsave(
    paste0(basename, ".svg"),
    figure, width = 7, height = 2.75, units="in"
  )
  return(figure)
}

generate_figure_experiment_1_and_3_emmeans <- function(
  model_breaching_experiment_1_and_3,
  df_experiment_1_and_3,
  basename
) {

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

  empirical_breaching_frequency_experiment_1_and_3 <- df_experiment_1_and_3 |>
    filter(
      transportation == "Walking" & distance == "5 ft" & !talk
    ) |>
    group_by(type_of_interaction, gaze, location) |>
    summarise(estimate = mean(breach), .groups = "keep") |>
    group_by(type_of_interaction) |>
    summarise(estimate = mean(estimate), .groups = "keep") |>
    mutate(
      type_of_interaction = factor(type_of_interaction, levels = rev(c("Human", "Sign", "Mural")))
    )

  figure <- emmeans_breaching_experiment_1_and_3 |>
    broom::tidy(conf.int = TRUE) |>
    mutate(
      type_of_interaction = factor(type_of_interaction, levels = rev(c("Human", "Sign", "Mural"))),
      gaze = factor(gaze, levels = rev(c(TRUE, FALSE)))
    ) |>
    ggplot(aes(x = prob, xmin = conf.low, xmax = conf.high, y = type_of_interaction, color = gaze)) +
    geom_point(
      data = empirical_breaching_frequency_experiment_1_and_3,
      mapping = aes(y = type_of_interaction, x = estimate),
      shape = 23, color = "black", fill = "white", size = 1.5, inherit.aes = FALSE
    ) +
    geom_pointrange(
      position = position_dodge(width = 1.0),
      size = 0.25, alpha = 1.0,
    ) +
    xlim(0.0, 0.7) +
    xlab("Breach Probability") +
    scale_color_manual(
      name = NULL,
      values = c("TRUE"="#00a087", "FALSE"="black"),
      labels = c("TRUE"="gaze", "FALSE"="no gaze")
    ) +
    theme_ccl() +
    theme(
      axis.title.y = element_blank(),
      strip.text = element_blank(),
      strip.background = element_blank(),
      plot.margin = margin(0, 0, 0, 0, "pt"),
      legend.position = c(.5, .5),
      legend.justification = c("left", "bottom"),
      legend.background = element_rect(fill = alpha("white", 1), color = "black"),
      legend.text = element_text(size = 8),
      legend.spacing = unit(1, "mm"),
      legend.margin  = margin(0, 3, 0, 3),
      legend.key.size = unit(4, 'mm'),
      legend.title = element_text(
          size = 8,
          margin = margin(b = 0)   # bottom margin in pt (default is larger)
        )
    )

  ggsave(
    paste0(basename, ".png"),
    figure, dpi = 300, width = 3.4, height = 1, units="in"
  )
  ggsave(
    paste0(basename, ".svg"),
    figure, width = 3.4, height = 1, units="in"
  )
  return(figure)
}

generate_figure_experiment_4_trajectories <- function(
  df_experiment_4_trajectory,
  df_experiment_4_trajectory_turning_point,
  df_cogsci_building_patio_shape,
  basename
) {
  figure <- df_experiment_4_trajectory |>
    filter(rts_y < 1500 & condition != "Baseline") |>
    mutate(
      participant_id = forcats::fct_shuffle(as.factor(participant_id))
    ) |>
    ggplot() +
    geom_polygon(
      data = df_cogsci_building_patio_shape,
      mapping = aes(x = x / 100, y = y / 100, group = i),
      fill = "black", alpha = 0.3
    ) +
    geom_path(
      aes(x = rts_x / 100, y = rts_y / 100, group = participant_id, color = pedestrian_gender),
      alpha = 0.6
    ) +
    facet_grid(cols = vars(condition)) +
    geom_point(
      data = data.frame(
        x = c(187.0, 187.0, -0.18, -0.18),
        y = c(20.4, 20.4, 41.97, 41.97),
        condition = c("Humans", "Chairs", "Humans", "Chairs")
      ),
      mapping = aes(x = x / 100, y = y / 100),
      color = "black"
    ) +
    geom_point(
      data = df_experiment_4_trajectory_turning_point |>
        filter(breach != 1 & condition == "Humans") |>
        mutate(
          pedestrian_gender = relevel(as.factor(pedestrian_gender), ref = "Woman")
        ),
      mapping = aes(x = rts_x / 100, y = rts_y / 100, fill = pedestrian_gender),
      shape = 21, size = 2, color = "black"
    ) +
    annotate(
      "segment",
      arrow = arrow(
        length = unit(1.25, "mm"),
        type = "closed"
      ),
      color = "#616161",
      x = 3, y = 13,
      xend = 2, yend = 10
    ) +
    coord_fixed(ratio = 1, ylim = c(-2.2, 14), xlim = c(-1.1, 12)) +
    scale_y_continuous(
      name = "feet",
      breaks = seq(0, 45 / 3.28, by = 10 / 3.28),
      labels = function(x) round(x * 3.28)
    ) +
    scale_x_continuous(
      name = "feet",
      breaks = seq(0, 45 / 3.28, by = 10 / 3.28),
      labels = function(x) round(x * 3.28)
    ) +
    scale_color_manual(
      values = cmap_gender,
      labels = c("Woman", "Man"),
      name = "participant\ngender"
    ) +
    scale_fill_manual(
      values = cmap_gender,
      labels = c("Woman", "Man"),
      name = "participant\ngender"
    ) +
    theme_ccl() +
    theme(
      panel.border = element_rect(colour = "black", fill = NA, linewidth = 2),
      strip.text = element_blank(),
      strip.background = element_blank(),
      plot.margin = margin(0, 0, 0, 0, "pt"),
      axis.text.y  = element_blank(),
      axis.title.y  = element_blank(),
      axis.ticks.y = element_blank(),
      legend.position = c(.25, .1),
      legend.justification = c("left", "bottom"),
      legend.background = element_rect(fill = alpha("white", 1), color = "black"),
      legend.text = element_text(size = 8),
      legend.spacing = unit(1, "mm"),
      legend.margin  = margin(0, 3, 0, 3),
      legend.key.size = unit(4, 'mm'),
      legend.title = element_text(
          size = 8,
          margin = margin(b = 0)   # bottom margin in pt (default is larger)
        )
    )

  ggsave(
    paste0(basename, ".png"),
    figure, dpi = 300, width = 3.4, height = 2.5, units = "in"
  )
  ggsave(
    paste0(basename, ".svg"),
    figure, width = 3.4, units = "in"
  )
  return(figure)
}

generate_figure_experiment_4_trajectories_all <- function(
  df_experiment_4_trajectory,
  df_experiment_4_trajectory_turning_point,
  df_cogsci_building_patio_shape,
  basename
) {
  figure <- df_experiment_4_trajectory |>
    filter(rts_y < 1500) |>
    mutate(
      participant_id = forcats::fct_shuffle(as.factor(participant_id))
    ) |>
    ggplot() +
    geom_polygon(
      data = df_cogsci_building_patio_shape,
      mapping = aes(x = x / 100, y = y / 100, group = i),
      fill = "black", alpha = 0.3
    ) +
    geom_path(
      aes(x = rts_x / 100, y = rts_y / 100, group = participant_id, color = pedestrian_gender),
      alpha = 0.6
    ) +
    facet_grid(cols = vars(condition)) +
    geom_point(
      data = data.frame(
        x = c(187.0, 187.0, -0.18, -0.18),
        y = c(20.4, 20.4, 41.97, 41.97),
        condition = c("Humans", "Chairs", "Humans", "Chairs")
      ),
      mapping = aes(x = x / 100, y = y / 100),
      color = "black"
    ) +
    geom_point(
      data = df_experiment_4_trajectory_turning_point |>
        filter(breach != 1 & condition == "Humans") |>
        mutate(
          pedestrian_gender = relevel(as.factor(pedestrian_gender), ref = "Woman")
        ),
      mapping = aes(x = rts_x / 100, y = rts_y / 100, fill = pedestrian_gender),
      shape = 21, size = 2, color = "black"
    ) +
    annotate(
      "segment",
      arrow = arrow(
        length = unit(1.25, "mm"),
        type = "closed"
      ),
      color = "#616161",
      x = 3, y = 13,
      xend = 2, yend = 10
    ) +
    coord_fixed(ratio = 1, ylim = c(-2.2, 14), xlim = c(-1.1, 12)) +
    scale_y_continuous(
      name = "feet",
      breaks = seq(0, 45 / 3.28, by = 10 / 3.28),
      labels = function(x) round(x * 3.28)
    ) +
    scale_x_continuous(
      name = "feet",
      breaks = seq(0, 45 / 3.28, by = 10 / 3.28),
      labels = function(x) round(x * 3.28)
    ) +
    scale_color_manual(
      values = cmap_gender,
      labels = c("Woman", "Man"),
      name = "participant\ngender"
    ) +
    scale_fill_manual(
      values = cmap_gender,
      labels = c("Woman", "Man"),
      name = "participant\ngender"
    ) +
    theme_ccl() +
    theme(
      panel.border = element_rect(colour = "black", fill = NA, linewidth = 2),
      strip.text = element_blank(),
      strip.background = element_blank(),
      plot.margin = margin(0, 0, 0, 0, "pt"),
      axis.text.y  = element_blank(),
      axis.title.y  = element_blank(),
      axis.ticks.y = element_blank(),
      legend.position = c(.25, .1),
      legend.justification = c("left", "bottom"),
      legend.background = element_rect(fill = alpha("white", 1), color = "black"),
      legend.text = element_text(size = 8),
      legend.spacing = unit(1, "mm"),
      legend.margin  = margin(0, 3, 0, 3),
      legend.key.size = unit(4, 'mm'),
      legend.title = element_text(
          size = 8,
          margin = margin(b = 0)   # bottom margin in pt (default is larger)
        )
    )

  ggsave(
    paste0(basename, ".png"),
    figure, dpi = 300, width = 7, height=3.2, units = "in"
  )
  ggsave(
    paste0(basename, ".svg"),
    figure, width = 7, height=3.2, units = "in"
  )
  return(figure)
}

generate_figure_experiment_2_collective_breaching_trajectories <- function(
  frames_before_pass,
  df_experiment_2,
  df_experiment_2_trajectory_contagion_case_study,
  df_mural_shape,
  contagion_example_pedestrians,
  model_breaching_experiment_2,
  basename
) {
  top_figure <- ggplot(
      df_experiment_2_trajectory_contagion_case_study,
      aes(alpha=condition)
    ) +
    geom_polygon(
      data = df_mural_shape |> filter(i == 0),
      mapping = aes(x = x, y = y, group = i),
      alpha=1,
      fill = MURAL_GROUND_COLOR
    ) +
    geom_polygon(
      data = df_mural_shape |> dplyr::filter(i == 1),
      mapping = aes(x = x, y = y, group = i),
      alpha=1, fill = "#e7d9b5"
    ) +
    geom_polygon(
      data = df_mural_shape |> dplyr::filter(i == 2),
      mapping = aes(x = x, y = y, group = i),
      alpha=1, fill = "#e7d9b5"
    ) +
    geom_polygon(
      data = df_mural_shape |> dplyr::filter(i == 3),
      mapping = aes(x = x,y = y,group = i),
      alpha=1, fill = "#e7d9b5", linewidth = 1.0, color = "black",
    ) +
    geom_path(
      aes(x = rts_x / 100, y = rts_y / 100, group = person_id, color = trigger_people),
      linewidth=1.5/ggplot2::.pt, alpha=0.5,
      arrow = arrow(
        length = unit(1.25, "mm"),
        type = "closed"
      ),
    ) +
    scale_color_manual(
      values = c("t" = "#e44c37", "f" = "black"), #, "o" = "blue"),
      name = element_blank()
    ) +
    geom_segment(
      data = data.frame(
        x     = c(-2.8, -2.8),
        y     = c(0 - ARROWLEN, 3.26 + ARROWLEN),
        xend  = c(-2.8, -2.8),
        yend  = c(0 + ARROWLEN, 3.26 - ARROWLEN)
      ),
      aes(x = x, y = y, xend = xend, yend = yend),
      arrow = arrow(
        length = unit(1.25, "mm")
      ),
      color = "#e44c37",
      linewidth = 0.5, alpha = 1
    ) +
    facet_wrap(~factor(before_trigger, c(TRUE, FALSE)), ncol = 2) +
    coord_fixed(ratio = 1, ylim = c(5.7, -2.0), xlim = c(-15, 11)) +
    scale_y_reverse() +
    scale_x_continuous(
      name = "feet",
      breaks = seq(-40 / 3.28, 50 / 3.28, by = 10 / 3.28) - (2.8),
      labels = function(x) round((x + 2.8) * 3.28)
    ) +
    theme_ccl() +
    theme(
      legend.position = "none",
      panel.border = element_rect(colour = "black", fill = NA, linewidth = 1),
      panel.background=element_rect(fill="#c1c1c1"),
      plot.margin = margin(0, 0, 0, 0, "in"),
      panel.spacing = unit(3, "pt"),
      strip.text = element_blank(),  # optional: remove facet titles
      axis.text.y  = element_blank(),
      axis.title.y  = element_blank(),
      axis.ticks.y = element_blank()
    )

  ggsave(
    paste0(basename, "_top", ".png"),
    top_figure, dpi = 300, width = 7, height = 1.4, units="in"
  )
  ggsave(
    paste0(basename, "_top", ".svg"),
    top_figure, width = 7, height = 1.4, units="in"
  )
  # ===========================================================================

  breach_df <- df_experiment_2 |>
    dplyr::filter(video == "2023-12-07" & person_id %in% contagion_example_pedestrians) |>
    dplyr::group_by(person_id, pass_frame) |>
    dplyr::summarise(breach=sum(breach))

  trigger <- (41629 - min(breach_df$pass_frame)) / 30

  rolling_breach <- function(center_frame) {
    agg <- breach_df |>
      dplyr::filter((center_frame - frames_before_pass) <= pass_frame & pass_frame <= (center_frame)) |>
      dplyr::summarise(breach=mean(breach))
    return(agg$breach[1])
  }

  breach_df <- breach_df |>
    dplyr::mutate(row_num = row_number()) |>
    dplyr::rowwise() |>
    dplyr::mutate(rolling_break_rate = rolling_breach(pass_frame)) |>
    dplyr::ungroup() |>
    dplyr::mutate(pass_frame = (pass_frame - min(pass_frame))/30) |>
    dplyr::mutate(
      trigger_people = dplyr::case_when(
        person_id %in% c(121, 123, 127) ~ "t",
        person_id == 147 ~ "o",
        .default = "f"
      )
    )

  breach_df$model_prediction <- predict(
    model_breaching_experiment_2,
    newdata = df_experiment_2 |> dplyr::filter(video == "2023-12-07" & person_id %in% contagion_example_pedestrians),
    type = "response"
  )

  bottom_figure <- ggplot(breach_df, aes(x=pass_frame, y=rolling_break_rate)) +
    geom_point(
      data=breach_df,
      mapping=aes(x=pass_frame, y=breach, color = trigger_people)
    ) +
    scale_color_manual(
      values = c("t" = "red", "f" = "black", "o" = "black"),
      name = element_blank()
    ) +
    geom_line(
      data=breach_df,
      mapping = aes(x=pass_frame, y=model_prediction),
      linetype = "dashed"
    ) +
    geom_vline(aes(xintercept=trigger), color="red") +
    xlab("seconds") +
    ylab("break rate") +
    theme_ccl() +
    theme(
      legend.position = "none"
    )

  ggsave(
    paste0(basename, "_bottom", ".png"),
    bottom_figure, dpi = 300, width=7, height=1.5, units = "in"
  )
  ggsave(
    paste0(basename, "_bottom", ".svg"),
    bottom_figure, width=7, height=1.5, units = "in"
  )
  return(list(top=top_figure, bottom=bottom_figure))
}

generate_figure_gender_breaching_probabilities <- function(
  emmeans_breaching_by_gender_experiment_1_and_3,
  df_experiment_1_and_3,
  basename
) {
  empirical_breaching_by_gender_frequency_experiment_1_and_3 <- df_experiment_1_and_3 |>
    filter(
      transportation == "Walking" & actor_gender != "MW" & distance == "5 ft"
    ) |>
    group_by(type_of_interaction, location, pedestrian_gender) |>
    summarise(estimate = mean(breach), size=n(), .groups = "keep") |>
    group_by(pedestrian_gender) |>
    summarise(estimate = mean(estimate), .groups = "keep") |>
    ungroup() |>
    mutate(
      pedestrian_gender = factor(pedestrian_gender, levels = c("Man", "Woman"))
    )

  figure <- emmeans_breaching_by_gender_experiment_1_and_3 |>
    broom::tidy(conf.int = TRUE) |>
    mutate(
      pedestrian_gender = factor(pedestrian_gender, levels = c("Man", "Woman")),
      actor_gender = factor(actor_gender, levels = c("M", "W"))
    ) |>
    ggplot(aes(x = prob, xmin = conf.low, xmax = conf.high, y = pedestrian_gender, color = actor_gender)) +
    geom_pointrange(position = position_dodge(width = 0.6), size = 0.25, alpha = 1.0) +
    geom_point(
      data = empirical_breaching_by_gender_frequency_experiment_1_and_3,
      mapping = aes(y = pedestrian_gender, x = estimate, color = pedestrian_gender),
      position = position_dodge(width = 0.6),
      shape = 23, color = "black", fill = "white", size = 1.5, inherit.aes = FALSE
    ) +
    xlab("Breach Probability") +
    ylab("Pedestrian Gender") +
    scale_color_manual(
      values = cmap_gender,
      labels = c("Man", "Woman"),
      name = "Actor Gender"
    ) +
    ggplot2::xlim(0.0, 0.3) +
    theme_ccl() +
    theme(
        panel.spacing = unit(3, "mm"),
        strip.placement = "left",
        strip.text.y = element_blank(),
        strip.background = element_blank(),
        plot.margin = margin(0, 2, 2, 0, "mm")
    )

  ggsave(
    paste0(basename, ".png"),
    figure, dpi = 300, width = 120, height = 50, units="mm"
  )
  ggsave(
    paste0(basename, ".svg"),
    figure, width = 120, height = 40, units="mm"
  )
  return(figure)
}


# =============================================================================
# Supplementary
# =============================================================================

generate_figure_experiment_4_orients_away_violin <- function(
  df_experiment_4_orients_away,
  basename
) {
  figure <- df_experiment_4_orients_away |>
    filter(breach != 1 & condition == "Humans") |>
    ggplot(aes(x = pedestrian_gender, y = rts_distance_to_wall_middle / 100)) +
    geom_violin(aes(fill = pedestrian_gender, color = pedestrian_gender),
      width = 0.75,
      alpha = 0.5
    ) +
    geom_boxplot(width = 0.3, fill = "white", color = "#333333") +
    stat_summary(
      fun = "mean", geom = "point",
      shape = 23, size = 2, fill = "white", stroke = 1.0
    ) +
    geom_quasirandom(
      aes(fill = pedestrian_gender),
      width = 0.2, alpha = 0.75, size = 0.75, color = "black"
    ) +
    ylim(0, 15) +
    ylab("Orients Away Distance (meters)") +
    xlab("Pedestrian Gender") +
    scale_color_manual(values = cmap_gender, name="Pedestrian Gender") +
    scale_fill_manual(values = cmap_gender, name="Pedestrian Gender") +
    theme_ccl()

  ggsave(
    paste0(basename, ".png"),
    figure, dpi = 300, width = 3.5, height = 5, units="in"
  )

  ggsave(
    paste0(basename, ".svg"),
    figure, width = 3.5, height = 5, units="in"
  )
  return(figure)
}
