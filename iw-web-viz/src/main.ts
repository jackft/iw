import './style.css'
import 'tabulator-tables/dist/css/tabulator.min.css';
import { Controller } from './controller.ts'
import rawTrajectoryData from './experiment_2_trajectory_2023-12-06.json'
import rawData from './experiment_2_2023-12-06.json'
import rawBackground from './mural.json'
import type { BackgroundType, RenderConfig, TrajectoryMeta, TrajectoryObservation } from './datastructures.ts';
import { Actors } from './actors.ts'
import type { ConditionMap } from './actors.ts'
import type { ColumnDefinition } from 'tabulator-tables';
import { Assets } from 'pixi.js';

const tableOptions: ColumnDefinition[] =  [
  {title: "person_id",field: "person_id", headerFilter: "input" },
  {title: "condition", field: "body_orientation", headerFilter: "list", headerFilterFunc: "=", headerFilterParams: {
          values: {Baseline: "Baseline", FaceToFace: "FaceToFace", BackToBack: "BackToBack", FacingOffset: "FacingOffset"}
      }
  },
  {title: "gender", field: "pedestrian_gender", headerFilter: "list", headerFilterFunc: "=", headerFilterParams: {
          values: { Male: "Male", Female: "Female" }
      }
  },
  {title: "transportation", field: "transportation", headerFilter: "list", headerFilterFunc: "=", headerFilterParams: {
          values: {Walking: "Walking", Scooter: "Scooter", Bike: "Bike", Skateboard: "Skateboard"}
      }
  },
  {title: "direction", field: "pedestrian_direction", headerFilter: "list", headerFilterFunc: "=", headerFilterParams: {
          values: {Left: "Left", Right: "Right"}
      }
  },
  {title: "pedestrian_on_phone", field: "pedestrian_on_phone"},
  {title: "breach", field: "breach"}
];

const trajectoryData = rawTrajectoryData as TrajectoryObservation[];
const trajectoryMetaData = rawData as TrajectoryMeta[];
const background = rawBackground as BackgroundType;
const config: RenderConfig = {xlim: [-1500, 1000], ylim: [-500, 1000], width: 1920, height: 1080, background: background, windowGroups: [{key: "Baseline", name: "Baseline"}, {key: "FaceToFace", name: "Face to face"}, {key: "BackToBack", name: "Back to back"}, {key: "OffsetFacing", name: "45° offset facing"}]};
const controller = new Controller(document.querySelector<HTMLDivElement>('#app')!, trajectoryData, trajectoryMetaData, tableOptions, config);
controller.renderer.persistenceMode = false;
controller.play();

window.addEventListener("keydown", (e) => {
    console.log(e.key);
    switch (e.key) {
        case "Tab":
            e.preventDefault(); // prevent browser focus switch
            controller.renderer.toggleViewMode();
            break;
        case " ": // space
            controller.togglePlay();
            break;
        case "ArrowRight":
            controller.stepForward();
            break;
        case "ArrowLeft":
            controller.stepBackward();
            break;
        case "ArrowUp":
            controller.increaseSpeed();
            break;
        case "ArrowDown":
            controller.decreaseSpeed();
            break;
        default:
            break;
    }
  }
);

controller.createColorDropdowns(["condition", "direction", "gender", "breach", "transportation"])
controller.addEventListener("colorBy", (group: string) => {
    switch(group) {
        case "none":
            controller.renderer.resetColors();
            controller.updateLegend(null);
            break;
        case "gender":
            const genderMapping = {Male: "#4dbbd5", Female: "#f48f3d"};
            controller.renderer.colorByGroup("pedestrian_gender", genderMapping);
            controller.updateLegend(genderMapping, "Gender")
            break;
        case "condition":
            const conditionMapping = {
                FaceToFace: "#00a087", BackToBack: "#f48f3d",
                OffsetFacing: "#4dbbd5", Baseline: "#000000"
            }
            controller.renderer.colorByGroup("body_orientation", conditionMapping);
            controller.updateLegend(conditionMapping, "Body Orientation Condition");
            break;
        case "breach":
            const breachMapping = {
                0: "#4dbbd5", 1: "#e44c37"
            };
            controller.renderer.colorByGroup("breach", breachMapping);
            controller.updateLegend(breachMapping, "Breaching Outcome");
            break;
        case "direction":
            const directionMapping = {
                Left: "#000000", Right: "#0fa18a"
            }
            controller.renderer.colorByGroup("pedestrian_direction", directionMapping);
            controller.updateLegend(directionMapping, "Pedestrian Direction");
            break;
        case "transportation":
            const transportationMapping ={
                Skateboard: "#00a087", Scooter: "#f48f3d",
                Bike: "#4dbbd5", Walking: "#000000"
            }
            controller.renderer.colorByGroup("transportation", transportationMapping);
            controller.updateLegend(transportationMapping, "Transportation");
            break;
        default:
            controller.renderer.resetColors();
            break;
    }
});

const faceToFaceConfig = {
    actor1: {x: -280, y: 0, angle: 90, visible: true},
    actor2: {x: -280, y: 326, angle: 270, visible: true}
}
const backToBackConfig = {
    actor1: {x: -280, y: 0, angle: 270, visible: true},
    actor2: {x: -280, y: 326, angle: 90, visible: true}
}
const offsetFacing = {
    actor1: {x: -280, y: 0, angle: 135, visible: true},
    actor2: {x: -280, y: 326, angle: 225, visible: true}
}

const conditions: ConditionMap = {
    "FaceToFace": faceToFaceConfig,
    "BackToBack": backToBackConfig,
    "OffsetFacing": offsetFacing 
};


controller.addEventListener("initialized", async () => {
    console.log("awaiting");
    const texture = await Assets.load("/assets/actor.png");
    console.log("got texture");
    const fullViewportActors = new Actors(texture, conditions, controller.renderer.fullViewport);
    fullViewportActors.update("FaceToFace");
    const paneActors = Object.keys(controller.renderer.panes)
          .map(condition => {
            if (condition === "Baseline") return;
            const pane = controller.renderer.panes[condition];
            const paneActors = new Actors(texture, conditions, pane);
            paneActors.update(condition);
            return paneActors;
          })

    document.querySelector<HTMLDivElement>('#app')!.querySelector<HTMLButtonElement>("#sightButton")!.addEventListener("click", () => {
        fullViewportActors.toggleViewLines();
        paneActors.forEach(pa => pa?.toggleViewLines());
    });

    controller.addEventListener("frameUpdated", (frame: number) => {
        if (1000 < frame && frame < 2000) {
            console.log(frame);
            fullViewportActors.update("OffsetFacing");
        }
        if (2000 < frame) {
            fullViewportActors.update("BackToBack");
        }
    });
});
