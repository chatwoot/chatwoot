declare const _default: __VLS_WithTemplateSlots<import("vue").DefineComponent<__VLS_TypePropsToOption<{
    color?: "default" | "primary" | "flat";
}>, {}, unknown, {}, {}, import("vue").ComponentOptionsMixin, import("vue").ComponentOptionsMixin, {}, string, import("vue").VNodeProps & import("vue").AllowedComponentProps & import("vue").ComponentCustomProps, Readonly<import("vue").ExtractPropTypes<__VLS_TypePropsToOption<{
    color?: "default" | "primary" | "flat";
}>>>, {}, {}>, {
    default?(_: {}): any;
}>;
export default _default;
export declare const __VLS_globalTypesStart: {};
declare global {
    type __VLS_IntrinsicElements = __VLS_PickNotAny<import('vue/jsx-runtime').JSX.IntrinsicElements, __VLS_PickNotAny<globalThis.JSX.IntrinsicElements, Record<string, any>>>;
    type __VLS_Element = __VLS_PickNotAny<import('vue/jsx-runtime').JSX.Element, globalThis.JSX.Element>;
    type __VLS_GlobalComponents = __VLS_PickNotAny<import('vue').GlobalComponents, {}> & __VLS_PickNotAny<import('@vue/runtime-core').GlobalComponents, {}> & __VLS_PickNotAny<import('@vue/runtime-dom').GlobalComponents, {}> & Pick<typeof import('vue'), 'Transition' | 'TransitionGroup' | 'KeepAlive' | 'Suspense' | 'Teleport'>;
    type __VLS_IsAny<T> = 0 extends 1 & T ? true : false;
    type __VLS_PickNotAny<A, B> = __VLS_IsAny<A> extends true ? B : A;
    const __VLS_intrinsicElements: __VLS_IntrinsicElements;
    function __VLS_getVForSourceType(source: number): [number, number, number][];
    function __VLS_getVForSourceType(source: string): [string, number, number][];
    function __VLS_getVForSourceType<T extends any[]>(source: T): [
        item: T[number],
        key: number,
        index: number
    ][];
    function __VLS_getVForSourceType<T extends {
        [Symbol.iterator](): Iterator<any>;
    }>(source: T): [
        item: T extends {
            [Symbol.iterator](): Iterator<infer T1>;
        } ? T1 : never,
        key: number,
        index: undefined
    ][];
    function __VLS_getVForSourceType<T extends number | {
        [Symbol.iterator](): Iterator<any>;
    }>(source: T): [
        item: number | (Exclude<T, number> extends {
            [Symbol.iterator](): Iterator<infer T1>;
        } ? T1 : never),
        key: number,
        index: undefined
    ][];
    function __VLS_getVForSourceType<T>(source: T): [
        item: T[keyof T],
        key: keyof T,
        index: number
    ][];
    function __VLS_getSlotParams<T>(slot: T): Parameters<__VLS_PickNotAny<NonNullable<T>, (...args: any[]) => any>>;
    function __VLS_getSlotParam<T>(slot: T): Parameters<__VLS_PickNotAny<NonNullable<T>, (...args: any[]) => any>>[0];
    function __VLS_directiveFunction<T>(dir: T): T extends import('vue').ObjectDirective<infer E, infer V> | import('vue').FunctionDirective<infer E, infer V> ? (value: V) => void : T;
    function __VLS_withScope<T, K>(ctx: T, scope: K): ctx is T & K;
    function __VLS_makeOptional<T>(t: T): {
        [K in keyof T]?: T[K];
    };
    type __VLS_SelfComponent<N, C> = string extends N ? {} : N extends string ? {
        [P in N]: C;
    } : {};
    type __VLS_WithComponent<N0 extends string, LocalComponents, N1 extends string, N2 extends string, N3 extends string> = N1 extends keyof LocalComponents ? N1 extends N0 ? Pick<LocalComponents, N0 extends keyof LocalComponents ? N0 : never> : {
        [K in N0]: LocalComponents[N1];
    } : N2 extends keyof LocalComponents ? N2 extends N0 ? Pick<LocalComponents, N0 extends keyof LocalComponents ? N0 : never> : {
        [K in N0]: LocalComponents[N2];
    } : N3 extends keyof LocalComponents ? N3 extends N0 ? Pick<LocalComponents, N0 extends keyof LocalComponents ? N0 : never> : {
        [K in N0]: LocalComponents[N3];
    } : N1 extends keyof __VLS_GlobalComponents ? N1 extends N0 ? Pick<__VLS_GlobalComponents, N0 extends keyof __VLS_GlobalComponents ? N0 : never> : {
        [K in N0]: __VLS_GlobalComponents[N1];
    } : N2 extends keyof __VLS_GlobalComponents ? N2 extends N0 ? Pick<__VLS_GlobalComponents, N0 extends keyof __VLS_GlobalComponents ? N0 : never> : {
        [K in N0]: __VLS_GlobalComponents[N2];
    } : N3 extends keyof __VLS_GlobalComponents ? N3 extends N0 ? Pick<__VLS_GlobalComponents, N0 extends keyof __VLS_GlobalComponents ? N0 : never> : {
        [K in N0]: __VLS_GlobalComponents[N3];
    } : {
        [K in N0]: unknown;
    };
    type __VLS_FillingEventArg_ParametersLength<E extends (...args: any) => any> = __VLS_IsAny<Parameters<E>> extends true ? -1 : Parameters<E>['length'];
    type __VLS_FillingEventArg<E> = E extends (...args: any) => any ? __VLS_FillingEventArg_ParametersLength<E> extends 0 ? ($event?: undefined) => ReturnType<E> : E : E;
    function __VLS_asFunctionalComponent<T, K = T extends new (...args: any) => any ? InstanceType<T> : unknown>(t: T, instance?: K): T extends new (...args: any) => any ? (props: (K extends {
        $props: infer Props;
    } ? Props : any) & Record<string, unknown>, ctx?: any) => __VLS_Element & {
        __ctx?: {
            attrs?: any;
            slots?: K extends {
                $slots: infer Slots;
            } ? Slots : any;
            emit?: K extends {
                $emit: infer Emit;
            } ? Emit : any;
        } & {
            props?: (K extends {
                $props: infer Props;
            } ? Props : any) & Record<string, unknown>;
            expose?(exposed: K): void;
        };
    } : T extends () => any ? (props: {}, ctx?: any) => ReturnType<T> : T extends (...args: any) => any ? T : (_: {} & Record<string, unknown>, ctx?: any) => {
        __ctx?: {
            attrs?: any;
            expose?: any;
            slots?: any;
            emit?: any;
            props?: {} & Record<string, unknown>;
        };
    };
    function __VLS_elementAsFunctionalComponent<T>(t: T): (_: T & Record<string, unknown>, ctx?: any) => {
        __ctx?: {
            attrs?: any;
            expose?: any;
            slots?: any;
            emit?: any;
            props?: T & Record<string, unknown>;
        };
    };
    function __VLS_functionalComponentArgsRest<T extends (...args: any) => any>(t: T): Parameters<T>['length'] extends 2 ? [any] : [];
    function __VLS_pickEvent<E1, E2>(emitEvent: E1, propEvent: E2): __VLS_FillingEventArg<__VLS_PickNotAny<__VLS_AsFunctionOrAny<E2>, __VLS_AsFunctionOrAny<E1>>> | undefined;
    function __VLS_pickFunctionalComponentCtx<T, K>(comp: T, compInstance: K): __VLS_PickNotAny<'__ctx' extends keyof __VLS_PickNotAny<K, {}> ? K extends {
        __ctx?: infer Ctx;
    } ? Ctx : never : any, T extends (props: any, ctx: infer Ctx) => any ? Ctx : any>;
    type __VLS_FunctionalComponentProps<T, K> = '__ctx' extends keyof __VLS_PickNotAny<K, {}> ? K extends {
        __ctx?: {
            props?: infer P;
        };
    } ? NonNullable<P> : never : T extends (props: infer P, ...args: any) => any ? P : {};
    type __VLS_AsFunctionOrAny<F> = unknown extends F ? any : ((...args: any) => any) extends F ? F : any;
    function __VLS_normalizeSlot<S>(s: S): S extends () => infer R ? (props: {}) => R : S;
    /**
     * emit
     */
    type __VLS_UnionToIntersection<U> = (U extends unknown ? (arg: U) => unknown : never) extends ((arg: infer P) => unknown) ? P : never;
    type __VLS_OverloadUnionInner<T, U = unknown> = U & T extends (...args: infer A) => infer R ? U extends T ? never : __VLS_OverloadUnionInner<T, Pick<T, keyof T> & U & ((...args: A) => R)> | ((...args: A) => R) : never;
    type __VLS_OverloadUnion<T> = Exclude<__VLS_OverloadUnionInner<(() => never) & T>, T extends () => never ? never : () => never>;
    type __VLS_ConstructorOverloads<T> = __VLS_OverloadUnion<T> extends infer F ? F extends (event: infer E, ...args: infer A) => any ? {
        [K in E & string]: (...args: A) => void;
    } : never : never;
    type __VLS_NormalizeEmits<T> = __VLS_PrettifyGlobal<__VLS_UnionToIntersection<__VLS_ConstructorOverloads<T> & {
        [K in keyof T]: T[K] extends any[] ? {
            (...args: T[K]): void;
        } : never;
    }>>;
    type __VLS_PrettifyGlobal<T> = {
        [K in keyof T]: T[K];
    } & {};
}
export declare const __VLS_globalTypesEnd: {};
type __VLS_WithTemplateSlots<T, S> = T & {
    new (): {
        $slots: S;
    };
};
type __VLS_NonUndefinedable<T> = T extends undefined ? never : T;
type __VLS_TypePropsToOption<T> = {
    [K in keyof T]-?: {} extends Pick<T, K> ? {
        type: import('vue').PropType<__VLS_NonUndefinedable<T[K]>>;
    } : {
        type: import('vue').PropType<T[K]>;
        required: true;
    };
};
