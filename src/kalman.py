# =============================================================================
# Title: Invisible Wall
# File: src/kalman.py
# Author: Jack Terwilliger (University of California, San Diego)
# Date Created: 2025-10-08
# Last Modified: 2025-10-08
# Description:
#   Functions for running kalman filters on pedestrian trajectory data.
#
#   kalman_filter allows you to specify a Kalman Filter which possibly operates
#   over multiple 'sensors', e.g. two cameras
#
#   run_filter runs a kalman filter over a dataframe (for just one pedestrian)
#
#   kalman runs a kalman filter over multiple pedestrians
#
#   If you have a dataframe with columns=[frame, trackingId, x, y]
#   Then, you can simply call kalman(df)
#
# Dependencies:
#   - filterpy
#   - numpy
#   - pandas
#   - scipy
#
# =================

from filterpy.kalman import KalmanFilter
from filterpy.common import Q_discrete_white_noise
from scipy.linalg import block_diag
import numpy as np
import pandas as pd

def kalman_filter(sx, sy, dt = 1./30., nsensors=1):
    R_std = 15
    Q_std = 15

    kfilter = KalmanFilter(dim_x=6, dim_z=2 * nsensors)
    kfilter.F = np.array([[1, dt, 0.5*dt*dt,  0,  0,          0],
                          [0,  1,        dt,  0,  0,          0],
                          [0,  0,         1,  0,  0,          0],
                          [0,  0,         0,  1,  dt, 0.5*dt*dt],
                          [0,  0,         0,  0,  1,         dt],
                          [0,  0,         0,  0,  0,          1]])

    kfilter.u = 0.
    kfilter.H = np.tile(
        np.array(
            [[1, 0, 0, 0, 0, 0],
             [0, 0, 0, 1, 0, 0]]
        ),
        (nsensors, 1)
    )

    kfilter.R = np.eye(2 * nsensors) * R_std**2
    q = Q_discrete_white_noise(dim=3, dt=dt, var=Q_std**2)
    kfilter.Q = block_diag(q, q)
    kfilter.x = np.array([[sx, 0, 0, sy, 0, 0]]).T  # type: ignore
    kfilter.P = np.eye(6) * 15
    return kfilter

def run_filter(kfilter, df):
    blocks = (pd.isna(df["x"]) != pd.isna(df["x"].shift())).cumsum()
    ms = []
    cs = []
    for _, gdf in df.groupby(blocks):
        if pd.isna(gdf["x"].iloc[0]) or pd.isna(gdf["y"].iloc[0]):
            m, c, _, _ = kfilter.batch_filter([None] * len(gdf))
        else:
            m, c, _, _ = kfilter.batch_filter(gdf[["x", "y"]].values)
        ms.append(m)
        cs.append(c)
    return np.vstack(ms), np.vstack(cs)

def kalman(df: pd.DataFrame) -> pd.DataFrame:
    for trackingId, gdf in df.groupby("trackingId"):
        start_idx = ~(pd.isna(gdf.x) | pd.isna(gdf.y))
        init_x = gdf.loc[start_idx].x.iloc[0]
        init_y = gdf.loc[start_idx].y.iloc[0]
        kfilter = kalman_filter(init_x, init_y, dt = 1/30)
        mu, cov = run_filter(kfilter, gdf)
        
        df.loc[gdf.index, "kalman_x"] = mu[:, 0, 0]
        df.loc[gdf.index, "kalman_dx_dt"] = mu[:, 1, 0]
        df.loc[gdf.index, "kalman_dx_dt_dt"] = mu[:, 2, 0]
        df.loc[gdf.index, "kalman_y"] = mu[:, 3, 0]
        df.loc[gdf.index, "kalman_dy_dt"] = mu[:, 4, 0]
        df.loc[gdf.index, "kalman_dy_dt_dt"] = mu[:, 5, 0]

        mu_rts, cov_rts, _, _ = kfilter.rts_smoother(mu, cov)
        df.loc[gdf.index, "rts_x"] = mu_rts[:, 0, 0]
        df.loc[gdf.index, "rts_dx_dt"] = mu_rts[:, 1, 0]
        df.loc[gdf.index, "rts_dx_dt_dt"] = mu_rts[:, 2, 0]
        df.loc[gdf.index, "rts_y"] = mu_rts[:, 3, 0]
        df.loc[gdf.index, "rts_dy_dt"] = mu_rts[:, 4, 0]
        df.loc[gdf.index, "rts_dy_dt_dt"] = mu_rts[:, 5, 0]
    return df