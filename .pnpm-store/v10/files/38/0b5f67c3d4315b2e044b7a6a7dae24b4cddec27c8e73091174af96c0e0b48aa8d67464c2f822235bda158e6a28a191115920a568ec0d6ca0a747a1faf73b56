import { computePosition } from '@floating-ui/dom';
import { Placement } from '../util/popper';
export type ComputePositionConfig = Parameters<typeof computePosition>[2];
declare let Element: any;
declare const createPopper: () => import("vue").DefineComponent<{
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
    noAutoFocus: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
    disposeTimeout: {
        type: NumberConstructor;
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
    randomId: string;
    shownChildren: Set<unknown>;
    lastAutoHide: boolean;
    pendingHide: boolean;
    containsGlobalTarget: boolean;
    isDisposed: boolean;
    mouseDownContains: boolean;
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
    $_scheduleShow(_event: any, skipDelay?: boolean): void;
    $_scheduleHide(_event: any, skipDelay?: boolean): void;
    $_computeDelay(type: 'show' | 'hide'): number;
    $_applyShow(skipTransition?: boolean): Promise<void>;
    $_applyShowEffect(): Promise<void>;
    $_applyHide(skipTransition?: boolean): Promise<void>;
    $_autoShowHide(): void;
    $_ensureTeleport(): void;
    $_addEventListeners(): void;
    $_registerEventListeners(targetNodes: Element[], eventType: string, handler: (event: Event) => void): void;
    $_registerTriggerListeners(targetNodes: Element[], eventMap: Record<string, string>, commonTriggers: any, customTrigger: any, handler: (event: Event) => void): void;
    $_removeEventListeners(filterEventType?: string): void;
    $_refreshListeners(): void;
    $_handleGlobalClose(event: any, touch?: boolean): void;
    $_detachPopperNode(): void;
    $_swapTargetAttrs(attrFrom: any, attrTo: any): void;
    $_applyAttrsToTarget(attrs: any): void;
    $_updateParentShownChildren(value: any): void;
    $_isAimingPopper(): boolean;
}, import("vue").ComponentOptionsMixin, import("vue").ComponentOptionsMixin, {
    show: () => true;
    hide: () => true;
    'update:shown': (shown: boolean) => true;
    'apply-show': () => true;
    'apply-hide': () => true;
    'close-group': () => true;
    'close-directive': () => true;
    'auto-hide': () => true;
    resize: () => true;
}, string, import("vue").VNodeProps & import("vue").AllowedComponentProps & import("vue").ComponentCustomProps, Readonly<import("vue").ExtractPropTypes<{
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
    noAutoFocus: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
    disposeTimeout: {
        type: NumberConstructor;
        default: (props: any) => any;
    };
}>> & {
    onResize?: () => any;
    onShow?: () => any;
    onHide?: () => any;
    "onUpdate:shown"?: (shown: boolean) => any;
    "onApply-show"?: () => any;
    "onApply-hide"?: () => any;
    "onClose-group"?: () => any;
    "onClose-directive"?: () => any;
    "onAuto-hide"?: () => any;
}, {
    placement: string;
    strategy: string;
    disabled: boolean;
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
    boundary: any;
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
    flip: boolean;
    shift: boolean;
    shiftCrossAxis: boolean;
    noAutoFocus: boolean;
    disposeTimeout: number;
    shown: boolean;
    referenceNode: Function;
    showGroup: string;
    ariaId: any;
}, {}>;
export declare function recomputeAllPoppers(): void;
export declare function hideAllPoppers(): void;
export default createPopper;
export type PopperInstance = ReturnType<typeof createPopper> extends {
    new (): infer T;
} ? T : never;
