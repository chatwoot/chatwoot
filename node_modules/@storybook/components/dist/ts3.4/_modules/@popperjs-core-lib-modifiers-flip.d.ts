import { Placement, Boundary, RootBoundary } from "./@popperjs-core-lib-enums";
import { Modifier, Padding } from "./@popperjs-core-lib-types";
export declare type Options = {
    mainAxis: boolean;
    altAxis: boolean;
    fallbackPlacements: Array<Placement>;
    padding: Padding;
    boundary: Boundary;
    rootBoundary: RootBoundary;
    altBoundary: boolean;
    flipVariations: boolean;
    allowedAutoPlacements: Array<Placement>;
};
export declare type FlipModifier = Modifier<"flip", Options>;
declare const _default: FlipModifier;
export default _default;
