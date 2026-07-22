import type { TrajectoryObservation, RenderConfig, TrajectoryMeta } from "./datastructures.ts";
import { Trajectories } from "./datastructures.ts";
import { TrajectoryRenderer } from "./viz.ts";
import { TabulatorFull as Tabulator, type ColumnDefinition, type RowComponent } from 'tabulator-tables';

// ---------------------------------------------------------
// Configuration constants
// ---------------------------------------------------------
const PLAYBACK = {
    minSpeed: 0.25,
    maxSpeed: 60,
    step: 0.25
};

// ---------------------------------------------------------
// Controller Class
// ---------------------------------------------------------

interface ControllerEvents {
    "colorBy": Array<(group: string) => void>,
    "initialized": Array<(controller: Controller) => void>,
    "frameUpdated": Array<(frame: number) => void>
    "seekedFrame": Array<(frame: number) => void>
    "speedChange": Array<(rate: number) => void>
    "play": Array<() => void>
    "pause": Array<() => void>
};

export class Controller {
    fps = 29.97;
    frame = 0;
    nframes = 30 * 60;
    playbackRate = 1;
    paused = true;

    private element: HTMLDivElement;
    renderer: TrajectoryRenderer;
    private trajectories: Trajectories;

    public table: Tabulator;

    private _startPlaybackTime?: number;
    private _pausedPlaybackTime = 0;

    private _slider: HTMLInputElement;
    private _playPauseButton: HTMLButtonElement;
    private _speedLabel: HTMLElement;
    private _tileButton: HTMLInputElement;
    private _trailButton: HTMLInputElement;
    private _filterButton: HTMLInputElement;
    private _tableDiv: HTMLDivElement;
    private _colorBySelect: HTMLSelectElement;
    private _speedButton: HTMLButtonElement;
    private _slowButton: HTMLButtonElement;

    private events: ControllerEvents = {
        "colorBy": [],
        "initialized": [],
        "frameUpdated": [],
        "seekedFrame": [],
        "speedChange": [],
        "play": [],
        "pause": [],
    };

    constructor(element: HTMLDivElement, trajectoryData: TrajectoryObservation[], metaData: TrajectoryMeta[], columnsDef: ColumnDefinition[], renderConfig: RenderConfig) {
        this.element = element;
        this.trajectories = new Trajectories(trajectoryData, metaData);
        this.nframes = Math.max(...Object.keys(this.trajectories.frames).map(Number));

        this.element.innerHTML = this.buildUI();
        this._slider = element.querySelector<HTMLInputElement>("#slider")!;
        this._playPauseButton = element.querySelector<HTMLButtonElement>("#playPause")!;
        this._speedLabel = element.querySelector<HTMLElement>("#speedLabel")!;
        this._tileButton = element.querySelector<HTMLInputElement>("#tileButton")!;
        this._trailButton = element.querySelector<HTMLInputElement>("#trailButton")!;
        this._filterButton = element.querySelector<HTMLInputElement>("#filterButton")!;
        this._colorBySelect = element.querySelector<HTMLSelectElement>("#colorBySelect")!;
        this._speedButton = element.querySelector<HTMLButtonElement>("#speedButton")!;
        this._slowButton = element.querySelector<HTMLButtonElement>("#slowButton")!;

        this._slider.addEventListener("input", e => this.seekToFrame((e.target as HTMLInputElement).valueAsNumber));
        this._playPauseButton.addEventListener("click", () => this.togglePlay());
        this._tileButton.addEventListener("click", () => this.renderer.toggleViewMode());
        this._trailButton.addEventListener("click", () => this.renderer.togglePersistMode());
        this._filterButton.addEventListener("click", () => this.renderer.toggleFilter(["entry_location", "exit_location", "pedestrian_passes_wall_area"], "top:top:1"));
        this._speedButton.addEventListener("click", () => this.increaseSpeed());
        this._slowButton.addEventListener("click", () => this.decreaseSpeed());

        this._tableDiv = element.querySelector<HTMLDivElement>("#table")!;
        this.table = new Tabulator(this._tableDiv, {
          height: "250px",
          layout: "fitColumns",
          data: metaData,
          selectableRows: 1,
          columns: columnsDef
        });

        // Renderer setup
        this.renderer = new TrajectoryRenderer(this, element, this.trajectories, renderConfig);

        requestAnimationFrame((timestamp) => this.playbackLoop(timestamp));

        this.table.on("rowClick", (_, row: RowComponent) => this.select(row.getData()["person_id"]));
        this.renderer.addEventListener("select", (trackingId: number) => this.select(trackingId));

        // events
        this._colorBySelect.addEventListener("change", () => this.dispatch("colorBy", this._colorBySelect.value));
        this.renderer.addEventListener("initialized", () => this.dispatch("initialized", this));

        // initial states
        if (this._filterButton.checked) {
            this.renderer.toggleFilter(["entry_location", "exit_location", "pedestrian_passes_wall_area"], "top:top:1");
        }
        if (this._trailButton.checked) {
            this.renderer.togglePersistMode();
        }
    }

    // ---------------------------------------------------------
    // UI setup
    // ---------------------------------------------------------
    private buildUI(): string {
        return `
        <div class="controller-container">
            <div id="viewport"></div>

            <input id="slider" type="range" min="0" max="${this.nframes - 1}" value="0" step="1" class="slider">

            <div class="controls-row">
                <div><button id="playPause" class="play-button iconplay-background"></button></div>
                <div class="info"><span>time:</span><span id="time"></span></div>
                <div class="info"><span>frame:</span><span id="frame"></span></div>
                <div class="info"><span id="speedLabel">Speed: ${this.playbackRate}×</span></div>
                <div><button id="slowButton" class="play-button iconslower-background"></button></div>
                <div><button id="speedButton" class="play-button iconfaster-background"></button></div>
            </div>
            <div class="controls-row" style="justify-content: center">

                <div class="control-toggle info">
                    <input type="checkbox" id="trailButton" class="toggle-input">
                    <label for="trailButton" class="toggle-label">Keep All Paths</label>
                    <input type="checkbox" id="tileButton" class="toggle-input">
                    <label for="tileButton" class="toggle-label">
                        <span>Facet By Condition</span>
                        <span class="icon icontile-background"></span>
                    </label>
                    <input type="checkbox" id="filterButton" class="toggle-input" checked>
                    <label for="filterButton" class="toggle-label">Only Near Passes</label>
                    <input type="checkbox" id="sightButton" class="toggle-input" checked>
                    <label for="sightButton" class="toggle-label">Actor Gaze</label>
                </div>

                <div class="info">
                    <label for="colorBySelect" style="margin-right: 4px;">Color by:</label>
                    <select id="colorBySelect" class="dropdown">
                    </select>
                </div>

            </div>

            <div id="colorLegend" class="controls-row" style="justify-content: center">
                <div class="info legend">
                    <span class="legend-label" id="colorLegendLabel"></span>   
                </div>
            </div>

            <div id="table" class="iw-datatable"></div>
        </div>`;
    }

    // ---------------------------------------------------------
    // Events
    // ---------------------------------------------------------

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

    // ---------------------------------------------------------
    // Playback loop
    // ---------------------------------------------------------
    private playbackLoop(timestamp: number) {
        if (this._startPlaybackTime === undefined) {
            this._startPlaybackTime = timestamp;
        }

        if (!this.paused) {
            const elapsed = (timestamp - this._startPlaybackTime) / 1000;
            const newFrame = Math.floor(elapsed * this.fps * this.playbackRate);
            const frameChanged = this.frame != newFrame;
            this.frame = newFrame;
            this.renderFrame(this.frame);
            if (frameChanged) this.dispatch("frameUpdated", this.frame);
        }

        requestAnimationFrame((t) => this.playbackLoop(t));
    }

    // ---------------------------------------------------------
    // Playback controls
    // ---------------------------------------------------------
    play() {
        this.paused = false;
        this._startPlaybackTime = performance.now() - this._pausedPlaybackTime;
        this._playPauseButton.classList.replace("iconplay-background", "iconpause-background");
        this.dispatch("play");
    }

    pause() {
        this.paused = true;
        this._pausedPlaybackTime = performance.now() - (this._startPlaybackTime || 0);
        this._playPauseButton.classList.replace("iconpause-background", "iconplay-background");
        this.dispatch("pause");
    }

    togglePlay() {
        this.paused ? this.play() : this.pause();
    }

    // ---------------------------------------------------------
    // Frame navigation
    // ---------------------------------------------------------
    seekToFrame(frame: number) {
        const deltaMs = (1000 * (frame - this.frame)) / (this.fps * this.playbackRate);

        if (this.paused) {
            this._pausedPlaybackTime += deltaMs;
        } else if (this._startPlaybackTime !== undefined) {
            this._startPlaybackTime -= deltaMs;
        }
        this.dispatch("seekedFrame", frame);
        this.renderFrame(frame);
    }

    stepForward() { this.seekToFrame(this.frame + 1); }
    stepBackward() { this.seekToFrame(this.frame - 1); }

    // ---------------------------------------------------------
    // Speed control
    // ---------------------------------------------------------
    increaseSpeed() {
        this.updatePlaybackRate(this.playbackRate + PLAYBACK.step);
    }

    decreaseSpeed() {
        this.updatePlaybackRate(this.playbackRate - PLAYBACK.step);
    }

    private updatePlaybackRate(newRate: number) {
        this.playbackRate = Math.min(Math.max(newRate, PLAYBACK.minSpeed), PLAYBACK.maxSpeed);
        this.dispatch("speedChange", this.playbackRate)
        this._speedLabel.textContent = `Speed: ${this.playbackRate}×`;

        if (!this.paused && this._startPlaybackTime !== undefined) {
            const now = performance.now();
            this._startPlaybackTime = now - (this.frame / (this.fps * this.playbackRate)) * 1000;
        }
    }

    // ---------------------------------------------------------
    // Frame rendering
    // ---------------------------------------------------------
    renderFrame(frame: number) {
        this.frame = Math.max(0, Math.min(frame, this.nframes - 1));
        this.renderer.render(this.frame);
        this._slider.value = String(this.frame);
    }

    // ---------------------------------------------------------
    // Utility
    // ---------------------------------------------------------
    time(frame: number): string {
        const seconds = frame / this.fps;
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        const s = Math.floor(seconds % 60);
        const ms = Math.floor((seconds - Math.floor(seconds)) * 1000);
        return `${h.toString().padStart(2, "0")}:${m.toString().padStart(2, "0")}:${s
            .toString()
            .padStart(2, "0")}.${ms.toString().padStart(3, "0")}`;
    }

    select(trackingId: number) {
        console.log(trackingId);
        // table
        this.table.deselectRow();
        this.table
            .getRows()
            .filter(r => r.getData().person_id === trackingId)
            .forEach(r => {
                r.select();
                this.table.scrollToRow(r, "center", false);
            });
        // renderer
        this.renderer.deselectAll();
        this.renderer.select(trackingId);
    }

    createColorDropdowns(options: Array<string>) {
        if (!this._colorBySelect) {
            console.warn("Dropdown element (this._colorBySelect) not found.");
            return;
        }

        this._colorBySelect.innerHTML = "";

        const allOptions = ["none", ...options];

        for (const key of allOptions) {
            const option = document.createElement("option");
            option.value = key;
            option.textContent = key;
            this._colorBySelect.appendChild(option);
        }

    }

    updateLegend(colorMap: Record<string, string> | null, title?: string) {
        const legend: HTMLDivElement = document.querySelector("#colorLegend")!;
        if (colorMap === null) {
            legend.style.visibility = 'hidden';
            return;
        }
        legend.style.visibility = 'visible';
        const legendContainer = document.querySelector(".legend");
        legendContainer!.innerHTML = `<span class="legend-label">${title}:</span>`;

        for (const [key, color] of Object.entries(colorMap)) {
            const item = document.createElement("div");
            item.className = "legend-item";

            const colorBox = document.createElement("span");
            colorBox.className = "legend-color";
            colorBox.style.backgroundColor = color;

            const label = document.createTextNode(key);

            item.appendChild(colorBox);
            item.appendChild(label);
            legendContainer!.appendChild(item);
        }
    }

}
