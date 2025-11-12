import { FloatingVueConfig } from './config';
import 'vue-resize/dist/vue-resize.css';
import './style.css';
export declare const options: any;
/**
 * @deprecated Import `vTooltip` instead.
 */
export declare const VTooltip: {
    beforeMount: typeof import("./directives/v-tooltip").bind;
    updated: typeof import("./directives/v-tooltip").bind;
    beforeUnmount(el: any): void;
};
export declare const vTooltip: {
    beforeMount: typeof import("./directives/v-tooltip").bind;
    updated: typeof import("./directives/v-tooltip").bind;
    beforeUnmount(el: any): void;
};
export { createTooltip, destroyTooltip } from './directives/v-tooltip';
/**
 * @deprecated Import `vClosePopper` instead.
 */
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
export declare const vClosePopper: {
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
export declare const Dropdown: import("vue").DefineComponent<{
    theme: {
        type: StringConstructor;
        default: any;
    };
    referenceNode: {
        type: import("vue").PropType<() => Element>;
        default: any;
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
        default: any;
    };
    positioningDisabled: {
        type: BooleanConstructor;
        default: any;
    };
    placement: {
        type: import("vue").PropType<import("./util/popper").Placement>;
        default: any;
    };
    delay: {
        type: import("vue").PropType<string | number | {
            show: number;
            hide: number;
        }>;
        default: any;
    };
    distance: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    skidding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    triggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[]>;
        default: any;
    };
    showTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    hideTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    popperTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[]>;
        default: any;
    };
    popperShowTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    popperHideTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    container: {
        type: any[];
        default: any;
    };
    boundary: {
        type: any[];
        default: any;
    };
    strategy: {
        type: import("vue").PropType<"absolute" | "fixed">;
        default: any;
    };
    autoHide: {
        type: import("vue").PropType<boolean | ((event: Event) => boolean)>;
        default: any;
    };
    handleResize: {
        type: BooleanConstructor;
        default: any;
    };
    instantMove: {
        type: BooleanConstructor;
        default: any;
    };
    eagerMount: {
        type: BooleanConstructor;
        default: any;
    };
    popperClass: {
        type: (ObjectConstructor | StringConstructor | ArrayConstructor)[];
        default: any;
    };
    computeTransformOrigin: {
        type: BooleanConstructor;
        default: any;
    };
    autoMinSize: {
        type: BooleanConstructor;
        default: any;
    };
    autoSize: {
        type: import("vue").PropType<boolean | "min" | "max">;
        default: any;
    };
    autoMaxSize: {
        type: BooleanConstructor;
        default: any;
    };
    autoBoundaryMaxSize: {
        type: BooleanConstructor;
        default: any;
    };
    preventOverflow: {
        type: BooleanConstructor;
        default: any;
    };
    overflowPadding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    arrowPadding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    arrowOverflow: {
        type: BooleanConstructor;
        default: any;
    };
    flip: {
        type: BooleanConstructor;
        default: any;
    };
    shift: {
        type: BooleanConstructor;
        default: any;
    };
    shiftCrossAxis: {
        type: BooleanConstructor;
        default: any;
    };
    noAutoFocus: {
        type: BooleanConstructor;
        default: any;
    };
    disposeTimeout: {
        type: NumberConstructor;
        default: any;
    };
}, unknown, unknown, {
    finalTheme(): string;
}, {
    getTargetNodes(): unknown[];
}, {
    computed: {
        themeClass(): string[];
    };
} | {
    methods: {
        show(...args: any[]): any;
        hide(...args: any[]): any;
        dispose(...args: any[]): any;
        onResize(...args: any[]): any;
    };
}, import("vue").ComponentOptionsMixin, {
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
        default: any;
    };
    referenceNode: {
        type: import("vue").PropType<() => Element>;
        default: any;
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
        default: any;
    };
    positioningDisabled: {
        type: BooleanConstructor;
        default: any;
    };
    placement: {
        type: import("vue").PropType<import("./util/popper").Placement>;
        default: any;
    };
    delay: {
        type: import("vue").PropType<string | number | {
            show: number;
            hide: number;
        }>;
        default: any;
    };
    distance: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    skidding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    triggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[]>;
        default: any;
    };
    showTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    hideTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    popperTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[]>;
        default: any;
    };
    popperShowTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    popperHideTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    container: {
        type: any[];
        default: any;
    };
    boundary: {
        type: any[];
        default: any;
    };
    strategy: {
        type: import("vue").PropType<"absolute" | "fixed">;
        default: any;
    };
    autoHide: {
        type: import("vue").PropType<boolean | ((event: Event) => boolean)>;
        default: any;
    };
    handleResize: {
        type: BooleanConstructor;
        default: any;
    };
    instantMove: {
        type: BooleanConstructor;
        default: any;
    };
    eagerMount: {
        type: BooleanConstructor;
        default: any;
    };
    popperClass: {
        type: (ObjectConstructor | StringConstructor | ArrayConstructor)[];
        default: any;
    };
    computeTransformOrigin: {
        type: BooleanConstructor;
        default: any;
    };
    autoMinSize: {
        type: BooleanConstructor;
        default: any;
    };
    autoSize: {
        type: import("vue").PropType<boolean | "min" | "max">;
        default: any;
    };
    autoMaxSize: {
        type: BooleanConstructor;
        default: any;
    };
    autoBoundaryMaxSize: {
        type: BooleanConstructor;
        default: any;
    };
    preventOverflow: {
        type: BooleanConstructor;
        default: any;
    };
    overflowPadding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    arrowPadding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    arrowOverflow: {
        type: BooleanConstructor;
        default: any;
    };
    flip: {
        type: BooleanConstructor;
        default: any;
    };
    shift: {
        type: BooleanConstructor;
        default: any;
    };
    shiftCrossAxis: {
        type: BooleanConstructor;
        default: any;
    };
    noAutoFocus: {
        type: BooleanConstructor;
        default: any;
    };
    disposeTimeout: {
        type: NumberConstructor;
        default: any;
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
    placement: import("./util/popper").Placement;
    strategy: "absolute" | "fixed";
    disabled: boolean;
    positioningDisabled: boolean;
    delay: string | number | {
        show: number;
        hide: number;
    };
    distance: string | number;
    skidding: string | number;
    triggers: import("./components/PopperWrapper.vue").TriggerEvent[];
    showTriggers: import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[]);
    hideTriggers: import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[]);
    popperTriggers: import("./components/PopperWrapper.vue").TriggerEvent[];
    popperShowTriggers: import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[]);
    popperHideTriggers: import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[]);
    container: any;
    boundary: any;
    autoHide: boolean | ((event: Event) => boolean);
    handleResize: boolean;
    instantMove: boolean;
    eagerMount: boolean;
    popperClass: string | unknown[] | Record<string, any>;
    computeTransformOrigin: boolean;
    autoMinSize: boolean;
    autoSize: boolean | "min" | "max";
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
    theme: string;
    referenceNode: () => Element;
    showGroup: string;
    ariaId: any;
}, {}>;
export declare const Menu: import("vue").DefineComponent<{
    theme: {
        type: StringConstructor;
        default: any;
    };
    referenceNode: {
        type: import("vue").PropType<() => Element>;
        default: any;
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
        default: any;
    };
    positioningDisabled: {
        type: BooleanConstructor;
        default: any;
    };
    placement: {
        type: import("vue").PropType<import("./util/popper").Placement>;
        default: any;
    };
    delay: {
        type: import("vue").PropType<string | number | {
            show: number;
            hide: number;
        }>;
        default: any;
    };
    distance: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    skidding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    triggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[]>;
        default: any;
    };
    showTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    hideTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    popperTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[]>;
        default: any;
    };
    popperShowTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    popperHideTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    container: {
        type: any[];
        default: any;
    };
    boundary: {
        type: any[];
        default: any;
    };
    strategy: {
        type: import("vue").PropType<"absolute" | "fixed">;
        default: any;
    };
    autoHide: {
        type: import("vue").PropType<boolean | ((event: Event) => boolean)>;
        default: any;
    };
    handleResize: {
        type: BooleanConstructor;
        default: any;
    };
    instantMove: {
        type: BooleanConstructor;
        default: any;
    };
    eagerMount: {
        type: BooleanConstructor;
        default: any;
    };
    popperClass: {
        type: (ObjectConstructor | StringConstructor | ArrayConstructor)[];
        default: any;
    };
    computeTransformOrigin: {
        type: BooleanConstructor;
        default: any;
    };
    autoMinSize: {
        type: BooleanConstructor;
        default: any;
    };
    autoSize: {
        type: import("vue").PropType<boolean | "min" | "max">;
        default: any;
    };
    autoMaxSize: {
        type: BooleanConstructor;
        default: any;
    };
    autoBoundaryMaxSize: {
        type: BooleanConstructor;
        default: any;
    };
    preventOverflow: {
        type: BooleanConstructor;
        default: any;
    };
    overflowPadding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    arrowPadding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    arrowOverflow: {
        type: BooleanConstructor;
        default: any;
    };
    flip: {
        type: BooleanConstructor;
        default: any;
    };
    shift: {
        type: BooleanConstructor;
        default: any;
    };
    shiftCrossAxis: {
        type: BooleanConstructor;
        default: any;
    };
    noAutoFocus: {
        type: BooleanConstructor;
        default: any;
    };
    disposeTimeout: {
        type: NumberConstructor;
        default: any;
    };
}, unknown, unknown, {
    finalTheme(): string;
}, {
    getTargetNodes(): unknown[];
}, {
    computed: {
        themeClass(): string[];
    };
} | {
    methods: {
        show(...args: any[]): any;
        hide(...args: any[]): any;
        dispose(...args: any[]): any;
        onResize(...args: any[]): any;
    };
}, import("vue").ComponentOptionsMixin, {
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
        default: any;
    };
    referenceNode: {
        type: import("vue").PropType<() => Element>;
        default: any;
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
        default: any;
    };
    positioningDisabled: {
        type: BooleanConstructor;
        default: any;
    };
    placement: {
        type: import("vue").PropType<import("./util/popper").Placement>;
        default: any;
    };
    delay: {
        type: import("vue").PropType<string | number | {
            show: number;
            hide: number;
        }>;
        default: any;
    };
    distance: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    skidding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    triggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[]>;
        default: any;
    };
    showTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    hideTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    popperTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[]>;
        default: any;
    };
    popperShowTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    popperHideTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    container: {
        type: any[];
        default: any;
    };
    boundary: {
        type: any[];
        default: any;
    };
    strategy: {
        type: import("vue").PropType<"absolute" | "fixed">;
        default: any;
    };
    autoHide: {
        type: import("vue").PropType<boolean | ((event: Event) => boolean)>;
        default: any;
    };
    handleResize: {
        type: BooleanConstructor;
        default: any;
    };
    instantMove: {
        type: BooleanConstructor;
        default: any;
    };
    eagerMount: {
        type: BooleanConstructor;
        default: any;
    };
    popperClass: {
        type: (ObjectConstructor | StringConstructor | ArrayConstructor)[];
        default: any;
    };
    computeTransformOrigin: {
        type: BooleanConstructor;
        default: any;
    };
    autoMinSize: {
        type: BooleanConstructor;
        default: any;
    };
    autoSize: {
        type: import("vue").PropType<boolean | "min" | "max">;
        default: any;
    };
    autoMaxSize: {
        type: BooleanConstructor;
        default: any;
    };
    autoBoundaryMaxSize: {
        type: BooleanConstructor;
        default: any;
    };
    preventOverflow: {
        type: BooleanConstructor;
        default: any;
    };
    overflowPadding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    arrowPadding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    arrowOverflow: {
        type: BooleanConstructor;
        default: any;
    };
    flip: {
        type: BooleanConstructor;
        default: any;
    };
    shift: {
        type: BooleanConstructor;
        default: any;
    };
    shiftCrossAxis: {
        type: BooleanConstructor;
        default: any;
    };
    noAutoFocus: {
        type: BooleanConstructor;
        default: any;
    };
    disposeTimeout: {
        type: NumberConstructor;
        default: any;
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
    placement: import("./util/popper").Placement;
    strategy: "absolute" | "fixed";
    disabled: boolean;
    positioningDisabled: boolean;
    delay: string | number | {
        show: number;
        hide: number;
    };
    distance: string | number;
    skidding: string | number;
    triggers: import("./components/PopperWrapper.vue").TriggerEvent[];
    showTriggers: import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[]);
    hideTriggers: import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[]);
    popperTriggers: import("./components/PopperWrapper.vue").TriggerEvent[];
    popperShowTriggers: import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[]);
    popperHideTriggers: import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[]);
    container: any;
    boundary: any;
    autoHide: boolean | ((event: Event) => boolean);
    handleResize: boolean;
    instantMove: boolean;
    eagerMount: boolean;
    popperClass: string | unknown[] | Record<string, any>;
    computeTransformOrigin: boolean;
    autoMinSize: boolean;
    autoSize: boolean | "min" | "max";
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
    theme: string;
    referenceNode: () => Element;
    showGroup: string;
    ariaId: any;
}, {}>;
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
    $_computeDelay(type: "show" | "hide"): number;
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
export declare const PopperContent: import("vue").DefineComponent<{
    popperId: StringConstructor;
    theme: StringConstructor;
    shown: BooleanConstructor;
    mounted: BooleanConstructor;
    skipTransition: BooleanConstructor;
    autoHide: BooleanConstructor;
    handleResize: BooleanConstructor;
    classes: ObjectConstructor;
    result: ObjectConstructor;
}, unknown, unknown, {}, {
    toPx(value: any): string;
}, {
    computed: {
        themeClass(): string[];
    };
}, import("vue").ComponentOptionsMixin, ("resize" | "hide")[], "resize" | "hide", import("vue").VNodeProps & import("vue").AllowedComponentProps & import("vue").ComponentCustomProps, Readonly<import("vue").ExtractPropTypes<{
    popperId: StringConstructor;
    theme: StringConstructor;
    shown: BooleanConstructor;
    mounted: BooleanConstructor;
    skipTransition: BooleanConstructor;
    autoHide: BooleanConstructor;
    handleResize: BooleanConstructor;
    classes: ObjectConstructor;
    result: ObjectConstructor;
}>> & {
    onResize?: (...args: any[]) => any;
    onHide?: (...args: any[]) => any;
}, {
    autoHide: boolean;
    handleResize: boolean;
    shown: boolean;
    mounted: boolean;
    skipTransition: boolean;
}, {}>;
export declare const PopperMethods: {
    methods: {
        show(...args: any[]): any;
        hide(...args: any[]): any;
        dispose(...args: any[]): any;
        onResize(...args: any[]): any;
    };
};
export declare const PopperWrapper: import("vue").DefineComponent<{
    theme: {
        type: StringConstructor;
        default: any;
    };
    referenceNode: {
        type: import("vue").PropType<() => Element>;
        default: any;
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
        default: any;
    };
    positioningDisabled: {
        type: BooleanConstructor;
        default: any;
    };
    placement: {
        type: import("vue").PropType<import("./util/popper").Placement>;
        default: any;
    };
    delay: {
        type: import("vue").PropType<string | number | {
            show: number;
            hide: number;
        }>;
        default: any;
    };
    distance: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    skidding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    triggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[]>;
        default: any;
    };
    showTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    hideTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    popperTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[]>;
        default: any;
    };
    popperShowTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    popperHideTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    container: {
        type: any[];
        default: any;
    };
    boundary: {
        type: any[];
        default: any;
    };
    strategy: {
        type: import("vue").PropType<"absolute" | "fixed">;
        default: any;
    };
    autoHide: {
        type: import("vue").PropType<boolean | ((event: Event) => boolean)>;
        default: any;
    };
    handleResize: {
        type: BooleanConstructor;
        default: any;
    };
    instantMove: {
        type: BooleanConstructor;
        default: any;
    };
    eagerMount: {
        type: BooleanConstructor;
        default: any;
    };
    popperClass: {
        type: (ObjectConstructor | StringConstructor | ArrayConstructor)[];
        default: any;
    };
    computeTransformOrigin: {
        type: BooleanConstructor;
        default: any;
    };
    autoMinSize: {
        type: BooleanConstructor;
        default: any;
    };
    autoSize: {
        type: import("vue").PropType<boolean | "min" | "max">;
        default: any;
    };
    autoMaxSize: {
        type: BooleanConstructor;
        default: any;
    };
    autoBoundaryMaxSize: {
        type: BooleanConstructor;
        default: any;
    };
    preventOverflow: {
        type: BooleanConstructor;
        default: any;
    };
    overflowPadding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    arrowPadding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    arrowOverflow: {
        type: BooleanConstructor;
        default: any;
    };
    flip: {
        type: BooleanConstructor;
        default: any;
    };
    shift: {
        type: BooleanConstructor;
        default: any;
    };
    shiftCrossAxis: {
        type: BooleanConstructor;
        default: any;
    };
    noAutoFocus: {
        type: BooleanConstructor;
        default: any;
    };
    disposeTimeout: {
        type: NumberConstructor;
        default: any;
    };
}, unknown, unknown, {
    finalTheme(): string;
}, {
    getTargetNodes(): unknown[];
}, {
    computed: {
        themeClass(): string[];
    };
} | {
    methods: {
        show(...args: any[]): any;
        hide(...args: any[]): any;
        dispose(...args: any[]): any;
        onResize(...args: any[]): any;
    };
}, import("vue").ComponentOptionsMixin, {
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
        default: any;
    };
    referenceNode: {
        type: import("vue").PropType<() => Element>;
        default: any;
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
        default: any;
    };
    positioningDisabled: {
        type: BooleanConstructor;
        default: any;
    };
    placement: {
        type: import("vue").PropType<import("./util/popper").Placement>;
        default: any;
    };
    delay: {
        type: import("vue").PropType<string | number | {
            show: number;
            hide: number;
        }>;
        default: any;
    };
    distance: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    skidding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    triggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[]>;
        default: any;
    };
    showTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    hideTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    popperTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[]>;
        default: any;
    };
    popperShowTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    popperHideTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    container: {
        type: any[];
        default: any;
    };
    boundary: {
        type: any[];
        default: any;
    };
    strategy: {
        type: import("vue").PropType<"absolute" | "fixed">;
        default: any;
    };
    autoHide: {
        type: import("vue").PropType<boolean | ((event: Event) => boolean)>;
        default: any;
    };
    handleResize: {
        type: BooleanConstructor;
        default: any;
    };
    instantMove: {
        type: BooleanConstructor;
        default: any;
    };
    eagerMount: {
        type: BooleanConstructor;
        default: any;
    };
    popperClass: {
        type: (ObjectConstructor | StringConstructor | ArrayConstructor)[];
        default: any;
    };
    computeTransformOrigin: {
        type: BooleanConstructor;
        default: any;
    };
    autoMinSize: {
        type: BooleanConstructor;
        default: any;
    };
    autoSize: {
        type: import("vue").PropType<boolean | "min" | "max">;
        default: any;
    };
    autoMaxSize: {
        type: BooleanConstructor;
        default: any;
    };
    autoBoundaryMaxSize: {
        type: BooleanConstructor;
        default: any;
    };
    preventOverflow: {
        type: BooleanConstructor;
        default: any;
    };
    overflowPadding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    arrowPadding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    arrowOverflow: {
        type: BooleanConstructor;
        default: any;
    };
    flip: {
        type: BooleanConstructor;
        default: any;
    };
    shift: {
        type: BooleanConstructor;
        default: any;
    };
    shiftCrossAxis: {
        type: BooleanConstructor;
        default: any;
    };
    noAutoFocus: {
        type: BooleanConstructor;
        default: any;
    };
    disposeTimeout: {
        type: NumberConstructor;
        default: any;
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
    placement: import("./util/popper").Placement;
    strategy: "absolute" | "fixed";
    disabled: boolean;
    positioningDisabled: boolean;
    delay: string | number | {
        show: number;
        hide: number;
    };
    distance: string | number;
    skidding: string | number;
    triggers: import("./components/PopperWrapper.vue").TriggerEvent[];
    showTriggers: import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[]);
    hideTriggers: import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[]);
    popperTriggers: import("./components/PopperWrapper.vue").TriggerEvent[];
    popperShowTriggers: import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[]);
    popperHideTriggers: import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[]);
    container: any;
    boundary: any;
    autoHide: boolean | ((event: Event) => boolean);
    handleResize: boolean;
    instantMove: boolean;
    eagerMount: boolean;
    popperClass: string | unknown[] | Record<string, any>;
    computeTransformOrigin: boolean;
    autoMinSize: boolean;
    autoSize: boolean | "min" | "max";
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
    theme: string;
    referenceNode: () => Element;
    showGroup: string;
    ariaId: any;
}, {}>;
export declare const ThemeClass: (prop?: string) => {
    computed: {
        themeClass(): string[];
    };
};
export declare const Tooltip: import("vue").DefineComponent<{
    theme: {
        type: StringConstructor;
        default: any;
    };
    referenceNode: {
        type: import("vue").PropType<() => Element>;
        default: any;
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
        default: any;
    };
    positioningDisabled: {
        type: BooleanConstructor;
        default: any;
    };
    placement: {
        type: import("vue").PropType<import("./util/popper").Placement>;
        default: any;
    };
    delay: {
        type: import("vue").PropType<string | number | {
            show: number;
            hide: number;
        }>;
        default: any;
    };
    distance: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    skidding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    triggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[]>;
        default: any;
    };
    showTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    hideTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    popperTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[]>;
        default: any;
    };
    popperShowTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    popperHideTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    container: {
        type: any[];
        default: any;
    };
    boundary: {
        type: any[];
        default: any;
    };
    strategy: {
        type: import("vue").PropType<"absolute" | "fixed">;
        default: any;
    };
    autoHide: {
        type: import("vue").PropType<boolean | ((event: Event) => boolean)>;
        default: any;
    };
    handleResize: {
        type: BooleanConstructor;
        default: any;
    };
    instantMove: {
        type: BooleanConstructor;
        default: any;
    };
    eagerMount: {
        type: BooleanConstructor;
        default: any;
    };
    popperClass: {
        type: (ObjectConstructor | StringConstructor | ArrayConstructor)[];
        default: any;
    };
    computeTransformOrigin: {
        type: BooleanConstructor;
        default: any;
    };
    autoMinSize: {
        type: BooleanConstructor;
        default: any;
    };
    autoSize: {
        type: import("vue").PropType<boolean | "min" | "max">;
        default: any;
    };
    autoMaxSize: {
        type: BooleanConstructor;
        default: any;
    };
    autoBoundaryMaxSize: {
        type: BooleanConstructor;
        default: any;
    };
    preventOverflow: {
        type: BooleanConstructor;
        default: any;
    };
    overflowPadding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    arrowPadding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    arrowOverflow: {
        type: BooleanConstructor;
        default: any;
    };
    flip: {
        type: BooleanConstructor;
        default: any;
    };
    shift: {
        type: BooleanConstructor;
        default: any;
    };
    shiftCrossAxis: {
        type: BooleanConstructor;
        default: any;
    };
    noAutoFocus: {
        type: BooleanConstructor;
        default: any;
    };
    disposeTimeout: {
        type: NumberConstructor;
        default: any;
    };
}, unknown, unknown, {
    finalTheme(): string;
}, {
    getTargetNodes(): unknown[];
}, {
    computed: {
        themeClass(): string[];
    };
} | {
    methods: {
        show(...args: any[]): any;
        hide(...args: any[]): any;
        dispose(...args: any[]): any;
        onResize(...args: any[]): any;
    };
}, import("vue").ComponentOptionsMixin, {
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
        default: any;
    };
    referenceNode: {
        type: import("vue").PropType<() => Element>;
        default: any;
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
        default: any;
    };
    positioningDisabled: {
        type: BooleanConstructor;
        default: any;
    };
    placement: {
        type: import("vue").PropType<import("./util/popper").Placement>;
        default: any;
    };
    delay: {
        type: import("vue").PropType<string | number | {
            show: number;
            hide: number;
        }>;
        default: any;
    };
    distance: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    skidding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    triggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[]>;
        default: any;
    };
    showTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    hideTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    popperTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[]>;
        default: any;
    };
    popperShowTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    popperHideTriggers: {
        type: import("vue").PropType<import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[])>;
        default: any;
    };
    container: {
        type: any[];
        default: any;
    };
    boundary: {
        type: any[];
        default: any;
    };
    strategy: {
        type: import("vue").PropType<"absolute" | "fixed">;
        default: any;
    };
    autoHide: {
        type: import("vue").PropType<boolean | ((event: Event) => boolean)>;
        default: any;
    };
    handleResize: {
        type: BooleanConstructor;
        default: any;
    };
    instantMove: {
        type: BooleanConstructor;
        default: any;
    };
    eagerMount: {
        type: BooleanConstructor;
        default: any;
    };
    popperClass: {
        type: (ObjectConstructor | StringConstructor | ArrayConstructor)[];
        default: any;
    };
    computeTransformOrigin: {
        type: BooleanConstructor;
        default: any;
    };
    autoMinSize: {
        type: BooleanConstructor;
        default: any;
    };
    autoSize: {
        type: import("vue").PropType<boolean | "min" | "max">;
        default: any;
    };
    autoMaxSize: {
        type: BooleanConstructor;
        default: any;
    };
    autoBoundaryMaxSize: {
        type: BooleanConstructor;
        default: any;
    };
    preventOverflow: {
        type: BooleanConstructor;
        default: any;
    };
    overflowPadding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    arrowPadding: {
        type: (StringConstructor | NumberConstructor)[];
        default: any;
    };
    arrowOverflow: {
        type: BooleanConstructor;
        default: any;
    };
    flip: {
        type: BooleanConstructor;
        default: any;
    };
    shift: {
        type: BooleanConstructor;
        default: any;
    };
    shiftCrossAxis: {
        type: BooleanConstructor;
        default: any;
    };
    noAutoFocus: {
        type: BooleanConstructor;
        default: any;
    };
    disposeTimeout: {
        type: NumberConstructor;
        default: any;
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
    placement: import("./util/popper").Placement;
    strategy: "absolute" | "fixed";
    disabled: boolean;
    positioningDisabled: boolean;
    delay: string | number | {
        show: number;
        hide: number;
    };
    distance: string | number;
    skidding: string | number;
    triggers: import("./components/PopperWrapper.vue").TriggerEvent[];
    showTriggers: import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[]);
    hideTriggers: import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[]);
    popperTriggers: import("./components/PopperWrapper.vue").TriggerEvent[];
    popperShowTriggers: import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[]);
    popperHideTriggers: import("./components/PopperWrapper.vue").TriggerEvent[] | ((triggers: import("./components/PopperWrapper.vue").TriggerEvent[]) => import("./components/PopperWrapper.vue").TriggerEvent[]);
    container: any;
    boundary: any;
    autoHide: boolean | ((event: Event) => boolean);
    handleResize: boolean;
    instantMove: boolean;
    eagerMount: boolean;
    popperClass: string | unknown[] | Record<string, any>;
    computeTransformOrigin: boolean;
    autoMinSize: boolean;
    autoSize: boolean | "min" | "max";
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
    theme: string;
    referenceNode: () => Element;
    showGroup: string;
    ariaId: any;
}, {}>;
export declare const TooltipDirective: import("vue").DefineComponent<{
    theme: {
        type: StringConstructor;
        default: string;
    };
    html: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
    content: {
        type: (StringConstructor | FunctionConstructor | NumberConstructor)[];
        default: any;
    };
    loadingContent: {
        type: StringConstructor;
        default: (props: any) => any;
    };
    targetNodes: {
        type: FunctionConstructor;
        /**
         * @deprecated Import `vTooltip` instead.
         */
        required: true;
    };
}, unknown, {
    asyncContent: string;
}, {
    isContentAsync(): boolean;
    loading(): boolean;
    finalContent(): string;
}, {
    fetchContent(force: boolean): void;
    onResult(fetchId: any, result: any): void;
    onShow(): void;
    onHide(): void;
}, {
    methods: {
        show(...args: any[]): any;
        hide(...args: any[]): any;
        dispose(...args: any[]): any;
        onResize(...args: any[]): any;
    };
}, import("vue").ComponentOptionsMixin, {}, string, import("vue").VNodeProps & import("vue").AllowedComponentProps & import("vue").ComponentCustomProps, Readonly<import("vue").ExtractPropTypes<{
    theme: {
        type: StringConstructor;
        default: string;
    };
    html: {
        type: BooleanConstructor;
        default: (props: any) => any;
    };
    content: {
        type: (StringConstructor | FunctionConstructor | NumberConstructor)[];
        default: any;
    };
    loadingContent: {
        type: StringConstructor;
        default: (props: any) => any;
    };
    targetNodes: {
        type: FunctionConstructor;
        /**
         * @deprecated Import `vTooltip` instead.
         */
        required: true;
    };
}>>, {
    theme: string;
    html: boolean;
    content: string | number | Function;
    loadingContent: string;
}, {}>;
export { hideAllPoppers, recomputeAllPoppers } from './components/Popper';
export * from './util/events';
export { placements } from './util/popper';
export type { Placement } from './util/popper';
export type { TriggerEvent } from './components/PopperWrapper.vue';
export declare function install(app: any, options?: FloatingVueConfig): void;
declare const plugin: {
    version: string;
    install: typeof install;
    options: any;
};
export default plugin;
