import type { State, SideObject, Padding } from "./@popperjs-core-lib-types";
import type { Placement, Boundary, RootBoundary, Context } from "./@popperjs-core-lib-enums";
export declare type Options = {
    placement: Placement;
    boundary: Boundary;
    rootBoundary: RootBoundary;
    elementContext: Context;
    altBoundary: boolean;
    padding: Padding;
};
export default function detectOverflow(state: State, options?: Partial<Options>): SideObject;