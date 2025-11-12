import type { Middleware, Rect, Placement, MiddlewareArguments, Coords } from '../types';
import { Options as DetectOverflowOptions } from '../detectOverflow';
export declare type Options = {
    mainAxis: boolean;
    crossAxis: boolean;
    limiter: {
        fn: (middlewareArguments: MiddlewareArguments) => Coords;
        options?: any;
    };
};
export declare const shift: (options?: Partial<Options & DetectOverflowOptions>) => Middleware;
declare type LimitShiftOffset = ((args: {
    placement: Placement;
    floating: Rect;
    reference: Rect;
}) => number | {
    mainAxis?: number;
    crossAxis?: number;
}) | number | {
    mainAxis?: number;
    crossAxis?: number;
};
export declare type LimitShiftOptions = {
    offset: LimitShiftOffset;
    mainAxis: boolean;
    crossAxis: boolean;
};
export declare const limitShift: (options?: Partial<LimitShiftOptions>) => {
    options: Partial<LimitShiftOffset>;
    fn: (middlewareArguments: MiddlewareArguments) => Coords;
};
export {};
