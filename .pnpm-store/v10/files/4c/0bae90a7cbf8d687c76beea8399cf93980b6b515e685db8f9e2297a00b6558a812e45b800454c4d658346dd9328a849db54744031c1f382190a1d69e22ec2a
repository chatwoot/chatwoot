import type { Middleware, Placement, Alignment } from '../types';
import { Options as DetectOverflowOptions } from '../detectOverflow';
export declare function getPlacementList(alignment: Alignment | null, autoAlignment: boolean, allowedPlacements: Array<Placement>): Placement[];
export declare type Options = {
    alignment: Alignment | null;
    allowedPlacements: Array<Placement>;
    autoAlignment: boolean;
};
export declare const autoPlacement: (options?: Partial<Options & DetectOverflowOptions>) => Middleware;
