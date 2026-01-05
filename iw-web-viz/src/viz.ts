import type { BackgroundType, RenderConfig } from "./datastructures";
import { Trajectories } from "./datastructures";
import { Controller } from "./controller";
import { Application, Container, Circle, Graphics, HTMLText } from "pixi.js";

// ---------------------------------------------------------
// Scale abstractions
// ---------------------------------------------------------
interface ScaleOptions {
    warn?: boolean;
    name?: string;
}

export interface Scale {
    name?: string;
    call(x: number): number;
    inv(y: number): number;
}

export class LinearScale implements Scale {
    constructor(
        public domain: [number, number],
        public range: [number, number],
        private opts: ScaleOptions = {}
    ) {}

    private get scale() {
        const [d0, d1] = this.domain;
        const [r0, r1] = this.range;
        return (r1 - r0) / (d1 - d0);
    }

    call(x: number) {
        const [d0] = this.domain;
        const [r0] = this.range;
        if (this.opts.warn && (x < d0 || x > this.domain[1])) {
            console.warn(`${x} outside domain ${this.domain}`);
        }
        return (x - d0) * this.scale + r0;
    }

    inv(y: number) {
        const [d0] = this.domain;
        const [r0] = this.range;
        if (this.opts.warn && (y < r0 || y > this.range[1])) {
            console.warn(`${y} outside range ${this.range}`);
        }
        return (y - r0) / this.scale + d0;
    }

    clone(): LinearScale {
        return new LinearScale([...this.domain] as [number, number], [...this.range] as [number, number], this.opts);
    }
}

// ---------------------------------------------------------
// Viewport wrapper for per-pane scaling
// ---------------------------------------------------------
export interface Viewport {
    container: Container;
    xscale: LinearScale;
    yscale: LinearScale;
}

function makeViewport(
    width: number,
    height: number,
    xlim: [number, number],
    ylim: [number, number]
): Viewport {
    const container = new Container();

    // Create a rectangular mask the same size as the pane
    const mask = new Graphics();
    mask.rect(0, 0, width, height)
        .fill(0xffffff);

    container.addChild(mask);
    container.mask = mask;  // apply mask to the container

    return {
        container,
        xscale: new LinearScale([0, width], xlim),
        yscale: new LinearScale([0, height], ylim)
    };
}


// ---------------------------------------------------------
// TrajectoryGeometry: handles rendering of one trajectory
// ---------------------------------------------------------

const DEFAULT_STYLE = {
    circle: {
        radius: 15,
        fill: 0xffffff,
        strokeColor: 0x1a1a1a,
        strokeWidth: 5
    },
    trajectory: {
        strokeColor: 0x1a1a1a,
        strokeWidth: 5,
        alpha: 0.5
    },
    highlightColor: 0xff0000
};


// ---------------------------------------------------------
// TrajectoryGeometry
// ---------------------------------------------------------
class TrajectoryGeometry {
    private circle: Graphics;
    private trajectory: Graphics;
    selected = false;
    filtered = false;
    lastFrame?: number;

    constructor(
        private renderer: TrajectoryRenderer,
        // @ts-ignore
        private app: Application,
        public trackingId: number,
        public group?: string
    ) {
        this.circle = this.createCircle();
        this.trajectory = this.createTrajectory();
        this.hide();

        this.circle.on("pointerover", () => this.setHighlight(true));
        this.circle.on("pointerout", () => this.setHighlight(false));
        this.circle.on("click", () => this.toggleSelect());
    }

    private createCircle(): Graphics {
        const c = new Graphics()
            .circle(0, 0, DEFAULT_STYLE.circle.radius)
            .fill(DEFAULT_STYLE.circle.fill)
            .stroke({
                width: DEFAULT_STYLE.circle.strokeWidth,
                color: DEFAULT_STYLE.circle.strokeColor
            });
        c.interactive = true;
        c.cursor = "pointer";
        c.hitArea = new Circle(0, 0, DEFAULT_STYLE.circle.radius);
        return c;
    }

    private createTrajectory(): Graphics {
        return new Graphics().stroke({
            width: DEFAULT_STYLE.trajectory.strokeWidth,
            color: DEFAULT_STYLE.trajectory.strokeColor,
            alpha: DEFAULT_STYLE.trajectory.alpha
        });
    }

    private setHighlight(active: boolean) {
        const color = active || this.selected ? DEFAULT_STYLE.highlightColor : DEFAULT_STYLE.circle.strokeColor;
        this.circle.clear()
            .circle(0, 0, DEFAULT_STYLE.circle.radius)
            .fill(DEFAULT_STYLE.circle.fill)
            .stroke({ width: DEFAULT_STYLE.circle.strokeWidth, color });
    }

    private toggleSelect() {
        this.selected ? this.renderer.dispatch("deselect", this.trackingId) : this.renderer.dispatch("select", this.trackingId);
    }

    select(selected: boolean) {
        this.selected = selected;
        this.setHighlight(false);
    }

    position(x: number, y: number) {
        this.circle.position.set(x, y);
    }

    draw(frame: number, points: { x: number; y: number }[]) {
        points.forEach((p, i) => {
            if (i === 0 || this.lastFrame === undefined) this.trajectory.moveTo(p.x, p.y);
            else this.trajectory.lineTo(p.x, p.y).stroke();
            this.lastFrame = frame;
        });
    }

    addToContainer(container: Container) {
        container.addChild(this.trajectory, this.circle);
    }

    show() {
        if (!this.filtered) {
            this.circle.visible = this.trajectory.visible = true;
        }
    }

    hide(persist = false) {
        this.circle.visible = false;
        if (!persist) this.trajectory.visible = false;
    }

    clear(persist = false) {
        this.lastFrame = undefined;
        if (!persist) this.trajectory.clear();
    }

    updateColors(color: number | string) {
        this.circle.clear()
            .circle(0, 0, DEFAULT_STYLE.circle.radius)
            .fill(DEFAULT_STYLE.circle.fill)
            .stroke({ width: DEFAULT_STYLE.circle.strokeWidth, color });
        this.trajectory.clear()
            .stroke({ width: DEFAULT_STYLE.trajectory.strokeWidth, color, alpha: DEFAULT_STYLE.trajectory.alpha });
    }

    defaultColors() {
        const color = this.selected ? DEFAULT_STYLE.highlightColor : DEFAULT_STYLE.circle.strokeColor;
        this.circle.clear()
            .circle(0, 0, DEFAULT_STYLE.circle.radius)
            .fill(DEFAULT_STYLE.circle.fill)
            .stroke({ width: DEFAULT_STYLE.circle.strokeWidth, color });
        this.trajectory.clear()
            .stroke({ width: DEFAULT_STYLE.trajectory.strokeWidth, color: DEFAULT_STYLE.trajectory.strokeColor, alpha: DEFAULT_STYLE.trajectory.alpha });
    }

    showTrajectory() {
        if (!this.filtered) {
            this.trajectory.visible = true;
        }
    }
}

interface TrajectoryRendererEvents {
    "select": Array<(trackingId: number) => void>,
    "deselect": Array<(trackingId: number) => void>,
    "initialized": Array<() => void>
};

export class TrajectoryRenderer {
    private app: Application;
    private started = false;
    private geoms: Record<number, TrajectoryGeometry> = {};
    private onScreen: TrajectoryGeometry[] = [];

    public fullViewport: Viewport;
    public panes: Record<string, Viewport> = {};

    private filtered = false;
    private tiled = false;
    public persistenceMode = false;
    private persistenceLastFrameTracker: Record<number, number | undefined> = {}
    private lastRenderedFrame = -1;

    private selected: Array<TrajectoryGeometry> = [];
    private events: TrajectoryRendererEvents = {
        "select": [],
        "deselect": [],
        "initialized": []
    };

    constructor(
        private controller: Controller,
        private element: HTMLDivElement,
        private trajectories: Trajectories,
        private config: RenderConfig
    ) {
        this.app = new Application();
        this.fullViewport = makeViewport(config.width, config.height, config.xlim, config.ylim);
        this.init();
    }

    dispatch(name: string, ...args: any[]) {
        // @ts-ignore
        this.events[name].forEach(f => f(...args));
    }

    addEventListener(name: string, handler: any) {
        // @ts-ignore
        this.events[name].push(handler);
    }

    removeEventListener(name: string, handler: any) {
        if (!this.events.hasOwnProperty(name)) return;
        // @ts-ignore
        const index = this.events[name].indexOf(handler);
        if (index != -1)
            // @ts-ignore
            this.events[name].splice(index, 1);
    }

    private async init() {
        await this.app.init({
            width: this.config.width,
            height: this.config.height,
            background: "#f6f3ec",
            antialias: true,
            eventMode: "static"
        });
        this.app.stage.interactive = true;
        this.app.canvas.style.width = "960px";
        this.app.canvas.style.height = "540px";
        this.app.stage.addChild(this.fullViewport.container);

        // Create window groups dynamically
        for (const {key} of this.config.windowGroups ?? []) {
            this.panes[key] = makeViewport(this.config.width, this.config.height, this.config.xlim, this.config.ylim);
            const border = new Graphics();
            border.rect(2, 2, this.panes[key].container.width, this.panes[key].container.height).stroke({width: 50, color: 0xff0000});
            this.panes[key].container.addChild(border);
        }

        this.element.querySelector("#viewport")?.appendChild(this.app.canvas);
        if (this.config.background) this.drawBackground(this.config.background);
        this.addGeometries();
        this.started = true;

        // borders
        const border = new Graphics();
        border.rect(0, 0, this.fullViewport.container.width, this.fullViewport.container.height).stroke({width: 16, color: 0x000000});
        this.fullViewport.container.addChild(border);
        for (const {key, name} of this.config.windowGroups ?? []) {
            const border = new Graphics();
            border.rect(0, 0, this.panes[key].container.width, this.panes[key].container.height).stroke({width: 16, color: 0x000000});
            this.panes[key].container.addChild(border);

            const text = new HTMLText({text: name, style: {
                fontFamily: "Arial",
                fontSize: 72,
                fill: 0x000000,
                stroke: 0x000000,
                align: "center",
                textBaseline: "middle"
            }});

            // Set position (relative to the container)
            text.x = this.panes[key].container.width / 2 - 300;
            text.y = 50;

            this.panes[key].container.addChild(text);
        }
        //
        this.dispatch("initialized");
    }

    private addGeometries() {
        Object.keys(this.trajectories.tracks).forEach(id => {
            const tid = Number(id);
            this.geoms[tid] = new TrajectoryGeometry(
                this,
                this.app,
                tid,
                this.trajectories.trajectories[tid][0].metaData.getGroup("body_orientation"));
            this.geoms[tid].addToContainer(this.fullViewport.container);
        });
    }

    // Background uses current viewport’s scale
    private drawBackground(background: BackgroundType, viewport = this.fullViewport) {
        const makeGraphic = (geomDef: any) => {
            const g = new Graphics()
                .poly(
                    geomDef.points.map((p: { x: number; y: number }) => [
                        viewport.xscale.inv(p.x),
                        viewport.yscale.inv(p.y)
                    ]).flat(),
                    geomDef.closed
                )
                .fill(geomDef.fill);
            if (geomDef.stroke) {
                g.stroke({ width: 10, color: geomDef.stroke });
            }
            return g;
        };

        for (const geomDef of Object.values(background)) {
            const base = makeGraphic(geomDef);
            viewport.container.addChild(base);
            for (const pane of Object.values(this.panes)) {
                pane.container.addChild(makeGraphic(geomDef));
            }
        }
    }

    getWindowPane(group: string) {
        return this.panes[group];
    }

    addToContainer(group?: string, ...objects: Graphics[]) {
        this.fullViewport.container.addChild(...objects);
        if (group == undefined) return;
        this.getWindowPane(group).container.addChild(...objects);
    }

    toggleFilter(columns: string[], value: string) {
        this.filtered = !this.filtered;
        if (!this.filtered) {
            Object.keys(this.geoms).forEach(tid => {
                this.geoms[Number(tid)].filtered = false;
            });
        }
        Object.keys(this.geoms)
              .filter(tid => this.trajectories.getGroup(Number(tid), ...columns) !== String(value))
              .forEach(tid => {
                    this.geoms[Number(tid)].filtered = true;
                    this.geoms[Number(tid)].hide();
              });
    }

    toggleViewMode() {
        if (!this.started) return;
        this.tiled = !this.tiled;
        this.app.stage.removeChildren();

        if (this.tiled) {
            this.arrangeTiledWindows();
            Object.values(this.geoms)
                  .forEach(geom => {
                    if (geom.group !== undefined) {
                        geom.addToContainer(this.getWindowPane(geom.group).container)
                    }
                });
        }
        else {
            this.app.stage.addChild(this.fullViewport.container);
            Object.values(this.geoms).forEach(geom => geom.addToContainer(this.fullViewport.container));
        }
    }

    private arrangeTiledWindows() {
        const n = Object.keys(this.panes).length;
        if (n === 0) return;

        const cols = Math.ceil(Math.sqrt(n));
        const rows = Math.ceil(n / cols);
        const paneW = this.config.width / cols;
        const paneH = this.config.height / rows;

        let i = 0;
        for (const pane of Object.values(this.panes)) {
            const col = i % cols;
            const row = Math.floor(i / cols);
            pane.container.x = col * paneW;
            pane.container.y = row * paneH;
            pane.container.scale.set(paneW / this.config.width, paneH / this.config.height);

            // Update each pane’s scale domain/range dynamically
            pane.xscale = new LinearScale([0, paneW], this.config.xlim);
            pane.yscale = new LinearScale([0, paneH], this.config.ylim);

            this.app.stage.addChild(pane.container);
            i++;
        }
    }

    togglePersistMode() {
        this.persistenceMode = !this.persistenceMode;
        Object.keys(this.persistenceLastFrameTracker)
              .forEach(tid => {this.persistenceLastFrameTracker[Number(tid)] = undefined});
    }

    render(frame: number) {
        if (!this.started) return;

        const frameLabel = this.element.querySelector("#frame");
        const timeLabel = this.element.querySelector("#time");
        frameLabel && (frameLabel.textContent = `${frame}`);
        timeLabel && (timeLabel.textContent = `${this.controller.time(frame)} / ${this.controller.time(this.controller.nframes)}`);

        // Hide geometries that are no longer visible
        this.updateVisibility(frame);

        const points = this.trajectories.getTrajectoryPointsByFrame(frame);
        if (!points) return;

        for (const point of points) {
            const geom = this.geoms[point.trackingId];
            geom.show();
            if (!this.onScreen.includes(geom)) {
                this.onScreen.push(geom);
            }

            geom.position(
                this.fullViewport.xscale.inv(point.x),
                this.fullViewport.yscale.inv(point.y)
            );

            let trajectory;
            if (geom.lastFrame === undefined || frame < geom.lastFrame) {
                geom.clear();
                trajectory = this.trajectories.getTrajectoryByTrackingIdToFrame(
                    geom.trackingId,
                    frame
                );
            } else if (geom.lastFrame < frame) {
                trajectory =
                    this.trajectories.getTrajectoryByTrackingIdBetweenFrames(
                        geom.trackingId,
                        geom.lastFrame,
                        frame
                    );
            }

            if (trajectory !== undefined) {
                geom.draw(
                    frame,
                    trajectory.map(tp => ({
                        x: this.fullViewport.xscale.inv(tp.x),
                        y: this.fullViewport.yscale.inv(tp.y)
                    }))
                );
                this.persistenceLastFrameTracker[geom.trackingId] = frame;
            }
        }

        if (this.persistenceMode === true) {
            // add new ones
            this.trajectories
                .getNewTrajectories(this.lastRenderedFrame, frame)
                .filter(tid => !this.onScreen.includes(this.geoms[Number(tid)]))
                .forEach(tid => {
                    const geom = this.geoms[Number(tid)];
                    geom.showTrajectory();
                    this.onScreen.push(geom);
                });
        }

        this.lastRenderedFrame = frame;
    }

    private updateVisibility(frame: number) {
        this.onScreen = this.onScreen.filter(geom => {
            const intervals = this.trajectories.tracks[geom.trackingId];
            const firstFrame = Math.min(...intervals.map(i => i.start));
            const lastFrame = Math.max(...intervals.map(i => i.end));

            if (frame < firstFrame) {
                geom.hide();
                geom.clear();
                this.persistenceLastFrameTracker[geom.trackingId] = undefined;
                return false;
            } else if (lastFrame < frame) {
                geom.hide(this.persistenceMode);
                geom.clear(this.persistenceMode);
                if (this.persistenceMode === false) {
                    return false;
                // @ts-ignore
                } else if (this.persistenceMode === true && (this.persistenceLastFrameTracker[geom.trackingId] === undefined || this.persistenceLastFrameTracker[geom.trackingId] < lastFrame)) {
                    const trajectory = this.trajectories.getTrajectoryByTrackingIdBetweenFrames(
                        geom.trackingId,
                        // @ts-ignore
                        (this.persistenceLastFrameTracker[geom.trackingId] === undefined) ? firstFrame : this.persistenceLastFrameTracker[geom.trackingId],
                        lastFrame
                    );
                    this.persistenceLastFrameTracker[geom.trackingId] = lastFrame;
                    geom.draw(
                        lastFrame,
                        trajectory.map(tp => ({
                            x: this.fullViewport.xscale.inv(tp.x),
                            y: this.fullViewport.yscale.inv(tp.y)
                        }))
                    );
                }
            }
            return true;
        });
    }

    deselectAll() {
        this.selected.forEach(geom => geom.select(false));
        this.selected = [];
    }

    select(trackingId: number) {
        if (trackingId in this.geoms) {
            this.geoms[trackingId].select(true);
            this.selected.push(this.geoms[trackingId]);
        }
    }

    freshRender(frame: number) {
        this.onScreen.forEach(geom => geom.lastFrame = undefined);
        Object.keys(this.persistenceLastFrameTracker).forEach(tid => {
            this.persistenceLastFrameTracker[Number(tid)] = undefined;
        });
        this.render(frame);
    }

    // Color geoms according to a group and a mapping
    colorByGroup(groupKey: string, coloring: Record<string, string | number>) {
        Object.keys(this.geoms)
              .forEach(trackingId => {
            const geom = this.geoms[Number(trackingId)];
            const group = this.trajectories.getGroup(geom.trackingId, groupKey)
            if (group in coloring) {
                geom.updateColors(coloring[group]);
            }
        });
        this.freshRender(this.lastRenderedFrame);
    }

    // Reset all geoms to their default color
    resetColors() {
        Object.keys(this.geoms)
              .forEach(trackingId => this.geoms[Number(trackingId)].defaultColors());
        this.freshRender(this.lastRenderedFrame);
    }
}
