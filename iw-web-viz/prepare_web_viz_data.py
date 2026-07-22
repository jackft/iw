import pathlib
import json
import pandas as pd
import numpy as np
from scipy import interpolate


n = 3
velocityFilter = 1
df = pd.read_csv("data/experiment_2_trajectory.csv")
for video, gdf in df.groupby("video"):
    gdf = gdf[["person_id", "rts_x", "rts_y", "sync_frame", "x"]]
    gdf = gdf.rename(columns={"rts_x": "x", "rts_y": "y", "sync_frame": "frame", "x": "keep"})
    gdf["frame"] = gdf["frame"] - gdf["frame"].min()
    
    interpolated_rows = []

    for person_id, pdf in gdf.groupby("person_id"):
        pdf = pdf.sort_values("frame").reset_index(drop=True)

        # --- Drop frames around NaN 'keep' ---
        mask = np.ones(len(pdf), dtype=bool)
        nan_ilocs = np.where(pdf["keep"].isna())[0]
        for loc in nan_ilocs:
            start = max(0, loc - n)
            end = min(len(pdf), loc + n + 1)
            mask[start:end] = False
        pdf = pdf.iloc[mask]

        if pdf.empty:
            continue

        # --- Velocity filter ---
        dx = pdf["x"].diff()
        dy = pdf["y"].diff()
        pdf["velocity"] = np.sqrt(dx**2 + dy**2)
        pdf = pdf[pdf["velocity"] > velocityFilter]

        if pdf.empty:
            continue

        # --- Linear interpolation to fill missing frames ---
        frames = np.asarray(pdf["frame"].values)
        xs = np.asarray(pdf["x"].values)
        ys = np.asarray(pdf["y"].values)
        all_frames = np.arange(frames.min(), frames.max() + 1)

        u = (frames - frames.min()) / (frames.max() - frames.min())
        tck, _ = interpolate.splprep([xs, ys], s=0)
        u_new = (all_frames - frames.min()) / (frames.max() - frames.min())
        x_filled, y_filled = interpolate.splev(u_new, tck)


        for f, x, y in zip(all_frames, x_filled, y_filled):
            interpolated_rows.append({
                "person_id": person_id,
                "frame": f,
                "x": x,
                "y": y
            })

    interpolated_df = pd.DataFrame(interpolated_rows)
    for col in interpolated_df.columns:
        interpolated_df[col] = interpolated_df[col].astype("int64")
    interpolated_df.to_json(
        f"iw-web-viz/public/data/experiment_2_trajectory_{video}.json.gz",
        index=False,
        orient="records",
        compression="gzip"
    )

df = pd.read_csv("data/experiment_2.csv")
for video, gdf in df.groupby("video"):
    gdf.to_json(
        f"iw-web-viz/public/data/experiment_2_{video}.json.gz",
        index=False,
        orient="records",
        compression="gzip"
    )

df = pd.read_csv("../data/environment_shapes/mural.csv")

def get_fill(i):
    if i == 0: return "c1c1c1"
    if i == 1: return "876542"
    if i == 2: return "876542"
    if i == 3: return "c1c1c1"
    if i == 4: return "c1c1c1"
    return None

def get_stroke(i):
    if i == 0: return None
    if i == 1: return None
    if i == 2: return None
    if i == 3: return "000000"
    if i == 4: return "000000"
    return None

mural_shape = {
    i: {
        "closed": True,
        "points": (gdf[["x", "y"]]*100).to_dict(orient="records"),
        "fill": get_fill(i),
        "stroke": get_stroke(i)
    }
    for i, gdf in df.groupby("i")
}
pathlib.Path("iw-web-viz/public/data/environments").mkdir(parents=True, exist_ok=True)
with open("iw-web-viz/public/data/environments/mural.json", "w") as f:
    json.dump(mural_shape, f)
