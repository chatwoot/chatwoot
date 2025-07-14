export declare type Alignment = 'start' | 'end';
export declare type BasePlacement = 'top' | 'right' | 'bottom' | 'left';
export declare type AlignedPlacement = `${BasePlacement}-${Alignment}`;
export declare type Placement = BasePlacement | AlignedPlacement;
export declare type Strategy = 'absolute' | 'fixed';
export declare type Axis = 'x' | 'y';
export declare type Length = 'width' | 'height';
declare type Promisable<T> = T | Promise<T>;
export declare type Platform = {
    getElementRects: (args: {
        reference: ReferenceElement;
        floating: FloatingElement;
        strategy: Strategy;
    }) => Promisable<ElementRects>;
    convertOffsetParentRelativeRectToViewportRelativeRect: (args: {
        rect: Rect;
        offsetParent: any;
        strategy: Strategy;
    }) => Promisable<Rect>;
    getOffsetParent: (args: {
        element: any;
    }) => Promisable<any>;
    isElement: (value: unknown) => Promisable<boolean>;
    getDocumentElement: (args: {
        element: any;
    }) => Promisable<any>;
    getClippingClientRect: (args: {
        element: any;
        boundary: Boundary;
        rootBoundary: RootBoundary;
    }) => Promisable<ClientRectObject>;
    getDimensions: (args: {
        element: any;
    }) => Promisable<Dimensions>;
    getClientRects?: (args: {
        element: any;
    }) => Promisable<Array<ClientRectObject>>;
};
export declare type Coords = {
    [key in Axis]: number;
};
export declare type SideObject = {
    [key in BasePlacement]: number;
};
export declare type MiddlewareData = {
    arrow?: Partial<Coords> & {
        centerOffset: number;
    };
    autoPlacement?: {
        index?: number;
        skip?: boolean;
        overflows: Array<{
            placement: Placement;
            overflows: Array<number>;
        }>;
    };
    flip?: {
        index?: number;
        skip?: boolean;
        overflows: Array<{
            placement: Placement;
            overflows: Array<number>;
        }>;
    };
    hide?: {
        referenceHidden: boolean;
        escaped: boolean;
        referenceHiddenOffsets: SideObject;
        escapedOffsets: SideObject;
    };
    inline?: {
        skip?: boolean;
    };
    size?: {
        skip?: boolean;
    };
    offset?: Coords;
    [key: string]: any;
};
export declare type ComputePositionConfig = {
    platform: Platform;
    placement?: Placement;
    strategy?: Strategy;
    middleware?: Array<Middleware>;
};
export declare type ComputePositionReturn = Coords & {
    placement: Placement;
    strategy: Strategy;
    middlewareData: MiddlewareData;
};
export declare type ComputePosition = (reference: unknown, floating: unknown, config: ComputePositionConfig) => Promise<ComputePositionReturn>;
export declare type MiddlewareReturn = Partial<Coords & {
    data: {
        [key: string]: any;
    };
    reset: true | {
        placement?: Placement;
        rects?: true | ElementRects;
    };
}>;
export declare type Middleware = {
    name: string;
    options?: any;
    fn: (middlewareArguments: MiddlewareArguments) => Promisable<MiddlewareReturn>;
};
export declare type Dimensions = {
    [key in Length]: number;
};
export declare type Rect = Coords & Dimensions;
export declare type ElementRects = {
    reference: Rect;
    floating: Rect;
};
export declare type VirtualElement = {
    getBoundingClientRect(): ClientRectObject;
    contextElement?: any;
};
export declare type ReferenceElement = any;
export declare type FloatingElement = any;
export declare type Elements = {
    reference: ReferenceElement;
    floating: FloatingElement;
};
export declare type MiddlewareArguments = Coords & {
    initialPlacement: Placement;
    placement: Placement;
    strategy: Strategy;
    middlewareData: MiddlewareData;
    elements: Elements;
    rects: ElementRects;
    platform: Platform;
};
export declare type ClientRectObject = Rect & SideObject;
export declare type Padding = number | SideObject;
export declare type Boundary = any;
export declare type RootBoundary = 'viewport' | 'document';
export declare type ElementContext = 'reference' | 'floating';
export { computePosition } from './computePosition';
export { rectToClientRect } from './utils/rectToClientRect';
export { detectOverflow } from './detectOverflow';
export { arrow } from './middleware/arrow';
export { autoPlacement } from './middleware/autoPlacement';
export { flip } from './middleware/flip';
export { hide } from './middleware/hide';
export { offset } from './middleware/offset';
export { shift, limitShift } from './middleware/shift';
export { size } from './middleware/size';
export { inline } from './middleware/inline';
