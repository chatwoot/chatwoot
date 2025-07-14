import type { AutoPlacementOptions, ClientRectObject, ComputePositionConfig as CoreComputePositionConfig, DetectOverflowOptions as CoreDetectOverflowOptions, Dimensions, ElementRects, FlipOptions, HideOptions, Middleware as CoreMiddleware, MiddlewareArguments as CoreMiddlewareArguments, MiddlewareReturn, Padding, Rect, RootBoundary, ShiftOptions, SideObject, SizeOptions as CoreSizeOptions, Strategy } from '@floating-ui/core';
type Promisable<T> = T | Promise<T>;
export interface Platform {
    getElementRects: (args: {
        reference: ReferenceElement;
        floating: FloatingElement;
        strategy: Strategy;
    }) => Promisable<ElementRects>;
    getClippingRect: (args: {
        element: Element;
        boundary: Boundary;
        rootBoundary: RootBoundary;
        strategy: Strategy;
    }) => Promisable<Rect>;
    getDimensions: (element: Element) => Promisable<Dimensions>;
    convertOffsetParentRelativeRectToViewportRelativeRect?: (args: {
        rect: Rect;
        offsetParent: Element;
        strategy: Strategy;
    }) => Promisable<Rect>;
    getOffsetParent?: (element: Element) => Promisable<Element | Window>;
    isElement?: (value: unknown) => Promisable<boolean>;
    getDocumentElement?: (element: Element) => Promisable<HTMLElement>;
    getClientRects?: (element: Element) => Promisable<Array<ClientRectObject>>;
    isRTL?: (element: Element) => Promisable<boolean>;
    getScale?: (element: HTMLElement) => Promisable<{
        x: number;
        y: number;
    }>;
}
export interface NodeScroll {
    scrollLeft: number;
    scrollTop: number;
}
export type Boundary = 'clippingAncestors' | Element | Array<Element>;
export type DetectOverflowOptions = Omit<CoreDetectOverflowOptions, 'boundary'> & {
    boundary: Boundary;
};
export type SizeOptions = Omit<CoreSizeOptions, 'apply'> & {
    /**
     * Function that is called to perform style mutations to the floating element
     * to change its size.
     * @default undefined
     */
    apply(args: MiddlewareArguments & {
        availableWidth: number;
        availableHeight: number;
    }): Promisable<void>;
};
export type ComputePositionConfig = Omit<CoreComputePositionConfig, 'middleware' | 'platform'> & {
    middleware?: Array<Middleware | null | undefined | false>;
    platform?: Platform;
};
/**
 * Custom positioning reference element.
 * @see https://floating-ui.com/docs/virtual-elements
 */
export interface VirtualElement {
    getBoundingClientRect(): ClientRectObject;
    contextElement?: Element;
}
export type ReferenceElement = Element | VirtualElement;
export type FloatingElement = HTMLElement;
export interface Elements {
    reference: ReferenceElement;
    floating: FloatingElement;
}
export type MiddlewareArguments = Omit<CoreMiddlewareArguments, 'elements'> & {
    elements: Elements;
};
export type Middleware = Omit<CoreMiddleware, 'fn'> & {
    fn(args: MiddlewareArguments): Promisable<MiddlewareReturn>;
};
/**
 * Automatically chooses the `placement` which has the most space available.
 * @see https://floating-ui.com/docs/autoPlacement
 */
declare const autoPlacement: (options?: Partial<AutoPlacementOptions & DetectOverflowOptions>) => Middleware;
/**
 * Shifts the floating element in order to keep it in view when it will overflow
 * a clipping boundary.
 * @see https://floating-ui.com/docs/shift
 */
declare const shift: (options?: Partial<ShiftOptions & DetectOverflowOptions>) => Middleware;
/**
 * Changes the placement of the floating element to one that will fit if the
 * initially specified `placement` does not.
 * @see https://floating-ui.com/docs/flip
 */
declare const flip: (options?: Partial<FlipOptions & DetectOverflowOptions>) => Middleware;
/**
 * Provides data to change the size of the floating element. For instance,
 * prevent it from overflowing its clipping boundary or match the width of the
 * reference element.
 * @see https://floating-ui.com/docs/size
 */
declare const size: (options?: Partial<SizeOptions & DetectOverflowOptions>) => Middleware;
/**
 * Positions an inner element of the floating element such that it is centered
 * to the reference element.
 * @see https://floating-ui.com/docs/arrow
 */
declare const arrow: (options: {
    element: Element;
    padding?: Padding;
}) => Middleware;
/**
 * Provides data to hide the floating element in applicable situations, such as
 * when it is not in the same clipping context as the reference element.
 * @see https://floating-ui.com/docs/hide
 */
declare const hide: (options?: Partial<HideOptions & DetectOverflowOptions>) => Middleware;
/**
 * Resolves with an object of overflow side offsets that determine how much the
 * element is overflowing a given clipping boundary.
 * - positive = overflowing the boundary by that number of pixels
 * - negative = how many pixels left before it will overflow
 * - 0 = lies flush with the boundary
 * @see https://floating-ui.com/docs/detectOverflow
 */
declare const detectOverflow: (middlewareArguments: MiddlewareArguments, options?: Partial<DetectOverflowOptions>) => Promise<SideObject>;
export { arrow, autoPlacement, detectOverflow, flip, hide, shift, size };
export { computePosition } from './';
export { autoUpdate, Options as AutoUpdateOptions } from './autoUpdate';
export { platform } from './platform';
export { getOverflowAncestors } from './utils/getOverflowAncestors';
export type { AlignedPlacement, Alignment, Axis, ClientRectObject, ComputePositionReturn, Coords, Dimensions, ElementContext, ElementRects, Length, MiddlewareData, MiddlewareReturn, Padding, Placement, Rect, RootBoundary, Side, SideObject, Strategy, } from '@floating-ui/core';
export { inline, limitShift, offset } from '@floating-ui/core';
