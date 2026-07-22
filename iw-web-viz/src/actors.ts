import { Graphics, Sprite, Texture } from "pixi.js";
import type { Viewport } from "./viz";

interface ActorState {
    x: number;
    y: number;
    angle: number; // degrees
    visible: boolean;
}

export interface ConditionConfig {
    actor1: ActorState;
    actor2: ActorState;
}

export type ConditionMap = Record<string, ConditionConfig>;

export class Actors {
    private conditions: ConditionMap;

    private actor1: Sprite;
    private actor2: Sprite;
    private viewLine1: Graphics;
    private viewLine2: Graphics;
    private viewport: Viewport;

    private viewLinesVisible = true;

    constructor(texture: Texture, conditions: ConditionMap, viewport: Viewport) {
        this.conditions = conditions;
        this.viewport = viewport;

        this.viewLine1 = new Graphics().setStrokeStyle({width: 4, color: 0xff0000, alpha: 0.5});
        this.viewport.container.addChild(this.viewLine1);
        this.viewLine2 = new Graphics().setStrokeStyle({width: 4, color: 0xff0000, alpha: 0.5});
        this.viewport.container.addChild(this.viewLine2);

        this.actor1 = new Sprite(texture);
        this.actor2 = new Sprite(texture);
        this.viewport.container.addChild(this.actor1);
        this.viewport.container.addChild(this.actor2);
        this.actor1.anchor.set(0.5);
        this.actor2.anchor.set(0.5);
    }

    update(condition: string) {
        const config = this.conditions[condition];
        if (!config) return;

        this.applyState(this.actor1, config.actor1);
        this.applyState(this.actor2, config.actor2);
        const distance = 118;
        const angle1Rad = (this.actor1.angle * Math.PI) / 180;
        const angle2Rad = (this.actor2.angle * Math.PI) / 180;
        this.viewLine1
            .clear()
            .moveTo(this.viewport.xscale.inv(config.actor1.x), this.viewport.yscale.inv(config.actor1.y))
            .lineTo(this.viewport.xscale.inv(config.actor1.x) + distance*Math.cos(angle1Rad), this.viewport.yscale.inv(config.actor1.y) + distance*Math.sin(angle1Rad))
            .stroke();

        this.viewLine2
            .clear()
            .moveTo(this.viewport.xscale.inv(config.actor2.x), this.viewport.yscale.inv(config.actor2.y))
            .lineTo(this.viewport.xscale.inv(config.actor2.x) + distance*Math.cos(angle2Rad), this.viewport.yscale.inv(config.actor2.y) + distance*Math.sin(angle2Rad))
            .stroke();

        const actor1Visible = config.actor1.visible;
        const actor2Visible = config.actor2.visible;
        this.actor1.visible = actor1Visible;
        this.actor2.visible = actor2Visible;
        this.viewLine1.visible = actor1Visible && this.viewLinesVisible;
        this.viewLine2.visible = actor2Visible && this.viewLinesVisible;
    }

    private applyState(sprite: Sprite, state: ActorState) {
        sprite.position.set(this.viewport.xscale.inv(state.x), this.viewport.yscale.inv(state.y))
        sprite.rotation = state.angle;
        sprite.scale.set(0.75);
        if (state.angle !== undefined) {
            sprite.rotation = (state.angle * Math.PI) / 180;
        }
    }

    toggleViewLines() {
        this.viewLinesVisible = !this.viewLinesVisible;
        this.viewLine1.visible = this.viewLinesVisible;
        this.viewLine2.visible = this.viewLinesVisible;
    }

    setAlpha(alpha: number) {
        this.actor1.alpha = alpha;
        this.actor2.alpha = alpha;
    }
}
