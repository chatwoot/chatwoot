import { FloatingVueConfig } from './config';
import 'vue-resize/dist/vue-resize.css';
export declare const options: any;
export declare const VTooltip: {
    beforeMount: typeof import("./directives/v-tooltip").bind;
    updated: typeof import("./directives/v-tooltip").bind;
    beforeUnmount(el: any): void;
};
export { createTooltip, destroyTooltip } from './directives/v-tooltip';
export declare const VClosePopper: {
    beforeMount(el: any, { value, modifiers }: {
        value: any;
        modifiers: any;
    }): void;
    updated(el: any, { value, oldValue, modifiers }: {
        value: any;
        oldValue: any;
        modifiers: any;
    }): void;
    beforeUnmount(el: any): void;
};
export declare const Dropdown: any;
export declare const Menu: any;
export declare const Popper: () => import("vue").DefineComponent<{
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
        validator: (value: import("./util/popper").Placement) => boolean;
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
    autoMinSize: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
    autoSize: {
        type: (StringConstructor | BooleanConstructor)[];
        default: (props: any) => any;
    };
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
}, import("vue").ComponentOptionsMixin, import("vue").ComponentOptionsMixin, ("resize" | "show" | "hide" | "update:shown" | "apply-show" | "apply-hide" | "close-group" | "close-directive" | "auto-hide" | "dispose")[], "resize" | "show" | "hide" | "update:shown" | "apply-show" | "apply-hide" | "close-group" | "close-directive" | "auto-hide" | "dispose", import("vue").VNodeProps & import("vue").AllowedComponentProps & import("vue").ComponentCustomProps, Readonly<{
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
    shown: boolean;
    theme: string;
    targetNodes: Function;
    popperNode: Function;
} & {
    referenceNode?: Function;
    showGroup?: string;
    ariaId?: any;
}> & {
    onResize?: (...args: any[]) => any;
    onShow?: (...args: any[]) => any;
    onHide?: (...args: any[]) => any;
    "onUpdate:shown"?: (...args: any[]) => any;
    "onApply-show"?: (...args: any[]) => any;
    "onApply-hide"?: (...args: any[]) => any;
    "onClose-group"?: (...args: any[]) => any;
    "onClose-directive"?: (...args: any[]) => any;
    "onAuto-hide"?: (...args: any[]) => any;
    onDispose?: (...args: any[]) => any;
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
    shown: boolean;
    referenceNode: Function;
    showGroup: string;
    ariaId: any;
}>;
export declare const PopperContent: any;
export declare const PopperMethods: {
    methods: {
        show(...args: any[]): any;
        hide(...args: any[]): any;
        dispose(...args: any[]): any;
        onResize(...args: any[]): any;
    };
};
export declare const PopperWrapper: any;
export declare const ThemeClass: (prop?: string) => {
    computed: {
        themeClass(): string[];
    };
};
export declare const Tooltip: any;
export declare const TooltipDirective: any;
export { hideAllPoppers } from './components/Popper';
export * from './util/events';
export { placements } from './util/popper';
export type { Placement } from './util/popper';
export declare function install(app: any, options?: FloatingVueConfig): void;
declare const plugin: {
    version: string;
    install: typeof install;
    options: any;
};
export default plugin;
