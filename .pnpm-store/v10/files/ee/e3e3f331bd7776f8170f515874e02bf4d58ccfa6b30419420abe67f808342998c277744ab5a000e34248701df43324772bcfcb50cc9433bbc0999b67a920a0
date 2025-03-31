import type { Middleware, MiddlewareArguments, SideObject } from '@floating-ui/core';
import type { Options as DetectOverflowOptions } from '@floating-ui/core/src/detectOverflow';
import type { Options as AutoPlacementOptions } from '@floating-ui/core/src/middleware/autoPlacement';
import type { Options as SizeOptions } from '@floating-ui/core/src/middleware/size';
import type { Options as FlipOptions } from '@floating-ui/core/src/middleware/flip';
import type { Options as ShiftOptions } from '@floating-ui/core/src/middleware/shift';
export declare type NodeScroll = {
    scrollLeft: number;
    scrollTop: number;
};
export declare type DOMDetectOverflowOptions = Omit<DetectOverflowOptions, 'boundary'> & {
    boundary: 'clippingParents' | Element | Array<Element>;
};
declare const autoPlacement: (options?: Partial<AutoPlacementOptions & DOMDetectOverflowOptions>) => Middleware;
declare const shift: (options?: Partial<ShiftOptions & DOMDetectOverflowOptions>) => Middleware;
declare const flip: (options?: Partial<FlipOptions & DOMDetectOverflowOptions>) => Middleware;
declare const size: (options?: Partial<SizeOptions & DOMDetectOverflowOptions>) => Middleware;
declare const arrow: (options: {
    element: HTMLElement;
    padding?: number | SideObject;
}) => Middleware;
declare const detectOverflow: (middlewareArguments: MiddlewareArguments, options?: Partial<DOMDetectOverflowOptions>) => Promise<SideObject>;
export { autoPlacement, shift, arrow, size, flip, detectOverflow };
export { hide, offset, limitShift, inline } from '@floating-ui/core';
export type { Platform, Placement, Strategy, Middleware, } from '@floating-ui/core';
export { computePosition } from './';
export { getScrollParents } from './utils/getScrollParents';
