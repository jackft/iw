import pandas as pd

# -----------------------------------------------------------------------------
# Load trajectory files
# -----------------------------------------------------------------------------
df_trajectory_2023_11_14 = pd.read_json("data/experiment_2_trajectory_2023-11-14.json.gz")
df_trajectory_2023_12_06 = pd.read_json("data/experiment_2_trajectory_2023-12-06.json.gz")
df_trajectory_2023_12_07 = pd.read_json("data/experiment_2_trajectory_2023-12-07.json.gz")

# === BASELINE ================================================================
df_baseline_trajectory = df_trajectory_2023_11_14.query("65985 <= frame <= 100798").copy()
df_baseline_trajectory["frame"] -= 65985

min_base_id = df_baseline_trajectory["person_id"].min()
df_baseline_trajectory["person_id"] -= min_base_id

df_baseline_trajectory_idmap = pd.DataFrame({
    "person_id": df_baseline_trajectory["person_id"] + min_base_id,
    "newid": df_baseline_trajectory["person_id"],
})

# === FACE-TO-FACE ============================================================
df_face2face_trajectory = df_trajectory_2023_12_07.query("31531 <= frame <= 53337").copy()
df_face2face_trajectory["frame"] = (
    df_face2face_trajectory["frame"] - 31531
    + df_baseline_trajectory["frame"].max()
    + 100
)

min_f2f_id = df_face2face_trajectory["person_id"].min()
offset_f2f = df_baseline_trajectory["person_id"].max() + 1

df_face2face_trajectory["person_id"] = (
    df_face2face_trajectory["person_id"] - min_f2f_id + offset_f2f
)

df_face2face_trajectory_idmap = pd.DataFrame({
    "person_id": df_face2face_trajectory["person_id"] + min_f2f_id - offset_f2f,
    "newid": df_face2face_trajectory["person_id"],
})

# === BACK-TO-BACK ============================================================
df_back2back_trajectory = df_trajectory_2023_12_06.query("89172 <= frame <= 104697").copy()
df_back2back_trajectory["frame"] = (
    df_back2back_trajectory["frame"] - 89172
    + df_face2face_trajectory["frame"].max()
    + 100
)

min_b2b_id = df_back2back_trajectory["person_id"].min()
offset_b2b = df_face2face_trajectory["person_id"].max() + 1

df_back2back_trajectory["person_id"] = (
    df_back2back_trajectory["person_id"] - min_b2b_id + offset_b2b
)

df_back2back_trajectory_idmap = pd.DataFrame({
    "person_id": df_back2back_trajectory["person_id"] + min_b2b_id - offset_b2b,
    "newid": df_back2back_trajectory["person_id"],
})

# === OFFSET-FACING ===========================================================
df_offsetfacing_trajectory = df_trajectory_2023_12_07.query("2240 <= frame <= 31530").copy()
df_offsetfacing_trajectory["frame"] = (
    df_offsetfacing_trajectory["frame"] - 2240
    + df_back2back_trajectory["frame"].max()
    + 100
)

min_of_id = df_offsetfacing_trajectory["person_id"].min()
offset_of = df_back2back_trajectory["person_id"].max() + 1

df_offsetfacing_trajectory["person_id"] = (
    df_offsetfacing_trajectory["person_id"] - min_of_id + offset_of
)

df_offsetfacing_trajectory_idmap = pd.DataFrame({
    "person_id": df_offsetfacing_trajectory["person_id"] + min_of_id - offset_of,
    "newid": df_offsetfacing_trajectory["person_id"],
})

# -----------------------------------------------------------------------------
# Combine all trajectory
# -----------------------------------------------------------------------------
df_trajectory = pd.concat(
    [
        df_baseline_trajectory,
        df_face2face_trajectory,
        df_back2back_trajectory,
        df_offsetfacing_trajectory,
    ],
    ignore_index=True
)

df_trajectory.to_json(
    "dist/data/experiment_2_trajectory_4video.json.gz",
    index=False,
    orient="records",
    compression="gzip"
)

# -----------------------------------------------------------------------------
# Remap IDs in the non-trajectory datafiles
# -----------------------------------------------------------------------------
df_2023_11_14 = pd.read_json("data/experiment_2_2023-11-14.json.gz")
df_2023_12_06 = pd.read_json("data/experiment_2_2023-12-06.json.gz")
df_2023_12_07 = pd.read_json("data/experiment_2_2023-12-07.json.gz")

def remap(df, idmap):
    m = idmap.set_index("person_id")["newid"].to_dict()
    return df[df["person_id"].isin(m)].assign(person_id=lambda z: z["person_id"].map(m))

df_baseline     = remap(df_2023_11_14, df_baseline_trajectory_idmap)
df_face2face    = remap(df_2023_12_07, df_face2face_trajectory_idmap)
df_back2back    = remap(df_2023_12_06, df_back2back_trajectory_idmap)
df_offsetfacing = remap(df_2023_12_07, df_offsetfacing_trajectory_idmap)

df = pd.concat(
    [df_baseline, df_face2face, df_back2back, df_offsetfacing],
    ignore_index=True,
)

df.to_json(
    "dist/data/experiment_2_4video.json.gz",
    index=False,
    orient="records",
    compression="gzip"
)
