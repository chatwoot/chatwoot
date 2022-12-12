import type { Modifier, Padding, Rect } from "./@popperjs-core-lib-types";
import type { Placement } from "./@popperjs-core-lib-enums";
export declare type Options = {
    element: HTMLElement | string | null;
    padding: Padding | ((arg0: {
        popper: Rect;
        reference: Rect;
        placement: Placement;
    }) => Padding);
};
export declare type ArrowModifier = Modifier<"arrow", Options>;
declare const _default: ArrowModifier;
export default _default;