import type { Placement, Rect, Coords, Middleware } from '../types';
declare type OffsetValue = number | {
    mainAxis?: number;
    crossAxis?: number;
};
declare type OffsetFunction = (args: {
    floating: Rect;
    reference: Rect;
    placement: Placement;
}) => OffsetValue;
export declare type Options = OffsetValue | OffsetFunction;
export declare function convertValueToCoords({ placement, rects, value, }: {
    placement: Placement;
    rects: {
        floating: Rect;
        reference: Rect;
    };
    value: Options;
}): Coords;
export declare const offset: (value?: Options) => Middleware;
export {};
