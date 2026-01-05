import { Assets } from "pixi.js";
import "./style.css"
export { Controller } from "./controller.ts";
export { Actors } from "./actors.ts";
export async function loadActorTexture(url: string) {
    return Assets.load(url);
}
