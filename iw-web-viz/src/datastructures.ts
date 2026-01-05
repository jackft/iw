import IntervalTree from 'node-interval-tree';

export interface TrajectoryObservation {
    person_id: number;
    frame: number;
    x: number;
    y: number;
    metadata?: Record<string, any>
}

export interface TrajectoryMeta {
  person_id: number;
  [key: string]: any;
}


export type BackgroundType = Record<
    number,
    {
        closed: boolean,
        points: {x: number, y: number}[],
        fill: string,
        stroke: string | null
    }
>;

export interface RenderConfig {
    xlim: [number, number];
    ylim: [number, number];
    width: number;
    height: number;
    background?: BackgroundType;
    windowGroups?: {key: string, name: string}[]
}

export class Interval {
    start: number
    end: number
    constructor(start: number, end: number) {
        this.start = start;
        this.end = end
    }

    intersects(other: Interval): boolean;
    intersects(other: number): boolean;
    intersects(other: Interval | number) {
        if (typeof other === "number") {
            return this.start <= other && other < this.end;
        }
        else {
            return !(this.end < other.start || other.end < this.start)
        }
    }

    merge(other: Interval) {
        // make sure these intersect!
        return new Interval(
            Math.min(this.start, other.start),
            Math.max(this.end, other.end)
        );
    }

    difference(other: Interval) {
        const result = [];
        if (this.intersects(other)) {
            if (this.start < other.start) {
                result.push(new Interval(this.start, Math.min(this.end, other.start)));
            }
            if (this.end > other.end) {
                result.push(new Interval(Math.max(this.start, other.end), this.end));
            }
        } else {
            result.push(new Interval(this.start, this.end));
        }
        return result;
    }

    intersection(other: Interval) {
        if (this.intersects(other)) {
            const start = Math.max(this.start, other.start);
            const end = Math.min(this.end, other.end);
            return new Interval(start, end);
        } else {
            // Return null if there is no intersection
            return null;
        }
    }

    forEach(callbackfn: (value: number, index: number, interval: Interval) => void) {
        for (let i = this.start; i < this.end; ++i) {
            callbackfn(i, i - this.start, this);
        }
    }
}


class TrajectoryPointMetaData {
    trackingId: number;
    metaData: Record<string, any>;
    constructor(trackingId: number, metaData: Record<string, any>) {
        this.trackingId = trackingId;
        this.metaData = metaData;
    }

    getGroup(...columns: string[]) {
        return columns.map(column => this.metaData[column])
                      .map(String)
                      .join(':')
    }
}

export class TrajectoryPoint {
    frame: number;
    trackingId: number;
    x: number;
    y: number;
    metaData: TrajectoryPointMetaData;
    constructor(frame: number, trackingId: number, x: number, y: number, metaData: TrajectoryPointMetaData) {
        this.frame = frame;
        this.trackingId = trackingId;
        this.x = x;
        this.y = y;
        this.metaData = metaData
    }
}

export class Trajectories {
    frames: Record<number, TrajectoryPoint[]> = {};
    tracks: Record<number, Interval[]> = {};
    trajectories: Record<number, TrajectoryPoint[]> = {};
    private trajectoryIntervalTree: IntervalTree<number> = new IntervalTree();
    private trajectoryPointMetaData: Record<number, TrajectoryPointMetaData> = {};
    constructor(data: TrajectoryObservation[], metaData: TrajectoryMeta[]) {
        metaData.forEach(row => {
            this.trajectoryPointMetaData[row.person_id] = new TrajectoryPointMetaData(row.person_id, row);
        });
        data.forEach(row => {
            if (!(row.person_id in this.trajectoryPointMetaData)) {
                this.trajectoryPointMetaData[row.person_id] = new TrajectoryPointMetaData(row.person_id, {});
            }
            const trajectoryPoint = new TrajectoryPoint(row.frame, row.person_id, row.x, row.y, this.trajectoryPointMetaData[row.person_id]);
            this.addTrajectoryPoint(trajectoryPoint);
        });
        Object.keys(this.tracks).forEach(tid => {
            const intervals = this.tracks[Number(tid)];
            this.trajectoryIntervalTree.insert(intervals[0].start, intervals[intervals.length - 1].end, Number(tid));
        });
    }

    getGroup(trackingId: number, ...columns: string[]) {
        return this.trajectoryPointMetaData[trackingId].getGroup(...columns);
    }

    getNewTrajectories(startFrame: number, endFrame: number) {
        return this.trajectoryIntervalTree.search(startFrame, endFrame);
    }

    getTrajectoryPointsByFrame(frame: number) {return this.frames[frame]}

    getTrajectoryByTrackingIdToFrame(trackingId: number, frame: number) {
        const fullTrajectory = this.trajectories[trackingId];
        if (fullTrajectory === undefined) return [];
        return fullTrajectory.filter(trajectoryPoint => trajectoryPoint.frame <= frame);
    }

    getTrajectoryByTrackingIdBetweenFrames(trackingId: number, start: number, end: number) {
        const fullTrajectory = this.trajectories[trackingId];
        if (fullTrajectory === undefined) return [];
        return fullTrajectory.filter(trajectoryPoint => start <= trajectoryPoint.frame  && trajectoryPoint.frame <= end);
    }

    addTrajectoryPoint(trajectoryPoint: TrajectoryPoint) {
        // add to frames
        if (!(trajectoryPoint.frame in this.frames)) {
            this.frames[trajectoryPoint.frame] = [];
        }
        this.frames[trajectoryPoint.frame].push(trajectoryPoint);
        if (!(trajectoryPoint.trackingId in this.trajectories)) {
            this.trajectories[trajectoryPoint.trackingId] = [];
        }
        this.trajectories[trajectoryPoint.trackingId].push(trajectoryPoint);

        // update interval
        if (!(trajectoryPoint.trackingId in this.tracks)) {
            this.tracks[trajectoryPoint.trackingId] = [];
        }
        const intervals = this.tracks[trajectoryPoint.trackingId];
        intervals.push(
            new Interval(trajectoryPoint.frame, trajectoryPoint.frame + 1)
        );
        // merge intervals
        intervals.sort((a, b) => {
            if (a.start < b.start) return -1;
            if (a.start > b.start) return 1;
            return 0;
        });
        const mergedIntervals = [intervals[0]];
        let lastMergedInterval = mergedIntervals[0];
        for (let i = 1; i < intervals.length; ++i) {
            const currInterval = intervals[i];

            if (lastMergedInterval.intersects(currInterval)) {
                lastMergedInterval = lastMergedInterval.merge(currInterval);
                mergedIntervals[mergedIntervals.length - 1] = lastMergedInterval;
            } else {
                mergedIntervals.push(currInterval);
                lastMergedInterval = currInterval;
            }
        }
        this.tracks[trajectoryPoint.trackingId] = mergedIntervals;
    }
}