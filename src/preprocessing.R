# =============================================================================
# Title: Invisible Wall
# File: src/preprocessing.R
# Author: Jack Terwilliger (University of California, San Diego)
# Date Created: 2025-10-08
# Last Modified: 2025-10-08
# Description:
#   Functions to preprocess experiment 2 data.
#
# Dependencies:
#   - dplyr
#   - lubridate
#
# =============================================================================

library(dplyr)
library(lubridate)

get_row_when_pedestrian_passes_wall <- function(wall_x_coord, df_trajectory) {
  df_passes_right <- df_trajectory |>
    filter(pedestrian_passes_wall_area == 1 & pedestrian_direction == "Right") |>
    group_by(video, person_id) |>
    filter(rts_x <= wall_x_coord) |>
    arrange(rts_x) |>
    slice_tail(n = 1)
  
  df_passes_left <- df_trajectory |>
    filter(pedestrian_passes_wall_area == 1 & pedestrian_direction == "Left") |>
    group_by(video, person_id) |>
    filter(rts_x >= wall_x_coord) |>
    arrange(rts_x) |>
    slice_head(n = 1)
  
  df_passes <- bind_rows(df_passes_left, df_passes_right) |>
    filter(abs(wall_x_coord - rts_x) < 30) |>
    mutate(
      pass_x     = rts_x,
      pass_y     = rts_y,
      pass_frame = sync_frame,
      start_t    = as.POSIXct(start_t, format="%H:%M:%OS", tz="UTC"),
      pass_t     = start_t + (pass_frame/30),
      pass_hour  = lubridate::hour(pass_t),
      pass_minute= lubridate::minute(pass_t)
    ) |>
    select(
      video, person_id, pedestrian_passes_wall_area, breach,
      pass_frame, pass_x, pass_y, start_t, pass_t, pass_hour, pass_minute) |>
    ungroup()

  return(df_passes)
}

get_crowd_size <- function(
  frames_before_pass, df_row_when_pedestrian_passes_wall,
  video, this_person_id, mid_frame
) {
  agg <- df_row_when_pedestrian_passes_wall |>
    filter(
      (video == video) &
      (mid_frame - frames_before_pass <= pass_frame) &
      (pass_frame <= mid_frame + frames_before_pass) &
      person_id != this_person_id
    ) |>
    summarise(crowd_size=length(unique(person_id)), .groups="keep")
  return(agg$crowd_size[1])
}

get_breach_before <- function(
  frames_before_pass, df_row_when_pedestrian_passes_wall,
  video, this_person_id, mid_frame
) {
  agg <- df_row_when_pedestrian_passes_wall |>
    filter(
      (video == video) &
      (mid_frame - frames_before_pass <= pass_frame) &
      (pass_frame <= mid_frame) &
      (pedestrian_passes_wall_area == 1) &
      person_id != this_person_id
    ) |>
    group_by(video, person_id) |>
    reframe(breach=first(breach), .groups="keep") |>
    ungroup() |>
    reframe(breach=sum(breach), .groups="keep")
  return(agg$breach[1])
}

get_crowd_aggregations <- function(
  wall_x_coord,
  frames_before_pass,
  df_trajectory,
  df_row_when_pedestrian_passes_wall
) {
  df_crowd_aggregations <- df_trajectory |>
    group_by(video, person_id) |>
    mutate(
      dist = abs(wall_x_coord - rts_x)
    ) |>
    arrange(dist) |>
    filter(row_number() == 1) |>
    summarise(
      start_t = first(start_t),
      mid_frame = first(sync_frame),
      pedestrian_group_id = first(pedestrian_group_id),
      .groups = "keep"
    ) |>
    mutate(
      start_t    = as.POSIXct(start_t, format="%H:%M:%OS", tz="UTC"),
      mid_t     = start_t + (mid_frame/30),
      mid_hour  = lubridate::hour(mid_t),
      mid_minute= lubridate::minute(mid_t)
    ) |>
    rowwise() |>
    mutate(
      crowd_size = get_crowd_size(
        frames_before_pass, df_row_when_pedestrian_passes_wall,
        video, person_id, mid_frame
      ),
      breach_before = get_breach_before(
        frames_before_pass, df_row_when_pedestrian_passes_wall,
        video, person_id, mid_frame
      )
    ) |>
    ungroup()
  return (df_crowd_aggregations)
}
