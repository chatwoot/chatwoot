/**
 * @private
 */
export declare const camelize: (str: string) => string;

/**
 * @private
 */
export declare const capitalize: (str: string) => string;

export declare const def: (obj: object, key: string | symbol, value: any) => void;

export declare const EMPTY_ARR: readonly never[];

export declare const EMPTY_OBJ: {
    readonly [key: string]: any;
};

export declare function escapeHtml(string: unknown): string;

export declare function escapeHtmlComment(src: string): string;

export declare const extend: {
    <T, U>(target: T, source: U): T & U;
    <T_1, U_1, V>(target: T_1, source1: U_1, source2: V): T_1 & U_1 & V;
    <T_2, U_2, V_1, W>(target: T_2, source1: U_2, source2: V_1, source3: W): T_2 & U_2 & V_1 & W;
    (target: object, ...sources: any[]): any;
};

export declare function generateCodeFrame(source: string, start?: number, end?: number): string;

export declare function genPropsAccessExp(name: string): string;

export declare const getGlobalThis: () => any;

export declare const hasChanged: (value: any, oldValue: any) => boolean;

export declare const hasOwn: (val: object, key: string | symbol) => key is never;

/**
 * @private
 */
export declare const hyphenate: (str: string) => string;

export declare type IfAny<T, Y, N> = 0 extends 1 & T ? Y : N;

/**
 * Boolean attributes should be included if the value is truthy or ''.
 * e.g. `<select multiple>` compiles to `{ multiple: '' }`
 */
export declare function includeBooleanAttr(value: unknown): boolean;

export declare const invokeArrayFns: (fns: Function[], arg?: any) => void;

export declare const isArray: (arg: any) => arg is any[];

/**
 * The full list is needed during SSR to produce the correct initial markup.
 */
export declare const isBooleanAttr: (key: string) => boolean;

export declare const isBuiltInDirective: (key: string) => boolean;

export declare const isDate: (val: unknown) => val is Date;

export declare const isFunction: (val: unknown) => val is Function;

export declare const isGloballyWhitelisted: (key: string) => boolean;

/**
 * Compiler only.
 * Do NOT use in runtime code paths unless behind `__DEV__` flag.
 */
export declare const isHTMLTag: (key: string) => boolean;

export declare const isIntegerKey: (key: unknown) => boolean;

/**
 * Known attributes, this is used for stringification of runtime static nodes
 * so that we don't stringify bindings that cannot be set from HTML.
 * Don't also forget to allow `data-*` and `aria-*`!
 * Generated from https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes
 */
export declare const isKnownHtmlAttr: (key: string) => boolean;

/**
 * Generated from https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute
 */
export declare const isKnownSvgAttr: (key: string) => boolean;

export declare const isMap: (val: unknown) => val is Map<any, any>;

export declare const isModelListener: (key: string) => boolean;

/**
 * CSS properties that accept plain numbers
 */
export declare const isNoUnitNumericStyleProp: (key: string) => boolean;

export declare const isObject: (val: unknown) => val is Record<any, any>;

export declare const isOn: (key: string) => boolean;

export declare const isPlainObject: (val: unknown) => val is object;

export declare const isPromise: <T = any>(val: unknown) => val is Promise<T>;

export declare const isReservedProp: (key: string) => boolean;

export declare const isSet: (val: unknown) => val is Set<any>;

export declare const isSpecialBooleanAttr: (key: string) => boolean;

export declare function isSSRSafeAttrName(name: string): boolean;

export declare const isString: (val: unknown) => val is string;

/**
 * Compiler only.
 * Do NOT use in runtime code paths unless behind `__DEV__` flag.
 */
export declare const isSVGTag: (key: string) => boolean;

export declare const isSymbol: (val: unknown) => val is symbol;

/**
 * Compiler only.
 * Do NOT use in runtime code paths unless behind `__DEV__` flag.
 */
export declare const isVoidTag: (key: string) => boolean;

export declare function looseEqual(a: any, b: any): boolean;

export declare function looseIndexOf(arr: any[], val: any): number;

export declare type LooseRequired<T> = {
    [P in string & keyof T]: T[P];
};

/**
 * Make a map and return a function for checking if a key
 * is in that map.
 * IMPORTANT: all calls of this function must be prefixed with
 * \/\*#\_\_PURE\_\_\*\/
 * So that rollup can tree-shake them if necessary.
 */
export declare function makeMap(str: string, expectsLowerCase?: boolean): (key: string) => boolean;

/**
 * Always return false.
 */
export declare const NO: () => boolean;

export declare const NOOP: () => void;

export declare function normalizeClass(value: unknown): string;

export declare type NormalizedStyle = Record<string, string | number>;

export declare function normalizeProps(props: Record<string, any> | null): Record<string, any> | null;

export declare function normalizeStyle(value: unknown): NormalizedStyle | string | undefined;

export declare const objectToString: () => string;

export declare function parseStringStyle(cssText: string): NormalizedStyle;

/**
 * dev only flag -> name mapping
 */
export declare const PatchFlagNames: {
    [x: number]: string;
};

/**
 * Patch flags are optimization hints generated by the compiler.
 * when a block with dynamicChildren is encountered during diff, the algorithm
 * enters "optimized mode". In this mode, we know that the vdom is produced by
 * a render function generated by the compiler, so the algorithm only needs to
 * handle updates explicitly marked by these patch flags.
 *
 * Patch flags can be combined using the | bitwise operator and can be checked
 * using the & operator, e.g.
 *
 * ```js
 * const flag = TEXT | CLASS
 * if (flag & TEXT) { ... }
 * ```
 *
 * Check the `patchElement` function in '../../runtime-core/src/renderer.ts' to see how the
 * flags are handled during diff.
 */
export declare const enum PatchFlags {
    /**
     * Indicates an element with dynamic textContent (children fast path)
     */
    TEXT = 1,
    /**
     * Indicates an element with dynamic class binding.
     */
    CLASS = 2,
    /**
     * Indicates an element with dynamic style
     * The compiler pre-compiles static string styles into static objects
     * + detects and hoists inline static objects
     * e.g. `style="color: red"` and `:style="{ color: 'red' }"` both get hoisted
     * as:
     * ```js
     * const style = { color: 'red' }
     * render() { return e('div', { style }) }
     * ```
     */
    STYLE = 4,
    /**
     * Indicates an element that has non-class/style dynamic props.
     * Can also be on a component that has any dynamic props (includes
     * class/style). when this flag is present, the vnode also has a dynamicProps
     * array that contains the keys of the props that may change so the runtime
     * can diff them faster (without having to worry about removed props)
     */
    PROPS = 8,
    /**
     * Indicates an element with props with dynamic keys. When keys change, a full
     * diff is always needed to remove the old key. This flag is mutually
     * exclusive with CLASS, STYLE and PROPS.
     */
    FULL_PROPS = 16,
    /**
     * Indicates an element with event listeners (which need to be attached
     * during hydration)
     */
    HYDRATE_EVENTS = 32,
    /**
     * Indicates a fragment whose children order doesn't change.
     */
    STABLE_FRAGMENT = 64,
    /**
     * Indicates a fragment with keyed or partially keyed children
     */
    KEYED_FRAGMENT = 128,
    /**
     * Indicates a fragment with unkeyed children.
     */
    UNKEYED_FRAGMENT = 256,
    /**
     * Indicates an element that only needs non-props patching, e.g. ref or
     * directives (onVnodeXXX hooks). since every patched vnode checks for refs
     * and onVnodeXXX hooks, it simply marks the vnode so that a parent block
     * will track it.
     */
    NEED_PATCH = 512,
    /**
     * Indicates a component with dynamic slots (e.g. slot that references a v-for
     * iterated value, or dynamic slot names).
     * Components with this flag are always force updated.
     */
    DYNAMIC_SLOTS = 1024,
    /**
     * Indicates a fragment that was created only because the user has placed
     * comments at the root level of a template. This is a dev-only flag since
     * comments are stripped in production.
     */
    DEV_ROOT_FRAGMENT = 2048,
    /**
     * SPECIAL FLAGS -------------------------------------------------------------
     * Special flags are negative integers. They are never matched against using
     * bitwise operators (bitwise matching should only happen in branches where
     * patchFlag > 0), and are mutually exclusive. When checking for a special
     * flag, simply check patchFlag === FLAG.
     */
    /**
     * Indicates a hoisted static vnode. This is a hint for hydration to skip
     * the entire sub tree since static content never needs to be updated.
     */
    HOISTED = -1,
    /**
     * A special flag that indicates that the diffing algorithm should bail out
     * of optimized mode. For example, on block fragments created by renderSlot()
     * when encountering non-compiler generated slots (i.e. manually written
     * render functions, which should always be fully diffed)
     * OR manually cloneVNodes
     */
    BAIL = -2
}

export declare const propsToAttrMap: Record<string, string | undefined>;

export declare const remove: <T>(arr: T[], el: T) => void;

export declare const enum ShapeFlags {
    ELEMENT = 1,
    FUNCTIONAL_COMPONENT = 2,
    STATEFUL_COMPONENT = 4,
    TEXT_CHILDREN = 8,
    ARRAY_CHILDREN = 16,
    SLOTS_CHILDREN = 32,
    TELEPORT = 64,
    SUSPENSE = 128,
    COMPONENT_SHOULD_KEEP_ALIVE = 256,
    COMPONENT_KEPT_ALIVE = 512,
    COMPONENT = 6
}

export declare const enum SlotFlags {
    /**
     * Stable slots that only reference slot props or context state. The slot
     * can fully capture its own dependencies so when passed down the parent won't
     * need to force the child to update.
     */
    STABLE = 1,
    /**
     * Slots that reference scope variables (v-for or an outer slot prop), or
     * has conditional structure (v-if, v-for). The parent will need to force
     * the child to update because the slot does not fully capture its dependencies.
     */
    DYNAMIC = 2,
    /**
     * `<slot/>` being forwarded into a child component. Whether the parent needs
     * to update the child is dependent on what kind of slots the parent itself
     * received. This has to be refined at runtime, when the child's vnode
     * is being created (in `normalizeChildren`)
     */
    FORWARDED = 3
}

/**
 * Dev only
 */
export declare const slotFlagsText: {
    1: string;
    2: string;
    3: string;
};

export declare function stringifyStyle(styles: NormalizedStyle | string | undefined): string;

/**
 * For converting {{ interpolation }} values to displayed strings.
 * @private
 */
export declare const toDisplayString: (val: unknown) => string;

/**
 * @private
 */
export declare const toHandlerKey: (str: string) => string;

export declare const toNumber: (val: any) => any;

export declare const toRawType: (value: unknown) => string;

export declare const toTypeString: (value: unknown) => string;

export declare type UnionToIntersection<U> = (U extends any ? (k: U) => void : never) extends (k: infer I) => void ? I : never;

export { }
