import { computePosition } from '@floating-ui/dom';
import { Placement } from '../util/popper';
export declare type ComputePositionConfig = Parameters<typeof computePosition>[2];
declare const _default: () => import("vue").DefineComponent<{
    theme: {
        type: StringConstructor;
        required: true;
    };
    targetNodes: {
        type: FunctionConstructor;
        required: true;
    };
    referenceNode: {
        type: FunctionConstructor;
        default: any;
    };
    popperNode: {
        type: FunctionConstructor;
        required: true;
    };
    shown: {
        type: BooleanConstructor;
        default: boolean;
    };
    showGroup: {
        type: StringConstructor;
        default: any;
    };
    ariaId: {
        default: any;
    };
    disabled: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
    positioningDisabled: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
    placement: {
        type: StringConstructor;
        default: (props: any) => any;
        validator: (value: Placement) => boolean;
    };
    delay: {
        type: (ObjectConstructor | StringConstructor | NumberConstructor)[];
        default: (props: any) => any;
    };
    distance: {
        type: (StringConstructor | NumberConstructor)[];
        default: (props: any) => any;
    };
    skidding: {
        type: (StringConstructor | NumberConstructor)[];
        default: (props: any) => any;
    };
    triggers: {
        type: ArrayConstructor;
        default: (props: any) => any;
    };
    showTriggers: {
        type: (FunctionConstructor | ArrayConstructor)[];
        default: (props: any) => any;
    };
    hideTriggers: {
        type: (FunctionConstructor | ArrayConstructor)[];
        default: (props: any) => any;
    };
    popperTriggers: {
        type: ArrayConstructor;
        default: (props: any) => any;
    };
    popperShowTriggers: {
        type: (FunctionConstructor | ArrayConstructor)[];
        default: (props: any) => any;
    };
    popperHideTriggers: {
        type: (FunctionConstructor | ArrayConstructor)[];
        default: (props: any) => any;
    };
    container: {
        type: any[];
        default: (props: any) => any;
    };
    boundary: {
        type: any[];
        default: (props: any) => any;
    };
    strategy: {
        type: StringConstructor;
        validator: (value: string) => boolean;
        default: (props: any) => any;
    };
    autoHide: {
        type: (FunctionConstructor | BooleanConstructor)[];
        default: (props: any) => any;
    };
    handleResize: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
    instantMove: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
    eagerMount: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
    popperClass: {
        type: (ObjectConstructor | StringConstructor | ArrayConstructor)[];
        default: (props: any) => any;
    };
    computeTransformOrigin: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
    /**
     * @deprecated
     */
    autoMinSize: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
    autoSize: {
        type: (StringConstructor | BooleanConstructor)[];
        default: (props: any) => any;
    };
    /**
     * @deprecated
     */
    autoMaxSize: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
    autoBoundaryMaxSize: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
    preventOverflow: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
    overflowPadding: {
        type: (StringConstructor | NumberConstructor)[];
        default: (props: any) => any;
    };
    arrowPadding: {
        type: (StringConstructor | NumberConstructor)[];
        default: (props: any) => any;
    };
    arrowOverflow: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
    flip: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
    shift: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
    shiftCrossAxis: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
}, unknown, {
    isShown: boolean;
    isMounted: boolean;
    skipTransition: boolean;
    classes: {
        showFrom: boolean;
        showTo: boolean;
        hideFrom: boolean;
        hideTo: boolean;
    };
    result: {
        x: number;
        y: number;
        placement: string;
        strategy: string;
        arrow: {
            x: number;
            y: number;
            centerOffset: number;
        };
        transformOrigin: any;
    };
    shownChildren: Set<unknown>;
    lastAutoHide: boolean;
}, {
    popperId(): any;
    shouldMountContent(): any;
    slotData(): {
        popperId: any;
        isShown: any;
        shouldMountContent: any;
        skipTransition: any;
        autoHide: any;
        show: any;
        hide: any;
        handleResize: any;
        onResize: any;
        classes: any;
        result: any;
        attrs: any;
    };
    parentPopper(): any;
    hasPopperShowTriggerHover(): any;
}, {
    show({ event, skipDelay, force }?: {
        event?: any;
        skipDelay?: boolean;
        force?: boolean;
    }): void;
    hide({ event, skipDelay }?: {
        event?: any;
        skipDelay?: boolean;
    }): void;
    init(): void;
    dispose(): void;
    onResize(): Promise<void>;
    $_computePosition(): Promise<void>;
    $_scheduleShow(event?: any, skipDelay?: boolean): void;
    $_scheduleHide(event?: any, skipDelay?: boolean): void;
    $_computeDelay(type: any): number;
    $_applyShow(skipTransition?: boolean): Promise<void>;
    $_applyShowEffect(): Promise<void>;
    $_applyHide(skipTransition?: boolean): Promise<void>;
    $_autoShowHide(): void;
    $_ensureTeleport(): void;
    $_addEventListeners(): void;
    $_registerEventListeners(targetNodes: any[], eventType: string, handler: (event: Event) => void): void;
    $_registerTriggerListeners(targetNodes: any[], eventMap: Record<string, string>, commonTriggers: any, customTrigger: any, handler: (event: Event) => void): void;
    $_removeEventListeners(filterEventType?: string): void;
    $_refreshListeners(): void;
    $_handleGlobalClose(event: any, touch?: boolean): void;
    $_detachPopperNode(): void;
    $_swapTargetAttrs(attrFrom: any, attrTo: any): void;
    $_applyAttrsToTarget(attrs: any): void;
    $_updateParentShownChildren(value: any): void;
    $_isAimingPopper(): boolean;
}, import("vue").ComponentOptionsMixin, import("vue").ComponentOptionsMixin, ("hide" | "show" | "resize" | "update:shown" | "apply-show" | "apply-hide" | "close-group" | "close-directive" | "auto-hide" | "dispose")[], "hide" | "show" | "resize" | "update:shown" | "apply-show" | "apply-hide" | "close-group" | "close-directive" | "auto-hide" | "dispose", import("vue").VNodeProps & import("vue").AllowedComponentProps & import("vue").ComponentCustomProps, Readonly<{
    theme?: unknown;
    targetNodes?: unknown;
    referenceNode?: unknown;
    popperNode?: unknown;
    shown?: unknown;
    showGroup?: unknown;
    ariaId?: unknown;
    disabled?: unknown;
    positioningDisabled?: unknown;
    placement?: unknown;
    delay?: unknown;
    distance?: unknown;
    skidding?: unknown;
    triggers?: unknown;
    showTriggers?: unknown;
    hideTriggers?: unknown;
    popperTriggers?: unknown;
    popperShowTriggers?: unknown;
    popperHideTriggers?: unknown;
    container?: unknown;
    boundary?: unknown;
    strategy?: unknown;
    autoHide?: unknown;
    handleResize?: unknown;
    instantMove?: unknown;
    eagerMount?: unknown;
    popperClass?: unknown;
    computeTransformOrigin?: unknown;
    autoMinSize?: unknown;
    autoSize?: unknown;
    autoMaxSize?: unknown;
    autoBoundaryMaxSize?: unknown;
    preventOverflow?: unknown;
    overflowPadding?: unknown;
    arrowPadding?: unknown;
    arrowOverflow?: unknown;
    flip?: unknown;
    shift?: unknown;
    shiftCrossAxis?: unknown;
} & {
    shift: boolean;
    disabled: boolean;
    boundary: any;
    flip: boolean;
    placement: string;
    strategy: string;
    positioningDisabled: boolean;
    delay: string | number | Record<string, any>;
    distance: string | number;
    skidding: string | number;
    triggers: unknown[];
    showTriggers: Function | unknown[];
    hideTriggers: Function | unknown[];
    popperTriggers: unknown[];
    popperShowTriggers: Function | unknown[];
    popperHideTriggers: Function | unknown[];
    container: any;
    autoHide: boolean | Function;
    handleResize: boolean;
    instantMove: boolean;
    eagerMount: boolean;
    popperClass: string | unknown[] | Record<string, any>;
    computeTransformOrigin: boolean;
    autoMinSize: boolean;
    autoSize: string | boolean;
    autoMaxSize: boolean;
    autoBoundaryMaxSize: boolean;
    preventOverflow: boolean;
    overflowPadding: string | number;
    arrowPadding: string | number;
    arrowOverflow: boolean;
    shiftCrossAxis: boolean;
    shown: boolean;
    theme: string;
    targetNodes: Function;
    popperNode: Function;
} & {
    referenceNode?: Function;
    showGroup?: string;
    ariaId?: any;
}> & {
    onHide?: (...args: any[]) => any;
    onShow?: (...args: any[]) => any;
    onResize?: (...args: any[]) => any;
    "onUpdate:shown"?: (...args: any[]) => any;
    "onApply-show"?: (...args: any[]) => any;
    "onApply-hide"?: (...args: any[]) => any;
    "onClose-group"?: (...args: any[]) => any;
    "onClose-directive"?: (...args: any[]) => any;
    "onAuto-hide"?: (...args: any[]) => any;
    onDispose?: (...args: any[]) => any;
}, {
    shift: boolean;
    disabled: boolean;
    boundary: any;
    flip: boolean;
    placement: string;
    strategy: string;
    positioningDisabled: boolean;
    delay: string | number | Record<string, any>;
    distance: string | number;
    skidding: string | number;
    triggers: unknown[];
    showTriggers: Function | unknown[];
    hideTriggers: Function | unknown[];
    popperTriggers: unknown[];
    popperShowTriggers: Function | unknown[];
    popperHideTriggers: Function | unknown[];
    container: any;
    autoHide: boolean | Function;
    handleResize: boolean;
    instantMove: boolean;
    eagerMount: boolean;
    popperClass: string | unknown[] | Record<string, any>;
    computeTransformOrigin: boolean;
    autoMinSize: boolean;
    autoSize: string | boolean;
    autoMaxSize: boolean;
    autoBoundaryMaxSize: boolean;
    preventOverflow: boolean;
    overflowPadding: string | number;
    arrowPadding: string | number;
    arrowOverflow: boolean;
    shiftCrossAxis: boolean;
    shown: boolean;
    referenceNode: Function;
    showGroup: string;
    ariaId: any;
}>;
export default _default;
export declare function hideAllPoppers(): void;
