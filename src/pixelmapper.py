# =============================================================================
# Title: Invisible Wall
# File: src/pixelmapper.py
# Author: Jack Terwilliger (University of California, San Diego)
# Date Created: 2025-10-08
# Last Modified: 2025-10-08
# Description:
#   Tools for camera homography, i.e., assuming a planar environment map
#   an object's pxiel coordinates to it's real world position.
#   
#   There are several steps needed to do this.
#   1. Determine the intrinsic calibration of your camera (lens & image sensor properties)
#   2. Locate some fixed landmarks in your images in order to estimate where the photo was taken
#   3. Fit a homography (image->ground plane linear mapping)
#   4. transform pixels to world coordinates
#
#   Here is a simple guide
#   1. Detemine intrinsic Calibration
#   First, take at least 10 photos of a checkerboard: https://github.com/opencv/opencv/blob/4.x/doc/pattern.png
#   Estimate the camera intrinsics using the intrinsic-calibration tool
#   If you have a fisheye camera, you will need to add the --fisheye flag
#   in order to use the appropriate mathematical camera model.
#
#   python pixelmapper.py intrinsic-calibration \
#       --input file_with_checkerboard_images \
#       --output intrinsic.pkl \
#       --fisheye
#
#   2. Locate landmarks
#   First, go into the world, find some unmovable landmarks and place them in a 2d coordinate system.
#   Triginometry and a tapemeasure are all you need.
#   Then, in a video, click on those landmarks in one of your video frames
#   
#   python pixelmapper.py tie-pixels-to-world \
#       --video video.mp4 --input world_measurements.csv \
#       --output world2pixel_mapping.csv
#
#   Finally, check whether the camera moved during your video. If it did, you will need to create
#   a separate mapping
#   
#   3. Create a homography (linear mapping)
#   Using the intrinsics and pixel->world landmark mapping you have enough
#
#   python pixelmapper.py extrinsic-calibration \
#       --input world2pixel_mapping.csv \
#       --intrinsic intrinsic.pkl \
#       --output homography.pkl
#
#   4. Map pixels to the ground plane
#   Now you can load the homography and use the PixelMapper class
#
#   with open("extrinsic.pkl", "rb") as f:
#       extrinsic_data = pickle.load(f)
#   with open("intrinsic.pkl", "rb") as f:
#       intrinsic_data = pickle.load(f)
#   pm = PixelMapper(
#       intrinsic_mtx=intrinsic_data["intrinsic_mtx"],
#       distortion=intrinsic_data["distortion"],
#       newcameramtx=intrinsic_data["newcameramtx"],
#       homography=extrinsic_data["pixel2world_homography"],
#       fisheye=intrinsic_data["fisheye"],
#   )
#
#   worldpoints = pm(df.loc[:, ["px", "py"]].to_numpy().astype(np.float32).reshape(-1, 1, 2))
#   imagepoints = pm.inv(df.loc[:, ["wx", "wy"]].to_numpy().astype(np.float32).reshape(-1, 1, 2))
#   
#
# Dependencies:
#   - click
#   - cv2
#   - pandas
#   - matplotlib
#
# =============================================================================


import glob
import pathlib
import pickle

import click
import cv2 as cv
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

################################################################################
# computer vision tools
################################################################################

def pad(X, val = 1):
    return np.pad(X, ((0, 0), (0, 1)), constant_values=val).T

def _extrinsic_calibration(pts_src, pts_dst):
    h, _ = cv.findHomography(pts_src, pts_dst, cv.RANSAC, 5.0)
    return h

def pixels2world(homography_h, pts_pixels):
    return cv.perspectiveTransform(pts_pixels.reshape(-1, 1, 2), homography_h)[:,0,:]

def _intrinsic_calibration(images, visualize = False, fisheye = False):
    # termination criteria
    criteria = (cv.TERM_CRITERIA_EPS + cv.TERM_CRITERIA_MAX_ITER, 30, 0.001)
    # prepare object points, like (0,0,0), (1,0,0), (2,0,0) ....,(6,5,0)
    objp = np.zeros((6*9,3), np.float32)
    objp[:,:2] = np.mgrid[0:9,0:6].T.reshape(-1,2)
    # Arrays to store object points and image points from all the images.
    objpoints = [] # 3d point in real world space
    imgpoints = [] # 2d points in image plane.
    for fname in images:
        img = cv.imread(fname)
        h, w = img.shape[:2]
        gray = cv.cvtColor(img, cv.COLOR_BGR2GRAY)
        # Find the chess board corners
        ret, corners = cv.findChessboardCorners(gray, (9,6), None)
        # If found, add object points, image points (after refining them)
        if ret == True:
            objpoints.append(objp)
            corners2 = cv.cornerSubPix(gray,corners, (11,11), (-1,-1), criteria)
            imgpoints.append(corners2)
            if not visualize: continue
            # Draw and display the corners
            cv.drawChessboardCorners(img, (9,6), corners2, ret)
            cv.imshow('img', img)
            cv.waitKey(500)
    cv.destroyAllWindows()

    if fisheye:
        N_OK = len(objpoints)
        K = np.zeros((3, 3))
        D = np.zeros((4, 1))
        rvecs = [np.zeros((1, 1, 3), dtype=np.float64) for i in range(N_OK)]
        tvecs = [np.zeros((1, 1, 3), dtype=np.float64) for i in range(N_OK)]
        calibration_flags = cv.fisheye.CALIB_RECOMPUTE_EXTRINSIC+cv.fisheye.CALIB_CHECK_COND+cv.fisheye.CALIB_FIX_SKEW
        objpoints = np.expand_dims(np.asarray(objpoints), -2)
        ret, mtx, dist, rvecs, tvecs = \
            cv.fisheye.calibrate(
                objpoints,
                imgpoints,
                gray.shape[::-1],
                K,
                D,
                rvecs,
                tvecs,
                calibration_flags,
                (cv.TERM_CRITERIA_EPS+cv.TERM_CRITERIA_MAX_ITER, 30, 1e-6)
            )
        newcameramtx = cv.fisheye.estimateNewCameraMatrixForUndistortRectify(mtx, dist, (w, h), R=np.eye(3), balance=1.0)
        roi = None
    else:
        ret, mtx, dist, rvecs, tvecs = cv.calibrateCamera(objpoints, imgpoints, gray.shape[::-1], None, None)
        newcameramtx, roi = cv.getOptimalNewCameraMatrix(mtx, dist, (w,h), None, None)
    return mtx, dist, newcameramtx, roi

def _undistort_fisheye(img, K, D, balance=0.0, dim2=None, dim3=None):
    h, w = img.shape[:2]
    dim1 = img.shape[:2][::-1]  #dim1 is the dimension of input image to un-distort
    assert dim1[0]/dim1[1] == w/h, "Image to undistort needs to have same aspect ratio as the ones used in calibration"
    if not dim2:
        dim2 = dim1
    if not dim3:
        dim3 = dim1
    scaled_K = K * dim1[0] / w  # The values of K is to scale with image dimension.
    scaled_K[2][2] = 1.0  # Except that K[2][2] is always 1.0    # This is how scaled_K, dim2 and balance are used to determine the final K used to un-distort image. OpenCV document failed to make this clear!
    new_K = cv.fisheye.estimateNewCameraMatrixForUndistortRectify(scaled_K, D, dim2, np.eye(3), balance=balance)
    map1, map2 = cv.fisheye.initUndistortRectifyMap(scaled_K, D, np.eye(3), new_K, dim3, cv.CV_16SC2)
    return cv.remap(img, map1, map2, interpolation=cv.INTER_LINEAR, borderMode=cv.BORDER_CONSTANT)

class PixelMapper:
    def __init__(self,
                 intrinsic_mtx=None,
                 distortion=None,
                 newcameramtx=None,
                 homography=None,
                 fisheye=False):
        self.intrinsic_mtx = intrinsic_mtx
        self.distortion = distortion
        self.newcameramtx = newcameramtx
        self.homography = homography
        self.fisheye = fisheye

    def undistort(self, X):
        if self.intrinsic_mtx is not None:
            if self.fisheye:
                return cv.fisheye.undistortPoints(X, self.intrinsic_mtx, self.distortion, None, self.newcameramtx)
            return cv.undistortPoints(X, self.intrinsic_mtx, self.distortion, None, self.newcameramtx)
        return X

    def __call__(self, X):
        """
        make sure you do .reshape(-1, 1, 2)
        """
        if self.intrinsic_mtx is not None:
            X = self.undistort(X)
        return cv.perspectiveTransform(X, self.homography)[:,0,:]

################################################################################
# command line utilities
################################################################################
# this just creates a group for us to add other commands, e.g., intrinsic_calibration
@click.group()
def cli():
    pass

@cli.command()
@click.option("--input", "-i", type=click.Path(exists=True), required=True, help="world2pixel")
@click.option("--intrinsic", "-imap", type=click.Path(exists=True), required=False, help="intrinsic calibration")
@click.option("--output", "-o", type=click.Path(exists=False), required=True, help="the name of the file to write calibration to")
def extrinsic_calibration(input, intrinsic, output):
    df = pd.read_csv(input)
    pts_pixels = np.array(df.loc[:, ["px", "py"]], np.float32)
    pts_world = np.array(df.loc[:, ["wx", "wy"]], np.float32)

    if intrinsic:
        with open(intrinsic, "rb") as f:
            intrinsic = pickle.load(f)
        pm = PixelMapper(
            intrinsic_mtx = intrinsic["intrinsic_mtx"],
            distortion = intrinsic["distortion"],
            newcameramtx = intrinsic["newcameramtx"],
            fisheye = intrinsic["fisheye"]
        )
    else:
        pm = PixelMapper()
    

    with np.printoptions(precision=3, suppress=True):
        print("-----------------")
        print("world")
        print("-----------------")
        print(pts_world)
        print("-----------------")
        print("pixels")
        print("-----------------")
        print(pts_pixels)
        print("-----------------")
        print("homography matrix")
        print("-----------------")
        pixel2world_homography = _extrinsic_calibration(pm.undistort(pts_pixels.reshape(-1, 1, 2)), pts_world)
        pm.homography = pixel2world_homography
        print(pixel2world_homography)
        print("---------------------")
        print("pixels -> world")
        print("---------------------")
        world_coords = pm(pts_pixels.reshape(-1, 1, 2)) #pixels2world(pixel2world_homography, pts_pixels)
        print(world_coords)
        print("---------------------")
        print("Errors")
        print("---------------------")
        print("l2", np.linalg.norm(pts_world - world_coords, axis=1))
        print("RMSE", np.linalg.norm(pts_world - world_coords, axis=1).mean())

    with open(output, r"wb") as f:
        pickle.dump(
            {
                "pixel2world_homography": pixel2world_homography,
                "l2": np.linalg.norm(pts_world - world_coords, axis=1),
                "RMSE": np.linalg.norm(pts_world - world_coords, axis=1).mean()
            },
            f
        )


@cli.command()
@click.option("--input", "-i", type=click.Path(exists=True), required=True, help="name of the file containing intrinsic checkerboard calibration")
@click.option("--output", "-o", type=click.Path(exists=False, file_okay=False, dir_okay=True), required=True, help="name of the pickle file containing intrinsic calibrations")
@click.option("--viz-output", "-vo", type=click.Path(exists=False), required=False, help="name of the pickle file containing intrinsic calibrations")
@click.option('--viz/--no-viz', default=False)
@click.option('--fisheye/--no-fisheye', default=False)
def intrinsic_calibration(input, output, viz_output, viz, fisheye):
    image_files = [str(p) for p in pathlib.Path(input).glob("*.JPG")]
    intrinsic_mtx, distortion, newcameramtx, roi = _intrinsic_calibration(image_files, viz, fisheye)

    if viz:
        for fname in image_files:
            img = cv.imread(fname)
            cv.imshow('img', img)
            cv.waitKey(500)
            h, w = img.shape[:2]
            if fisheye:
                dst = _undistort_fisheye(img, intrinsic_mtx, distortion, balance=0.8)
            elif roi is not None:
                mapx, mapy = cv.initUndistortRectifyMap(intrinsic_mtx, distortion, None, newcameramtx, (w,h), 5)
                dst = cv.remap(img, mapx, mapy, cv.INTER_LINEAR)
                # crop the image
                x, y, w, h = roi
                dst = dst[y:y+h, x:x+w]
            cv.imshow('img', dst)
            cv.waitKey(500)
            if viz_output is not None:
                print(str(pathlib.Path(viz_output) / pathlib.Path(fname).name))
                cv.imwrite(
                    str(pathlib.Path(viz_output) / pathlib.Path(fname).name),
                dst)

    with open(output, r"wb") as f:
        pickle.dump(
            {
                "intrinsic_mtx": intrinsic_mtx,
                "distortion": distortion,
                "newcameramtx": newcameramtx,
                "roi": roi,
                "fisheye": fisheye
            },
            f
        )


@cli.command()
@click.option("--videos", "-v", required=True, help="glob")
@click.option("--input", "-i", type=click.Path(exists=True), required=True, help="mapping file")
def check_mapping(videos, input):

    cv.namedWindow("Drawing", cv.WINDOW_GUI_NORMAL | cv.WINDOW_KEEPRATIO)
    cv.resizeWindow("Drawing", 800, 450)

    points_df = pd.read_csv(input)
    print(videos)
    for video in glob.glob(videos):
        cap = cv.VideoCapture(video)

        show_instruction = True
        show_points = True
        instruction = ""
        controls = ""
        ret, frame = cap.read()
        assert ret
        frame_index = 0

        def draw_image(frame, points_df, instruction, controls, show_points = True, show_instruction=True):
            to_draw = frame.copy()
            if show_points:
                draw_points(to_draw, points_df)
            if show_instruction:
                draw_instruction(to_draw, instruction, controls)
            return to_draw

        def draw_points(frame, points_df):
            for _, row in points_df.iterrows():
                cv.circle(frame, (int(row["px"]), int(row["py"])), 3, (0, 255, 0), -1)

        def draw_instruction(frame, instruction: str, controls: str):
            cv.putText(frame, str(frame_index), (50, 50),
                cv.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2
            )
            cv.putText(frame, str(pathlib.Path(video).name), (200, 50),
                cv.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2
            )
            cv.putText(frame, instruction, (100, 100),
                cv.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2
            )
            cv.putText(frame, controls, (100, 150),
                cv.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2
            )

        # Loop Over Remainder of Frames to See if Camera moves
        instruction = "Watch to see if camera moves. Wait till end"
        controls = "('h'=hide;'q'=quit;scroll=zoom)"
        while True:
            ret, _frame = cap.read()
            k = -1
            if not ret:
                instruction = "Click 'Enter'"
                controls = "('h'=hide;'q'=quit;scroll=zoom)"
                draw_img = draw_image(
                    frame, points_df, instruction, controls,
                    show_points=show_points, show_instruction=show_instruction
                )
                cv.imshow("Drawing", draw_img)
                k = cv.waitKey(1) 
            if ret:
                frame = _frame
                frame_index += 1
                if frame_index % 30 == 0:
                    draw_img = draw_image(
                        frame, points_df, instruction, controls,
                        show_points=show_points, show_instruction=show_instruction
                    )
                    cv.imshow("Drawing", draw_img)
                    k = cv.waitKey(1) 
            if k == 113:
                exit()
            elif k == 104:
                # 'h' == hide
                show_instruction = not show_instruction
                continue
            elif k == 13:
                # 'enter' == finish
                break

        cap.release()


@cli.command()
@click.option("--video", "-v", type=click.Path(exists=True), required=True, help="the video file")
@click.option("--input", "-i", type=click.Path(exists=True), required=True, help="ground truth locations")
@click.option("--output", "-o", type=click.Path(exists=False, file_okay=False, dir_okay=False), required=True, help="name of the pickle file containing intrinsic calibrations")
def tie_pixels_to_world(video, input, output):
    df = pd.read_csv(input, sep=',')
    cap = cv.VideoCapture(video)
    points_df = pd.DataFrame({
        "name": pd.Series(dtype=str),
        "wx": pd.Series(dtype=float),
        "wy": pd.Series(dtype=float),
        "px": pd.Series(dtype=int),
        "py": pd.Series(dtype=int)
    })

    # states
    cv.namedWindow("Map")
    cv.namedWindow("Drawing", cv.WINDOW_GUI_NORMAL | cv.WINDOW_KEEPRATIO)
    cv.resizeWindow("Drawing", 800, 450)

    show_instruction = True
    show_points = True
    instruction = ""
    controls = ""
    current_point = 0
    ret, frame = cap.read()
    assert ret
    frame_index = 0

    # functions
    def draw_map(df, current_point):
        innerW, innerH = 300, 300
        W, H = 500, 600
        max_x = df["x"].max()
        min_x = df["x"].min()
        def fx(x): return (x - min_x) / (max_x - min_x) * innerW + (W - innerW) / 2
        max_y = df["y"].max()
        min_y = df["y"].min()
        def fy(y): return (y - min_y) / (max_y - min_y) * innerH + (H - innerH) / 2
        blank_image = np.zeros((W, H, 3), np.uint8)
        for idx, row in df.iterrows():
            color = (0, 0, 255) if idx == current_point else (0, 255, 255)
            pts = (int(fx(row.x)), int(fy(row.y)))
            cv.circle(blank_image, pts, 3, color)
            cv.putText(
                blank_image, str(row["name"]), pts, cv.FONT_HERSHEY_COMPLEX,
                0.5, color
            )
        return blank_image

    def draw_image(frame, points_df, instruction, controls, show_points = True, show_instruction=True):
        to_draw = frame.copy()
        if show_points:
            draw_points(to_draw, points_df)
        if show_instruction:
            draw_instruction(to_draw, instruction, controls)
        return to_draw

    def draw_points(frame, points_df):
        for _, row in points_df.iterrows():
            cv.circle(frame, (int(row["px"]), int(row["py"])), 3, (0, 255, 0), -1)

    def draw_instruction(frame, instruction: str, controls: str):
        cv.putText(frame, str(frame_index), (50, 50),
            cv.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2
        )
        cv.putText(frame, instruction, (100, 100),
            cv.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2
        )
        cv.putText(frame, controls, (100, 150),
            cv.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2
        )

    def on_click(event, x: int, y: int, flags, params):
        if event == cv.EVENT_LBUTTONDOWN:
            if current_point not in df.index: return
            name: str = df.loc[current_point, "name"] # type: ignore
            wx: float = df.loc[current_point, "x"] # type: ignore
            wy: float = df.loc[current_point, "y"] # type: ignore
            points_df.loc[current_point,:] = [name, wx, wy, x, y]  # type: ignore

    # Main Loop
    instruction = "Click on Points ('s' to skip 'j/k'=prev/next frame)"
    controls = "('h'=hide;'q'=quit;'z'=undo;scroll=zoom)"
    cv.setMouseCallback("Drawing", on_click)
    while True and current_point != len(df):
        points_before_loop = len(points_df)
        map_img = draw_map(df, current_point)
        draw_img = draw_image(
            frame, points_df, instruction, controls,
            show_points=show_points, show_instruction=show_instruction
        )
        cv.imshow("Map", map_img)
        cv.imshow("Drawing", draw_img)
        k = cv.waitKey(5) 
        if k == 113:
            # 'q' == quit
            exit()
        elif k == 107:
            # 'k' == next
            ret, _frame = cap.read()
            if ret:
                frame = _frame
                frame_index += 1
            continue
        elif k == 106:
            # 'j' == prev
            cap.set(cv.CAP_PROP_POS_FRAMES, max(0, frame_index - 2))
            ret, _frame = cap.read()
            if ret:
                frame = _frame
                frame_index = max(0, frame_index - 1)
            continue
        elif k == 115:
            # 's' == skip
            current_point += 1
            continue
        elif k == 104:
            # 'h' == hide
            show_instruction = not show_instruction
            continue
        elif k == 122:
            # 'z' == undo
            current_point = max(0, current_point - 1)
            points_df = points_df.iloc[:-1,:]
            continue
        elif k != -1:
            print(k)
            continue
        points_after_loop = len(points_df)
        if points_after_loop > points_before_loop:
            current_point += 1

    # Loop Over Remainder of Frames to See if Camera moves
    instruction = "Watch to see if camera moves. Wait till end"
    controls = "('h'=hide;'q'=quit;scroll=zoom)"
    while True:
        ret, _frame = cap.read()
        k = -1
        if not ret:
            instruction = "Click 'Enter'"
            controls = "('h'=hide;'q'=quit;scroll=zoom)"
            draw_img = draw_image(
                frame, points_df, instruction, controls,
                show_points=show_points, show_instruction=show_instruction
            )
            cv.imshow("Drawing", draw_img)
            k = cv.waitKey(1) 
        if ret:
            frame = _frame
            frame_index += 1
            if frame_index % 30 == 0:
                draw_img = draw_image(
                    frame, points_df, instruction, controls,
                    show_points=show_points, show_instruction=show_instruction
                )
                cv.imshow("Drawing", draw_img)
                k = cv.waitKey(1) 
        if k == 113:
            exit()
        elif k == 104:
            # 'h' == hide
            show_instruction = not show_instruction
            continue
        elif k == 13:
            # 'enter' == finish
            break

    # Output
    points_df.to_csv(output, index=False)


if __name__ == "__main__":
    cli()
