// src/assets.ts
import { Assets } from 'pixi.js';
import actorTextureUrl from '/assets/actor.png'; // works with Vite

export async function loadAssets() {
  const texture = await Assets.load(actorTextureUrl);
  return { actor: texture };
}
