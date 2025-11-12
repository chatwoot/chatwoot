import * as vue from 'vue';
import { ComponentPublicInstance, ObjectDirective, Ref, UnwrapNestedRefs, ComputedRef, FunctionDirective } from 'vue';
import { MaybeRef, MaybeRefOrGetter, ConfigurableEventFilter, ConfigurableFlush, Awaitable } from '@vueuse/shared';
import { UseClipboardOptions, UseDarkOptions, UseDevicesListOptions, UseDraggableOptions, ElementSize as ElementSize$1, UseGeolocationOptions, UseIdleOptions, UseMouseOptions, MouseInElementOptions, MousePressedOptions, UseNowOptions, UsePointerOptions, UseTimeAgoOptions, UseTimestampOptions, UseVirtualListOptions, UseWindowSizeOptions } from '@vueuse/core';

interface ConfigurableWindow {
    window?: Window;
}

type VueInstance = ComponentPublicInstance;
type MaybeElementRef<T extends MaybeElement = MaybeElement> = MaybeRef<T>;
type MaybeComputedElementRef<T extends MaybeElement = MaybeElement> = MaybeRefOrGetter<T>;
type MaybeElement = HTMLElement | SVGElement | VueInstance | undefined | null;

interface OnClickOutsideOptions extends ConfigurableWindow {
    /**
     * List of elements that should not trigger the event.
     */
    ignore?: MaybeRefOrGetter<(MaybeElementRef | string)[]>;
    /**
     * Use capturing phase for internal event listener.
     * @default true
     */
    capture?: boolean;
    /**
     * Run handler function if focus moves to an iframe.
     * @default false
     */
    detectIframe?: boolean;
}
type OnClickOutsideHandler<T extends {
    detectIframe: OnClickOutsideOptions['detectIframe'];
} = {
    detectIframe: false;
}> = (evt: T['detectIframe'] extends true ? PointerEvent | FocusEvent : PointerEvent) => void;

interface RenderableComponent {
    /**
     * The element that the component should be rendered as
     *
     * @default 'div'
     */
    as?: object | string;
}

interface OnClickOutsideProps extends RenderableComponent {
    options?: OnClickOutsideOptions;
}
declare const OnClickOutside: vue.DefineComponent<OnClickOutsideProps, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<OnClickOutsideProps> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

declare const vOnClickOutside: ObjectDirective<HTMLElement, OnClickOutsideHandler | [(evt: any) => void, OnClickOutsideOptions]>;

type KeyStrokeEventName = 'keydown' | 'keypress' | 'keyup';
interface OnKeyStrokeOptions {
    eventName?: KeyStrokeEventName;
    target?: MaybeRefOrGetter<EventTarget | null | undefined>;
    passive?: boolean;
    /**
     * Set to `true` to ignore repeated events when the key is being held down.
     *
     * @default false
     */
    dedupe?: MaybeRefOrGetter<boolean>;
}

type BindingValueFunction$8 = (event: KeyboardEvent) => void;
type BindingValueArray$7 = [BindingValueFunction$8, OnKeyStrokeOptions];
declare const vOnKeyStroke: ObjectDirective<HTMLElement, BindingValueFunction$8 | BindingValueArray$7>;

interface OnLongPressOptions {
    /**
     * Time in ms till `longpress` gets called
     *
     * @default 500
     */
    delay?: number;
    modifiers?: OnLongPressModifiers;
    /**
     * Allowance of moving distance in pixels,
     * The action will get canceled When moving too far from the pointerdown position.
     * @default 10
     */
    distanceThreshold?: number | false;
    /**
     * Function called when the ref element is released.
     * @param duration how long the element was pressed in ms
     * @param distance distance from the pointerdown position
     * @param isLongPress whether the action was a long press or not
     */
    onMouseUp?: (duration: number, distance: number, isLongPress: boolean) => void;
}
interface OnLongPressModifiers {
    stop?: boolean;
    once?: boolean;
    prevent?: boolean;
    capture?: boolean;
    self?: boolean;
}

interface OnLongPressProps extends RenderableComponent {
    options?: OnLongPressOptions;
}
declare const OnLongPress: vue.DefineComponent<OnLongPressProps, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<OnLongPressProps> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

type BindingValueFunction$7 = (evt: PointerEvent) => void;
type BindingValueArray$6 = [
    BindingValueFunction$7,
    OnLongPressOptions
];
declare const vOnLongPress: ObjectDirective<HTMLElement, BindingValueFunction$7 | BindingValueArray$6>;

declare const UseActiveElement: vue.DefineComponent<{}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}>[] | undefined, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<{}> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, true, {}, any>;

declare const UseBattery: vue.DefineComponent<{}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}>[] | undefined, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<{}> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, true, {}, any>;

declare const UseBrowserLocation: vue.DefineComponent<{}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}>[] | undefined, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<{}> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, true, {}, any>;

interface UseClipboardProps<Source = string> extends UseClipboardOptions<Source> {
}
declare const UseClipboard: vue.DefineComponent<UseClipboardProps<string>, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<UseClipboardProps<string>> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

interface StorageLike {
    getItem: (key: string) => string | null;
    setItem: (key: string, value: string) => void;
    removeItem: (key: string) => void;
}

interface Serializer<T> {
    read: (raw: string) => T;
    write: (value: T) => string;
}
interface UseStorageOptions<T> extends ConfigurableEventFilter, ConfigurableWindow, ConfigurableFlush {
    /**
     * Watch for deep changes
     *
     * @default true
     */
    deep?: boolean;
    /**
     * Listen to storage changes, useful for multiple tabs application
     *
     * @default true
     */
    listenToStorageChanges?: boolean;
    /**
     * Write the default value to the storage when it does not exist
     *
     * @default true
     */
    writeDefaults?: boolean;
    /**
     * Merge the default value with the value read from the storage.
     *
     * When setting it to true, it will perform a **shallow merge** for objects.
     * You can pass a function to perform custom merge (e.g. deep merge), for example:
     *
     * @default false
     */
    mergeDefaults?: boolean | ((storageValue: T, defaults: T) => T);
    /**
     * Custom data serialization
     */
    serializer?: Serializer<T>;
    /**
     * On error callback
     *
     * Default log error to `console.error`
     */
    onError?: (error: unknown) => void;
    /**
     * Use shallow ref as reference
     *
     * @default false
     */
    shallow?: boolean;
    /**
     * Wait for the component to be mounted before reading the storage.
     *
     * @default false
     */
    initOnMounted?: boolean;
}

type BasicColorMode = 'light' | 'dark';
type BasicColorSchema = BasicColorMode | 'auto';
interface UseColorModeOptions<T extends string = BasicColorMode> extends UseStorageOptions<T | BasicColorMode> {
    /**
     * CSS Selector for the target element applying to
     *
     * @default 'html'
     */
    selector?: string | MaybeElementRef;
    /**
     * HTML attribute applying the target element
     *
     * @default 'class'
     */
    attribute?: string;
    /**
     * The initial color mode
     *
     * @default 'auto'
     */
    initialValue?: MaybeRefOrGetter<T | BasicColorSchema>;
    /**
     * Prefix when adding value to the attribute
     */
    modes?: Partial<Record<T | BasicColorSchema, string>>;
    /**
     * A custom handler for handle the updates.
     * When specified, the default behavior will be overridden.
     *
     * @default undefined
     */
    onChanged?: (mode: T | BasicColorMode, defaultHandler: ((mode: T | BasicColorMode) => void)) => void;
    /**
     * Custom storage ref
     *
     * When provided, `useStorage` will be skipped
     */
    storageRef?: Ref<T | BasicColorSchema>;
    /**
     * Key to persist the data into localStorage/sessionStorage.
     *
     * Pass `null` to disable persistence
     *
     * @default 'vueuse-color-scheme'
     */
    storageKey?: string | null;
    /**
     * Storage object, can be localStorage or sessionStorage
     *
     * @default localStorage
     */
    storage?: StorageLike;
    /**
     * Emit `auto` mode from state
     *
     * When set to `true`, preferred mode won't be translated into `light` or `dark`.
     * This is useful when the fact that `auto` mode was selected needs to be known.
     *
     * @default undefined
     * @deprecated use `store.value` when `auto` mode needs to be known
     * @see https://vueuse.org/core/useColorMode/#advanced-usage
     */
    emitAuto?: boolean;
    /**
     * Disable transition on switch
     *
     * @see https://paco.me/writing/disable-theme-transitions
     * @default true
     */
    disableTransition?: boolean;
}

declare const UseColorMode: vue.DefineComponent<UseColorModeOptions<BasicColorMode>, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<UseColorModeOptions<BasicColorMode>> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

declare const UseDark: vue.DefineComponent<UseDarkOptions, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<UseDarkOptions> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

declare const UseDeviceMotion: vue.DefineComponent<{}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}>[] | undefined, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<{}> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, true, {}, any>;

declare const UseDeviceOrientation: vue.DefineComponent<{}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}>[] | undefined, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<{}> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, true, {}, any>;

declare const UseDevicePixelRatio: vue.DefineComponent<{}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}>[] | undefined, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<{}> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, true, {}, any>;

declare const UseDevicesList: vue.DefineComponent<UseDevicesListOptions, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<UseDevicesListOptions> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

declare const UseDocumentVisibility: vue.DefineComponent<{}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}>[] | undefined, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<{}> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, true, {}, any>;

interface UseDraggableProps extends UseDraggableOptions, RenderableComponent {
    /**
     * When provided, use `useStorage` to preserve element's position
     */
    storageKey?: string;
    /**
     * Storage type
     *
     * @default 'local'
     */
    storageType?: 'local' | 'session';
}
declare const UseDraggable: vue.DefineComponent<UseDraggableProps, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<UseDraggableProps> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

interface ResizeObserverSize {
    readonly inlineSize: number;
    readonly blockSize: number;
}
interface ResizeObserverEntry {
    readonly target: Element;
    readonly contentRect: DOMRectReadOnly;
    readonly borderBoxSize: ReadonlyArray<ResizeObserverSize>;
    readonly contentBoxSize: ReadonlyArray<ResizeObserverSize>;
    readonly devicePixelContentBoxSize: ReadonlyArray<ResizeObserverSize>;
}
type ResizeObserverCallback = (entries: ReadonlyArray<ResizeObserverEntry>, observer: ResizeObserver) => void;
interface UseResizeObserverOptions extends ConfigurableWindow {
    /**
     * Sets which box model the observer will observe changes to. Possible values
     * are `content-box` (the default), `border-box` and `device-pixel-content-box`.
     *
     * @default 'content-box'
     */
    box?: ResizeObserverBoxOptions;
}
declare class ResizeObserver {
    constructor(callback: ResizeObserverCallback);
    disconnect(): void;
    observe(target: Element, options?: UseResizeObserverOptions): void;
    unobserve(target: Element): void;
}

declare const UseElementBounding: vue.DefineComponent<UseResizeObserverOptions & RenderableComponent, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<UseResizeObserverOptions & RenderableComponent> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

interface UseElementHoverOptions extends ConfigurableWindow {
    delayEnter?: number;
    delayLeave?: number;
}

type BindingValueFunction$6 = (state: boolean) => void;
declare const vElementHover: ObjectDirective<HTMLElement, BindingValueFunction$6 | [handler: BindingValueFunction$6, options: UseElementHoverOptions]>;

declare const UseElementSize: vue.DefineComponent<ElementSize$1 & UseResizeObserverOptions & RenderableComponent, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<ElementSize$1 & UseResizeObserverOptions & RenderableComponent> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

interface ElementSize {
    width: number;
    height: number;
}
/**
 * Reactive size of an HTML element.
 *
 * @see https://vueuse.org/useElementSize
 */
declare function useElementSize(target: MaybeComputedElementRef, initialSize?: ElementSize, options?: UseResizeObserverOptions): {
    width: vue.Ref<number, number>;
    height: vue.Ref<number, number>;
    stop: () => void;
};

type RemoveFirstFromTuple<T extends any[]> = T['length'] extends 0 ? undefined : (((...b: T) => void) extends (a: any, ...b: infer I) => void ? I : []);
type BindingValueFunction$5 = (size: ElementSize) => void;
type VElementSizeOptions = RemoveFirstFromTuple<Parameters<typeof useElementSize>>;
type BindingValueArray$5 = [BindingValueFunction$5, ...VElementSizeOptions];
declare const vElementSize: ObjectDirective<HTMLElement, BindingValueFunction$5 | BindingValueArray$5>;

declare const UseElementVisibility: vue.DefineComponent<RenderableComponent, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<RenderableComponent> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

interface UseIntersectionObserverOptions extends ConfigurableWindow {
    /**
     * Start the IntersectionObserver immediately on creation
     *
     * @default true
     */
    immediate?: boolean;
    /**
     * The Element or Document whose bounds are used as the bounding box when testing for intersection.
     */
    root?: MaybeComputedElementRef | Document;
    /**
     * A string which specifies a set of offsets to add to the root's bounding_box when calculating intersections.
     */
    rootMargin?: string;
    /**
     * Either a single number or an array of numbers between 0.0 and 1.
     * @default 0
     */
    threshold?: number | number[];
}

interface UseElementVisibilityOptions extends ConfigurableWindow, Pick<UseIntersectionObserverOptions, 'threshold'> {
    scrollTarget?: MaybeRefOrGetter<HTMLElement | undefined | null>;
}

type BindingValueFunction$4 = (state: boolean) => void;
type BindingValueArray$4 = [BindingValueFunction$4, UseElementVisibilityOptions];
declare const vElementVisibility: ObjectDirective<HTMLElement, BindingValueFunction$4 | BindingValueArray$4>;

declare const UseEyeDropper: vue.DefineComponent<vue.ExtractPropTypes<{
    sRGBHex: StringConstructor;
}>, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}>[] | undefined, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<vue.ExtractPropTypes<{
    sRGBHex: StringConstructor;
}>> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, true, {}, any>;

declare const UseFullscreen: vue.DefineComponent<RenderableComponent, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<RenderableComponent> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

declare const UseGeolocation: vue.DefineComponent<UseGeolocationOptions, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<UseGeolocationOptions> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

declare const UseIdle: vue.DefineComponent<UseIdleOptions & {
    timeout: number;
}, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<UseIdleOptions & {
    timeout: number;
}> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

interface UseScrollOptions extends ConfigurableWindow {
    /**
     * Throttle time for scroll event, it’s disabled by default.
     *
     * @default 0
     */
    throttle?: number;
    /**
     * The check time when scrolling ends.
     * This configuration will be setting to (throttle + idle) when the `throttle` is configured.
     *
     * @default 200
     */
    idle?: number;
    /**
     * Offset arrived states by x pixels
     *
     */
    offset?: {
        left?: number;
        right?: number;
        top?: number;
        bottom?: number;
    };
    /**
     * Trigger it when scrolling.
     *
     */
    onScroll?: (e: Event) => void;
    /**
     * Trigger it when scrolling ends.
     *
     */
    onStop?: (e: Event) => void;
    /**
     * Listener options for scroll event.
     *
     * @default {capture: false, passive: true}
     */
    eventListenerOptions?: boolean | AddEventListenerOptions;
    /**
     * Optionally specify a scroll behavior of `auto` (default, not smooth scrolling) or
     * `smooth` (for smooth scrolling) which takes effect when changing the `x` or `y` refs.
     *
     * @default 'auto'
     */
    behavior?: MaybeRefOrGetter<ScrollBehavior>;
    /**
     * On error callback
     *
     * Default log error to `console.error`
     */
    onError?: (error: unknown) => void;
}
/**
 * Reactive scroll.
 *
 * @see https://vueuse.org/useScroll
 * @param element
 * @param options
 */
declare function useScroll(element: MaybeRefOrGetter<HTMLElement | SVGElement | Window | Document | null | undefined>, options?: UseScrollOptions): {
    x: vue.WritableComputedRef<number, number>;
    y: vue.WritableComputedRef<number, number>;
    isScrolling: vue.Ref<boolean, boolean>;
    arrivedState: {
        left: boolean;
        right: boolean;
        top: boolean;
        bottom: boolean;
    };
    directions: {
        left: boolean;
        right: boolean;
        top: boolean;
        bottom: boolean;
    };
    measure(): void;
};
type UseScrollReturn = ReturnType<typeof useScroll>;

type InfiniteScrollElement = HTMLElement | SVGElement | Window | Document | null | undefined;
interface UseInfiniteScrollOptions<T extends InfiniteScrollElement = InfiniteScrollElement> extends UseScrollOptions {
    /**
     * The minimum distance between the bottom of the element and the bottom of the viewport
     *
     * @default 0
     */
    distance?: number;
    /**
     * The direction in which to listen the scroll.
     *
     * @default 'bottom'
     */
    direction?: 'top' | 'bottom' | 'left' | 'right';
    /**
     * The interval time between two load more (to avoid too many invokes).
     *
     * @default 100
     */
    interval?: number;
    /**
     * A function that determines whether more content can be loaded for a specific element.
     * Should return `true` if loading more content is allowed for the given element,
     * and `false` otherwise.
     */
    canLoadMore?: (el: T) => boolean;
}
/**
 * Reactive infinite scroll.
 *
 * @see https://vueuse.org/useInfiniteScroll
 */
declare function useInfiniteScroll<T extends InfiniteScrollElement>(element: MaybeRefOrGetter<T>, onLoadMore: (state: UnwrapNestedRefs<ReturnType<typeof useScroll>>) => Awaitable<void>, options?: UseInfiniteScrollOptions<T>): {
    isLoading: vue.ComputedRef<boolean>;
    reset(): void;
};

interface UseOffsetPaginationOptions {
    /**
     * Total number of items.
     */
    total?: MaybeRefOrGetter<number>;
    /**
     * The number of items to display per page.
     * @default 10
     */
    pageSize?: MaybeRefOrGetter<number>;
    /**
     * The current page number.
     * @default 1
     */
    page?: MaybeRef<number>;
    /**
     * Callback when the `page` change.
     */
    onPageChange?: (returnValue: UnwrapNestedRefs<UseOffsetPaginationReturn>) => unknown;
    /**
     * Callback when the `pageSize` change.
     */
    onPageSizeChange?: (returnValue: UnwrapNestedRefs<UseOffsetPaginationReturn>) => unknown;
    /**
     * Callback when the `pageCount` change.
     */
    onPageCountChange?: (returnValue: UnwrapNestedRefs<UseOffsetPaginationReturn>) => unknown;
}
interface UseOffsetPaginationReturn {
    currentPage: Ref<number>;
    currentPageSize: Ref<number>;
    pageCount: ComputedRef<number>;
    isFirstPage: ComputedRef<boolean>;
    isLastPage: ComputedRef<boolean>;
    prev: () => void;
    next: () => void;
}

interface UseImageOptions {
    /** Address of the resource */
    src: string;
    /** Images to use in different situations, e.g., high-resolution displays, small monitors, etc. */
    srcset?: string;
    /** Image sizes for different page layouts */
    sizes?: string;
    /** Image alternative information */
    alt?: string;
    /** Image classes */
    class?: string;
    /** Image loading */
    loading?: HTMLImageElement['loading'];
    /** Image CORS settings */
    crossorigin?: string;
    /** Referrer policy for fetch https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Referrer-Policy */
    referrerPolicy?: HTMLImageElement['referrerPolicy'];
}

declare const UseImage: vue.DefineComponent<UseImageOptions & RenderableComponent, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<UseImageOptions & RenderableComponent> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

type BindingValueFunction$3 = Parameters<typeof useInfiniteScroll>[1];
type BindingValueArray$3 = [BindingValueFunction$3, UseInfiniteScrollOptions];
declare const vInfiniteScroll: ObjectDirective<HTMLElement, BindingValueFunction$3 | BindingValueArray$3>;

type BindingValueFunction$2 = IntersectionObserverCallback;
type BindingValueArray$2 = [BindingValueFunction$2, UseIntersectionObserverOptions];
declare const vIntersectionObserver: ObjectDirective<HTMLElement, BindingValueFunction$2 | BindingValueArray$2>;

declare const UseMouse: vue.DefineComponent<UseMouseOptions, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<UseMouseOptions> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

declare const UseMouseInElement: vue.DefineComponent<MouseInElementOptions & RenderableComponent, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<MouseInElementOptions & RenderableComponent> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

declare const UseMousePressed: vue.DefineComponent<Omit<MousePressedOptions, "target"> & RenderableComponent, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<Omit<MousePressedOptions, "target"> & RenderableComponent> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

declare const UseNetwork: vue.DefineComponent<{}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}>[] | undefined, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<{}> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, true, {}, any>;

declare const UseNow: vue.DefineComponent<Omit<UseNowOptions<true>, "controls">, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<Omit<UseNowOptions<true>, "controls">> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

interface UseObjectUrlProps {
    object: Blob | MediaSource | undefined;
}
declare const UseObjectUrl: vue.DefineComponent<UseObjectUrlProps, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<UseObjectUrlProps> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

declare const UseOffsetPagination: vue.DefineComponent<UseOffsetPaginationOptions, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<UseOffsetPaginationOptions> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

declare const UseOnline: vue.DefineComponent<{}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}>[] | undefined, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<{}> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, true, {}, any>;

declare const UsePageLeave: vue.DefineComponent<{}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}>[] | undefined, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<{}> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, true, {}, any>;

declare const UsePointer: vue.DefineComponent<Omit<UsePointerOptions, "target"> & {
    target: "window" | "self";
}, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<Omit<UsePointerOptions, "target"> & {
    target: "window" | "self";
}> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

declare const UsePointerLock: vue.DefineComponent<RenderableComponent, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<RenderableComponent> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

declare const UsePreferredColorScheme: vue.DefineComponent<{}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}>[] | undefined, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<{}> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, true, {}, any>;

declare const UsePreferredContrast: vue.DefineComponent<{}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}>[] | undefined, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<{}> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, true, {}, any>;

declare const UsePreferredDark: vue.DefineComponent<{}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}>[] | undefined, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<{}> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, true, {}, any>;

declare const UsePreferredLanguages: vue.DefineComponent<{}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}>[] | undefined, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<{}> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, true, {}, any>;

declare const UsePreferredReducedMotion: vue.DefineComponent<{}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}>[] | undefined, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<{}> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, true, {}, any>;

type BindingValueFunction$1 = ResizeObserverCallback;
type BindingValueArray$1 = [BindingValueFunction$1, UseResizeObserverOptions];
declare const vResizeObserver: ObjectDirective<HTMLElement, BindingValueFunction$1 | BindingValueArray$1>;

declare const UseScreenSafeArea: vue.DefineComponent<vue.ExtractPropTypes<{
    top: BooleanConstructor;
    right: BooleanConstructor;
    bottom: BooleanConstructor;
    left: BooleanConstructor;
}>, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}> | undefined, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<vue.ExtractPropTypes<{
    top: BooleanConstructor;
    right: BooleanConstructor;
    bottom: BooleanConstructor;
    left: BooleanConstructor;
}>> & Readonly<{}>, {
    top: boolean;
    left: boolean;
    right: boolean;
    bottom: boolean;
}, {}, {}, {}, string, vue.ComponentProvideOptions, true, {}, any>;

type BindingValueFunction = (state: UseScrollReturn) => void;
type BindingValueArray = [BindingValueFunction, UseScrollOptions];
declare const vScroll: ObjectDirective<HTMLElement, BindingValueFunction | BindingValueArray>;

declare const vScrollLock: FunctionDirective<HTMLElement, boolean>;

interface UseTimeAgoComponentOptions extends Omit<UseTimeAgoOptions<true>, 'controls'> {
    time: MaybeRef<Date | number | string>;
}
declare const UseTimeAgo: vue.DefineComponent<UseTimeAgoComponentOptions, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<UseTimeAgoComponentOptions> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

declare const UseTimestamp: vue.DefineComponent<Omit<UseTimestampOptions<true>, "controls">, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<Omit<UseTimestampOptions<true>, "controls">> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

interface UseVirtualListProps {
    /**
     * data of scrollable list
     *
     * @default []
     */
    list: Array<any>;
    /**
     * useVirtualList's options
     *
     * @default {}
     */
    options: UseVirtualListOptions;
    /**
     * virtualList's height
     *
     * @default 300px
     */
    height: string;
}
declare const UseVirtualList: vue.DefineComponent<UseVirtualListProps, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<UseVirtualListProps> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

declare const UseWindowFocus: vue.DefineComponent<{}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}>[] | undefined, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<{}> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, true, {}, any>;

declare const UseWindowSize: vue.DefineComponent<UseWindowSizeOptions, {}, {}, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<UseWindowSizeOptions> & Readonly<{}>, {}, {}, {}, {}, string, vue.ComponentProvideOptions, false, {}, any>;

export { OnClickOutside, type OnClickOutsideProps, OnLongPress, type OnLongPressProps, UseActiveElement, UseBattery, UseBrowserLocation, UseClipboard, UseColorMode, UseDark, UseDeviceMotion, UseDeviceOrientation, UseDevicePixelRatio, UseDevicesList, UseDocumentVisibility, UseDraggable, type UseDraggableProps, UseElementBounding, UseElementSize, UseElementVisibility, UseEyeDropper, UseFullscreen, UseGeolocation, UseIdle, UseImage, UseMouse, UseMouseInElement, UseMousePressed, UseNetwork, UseNow, UseObjectUrl, type UseObjectUrlProps, UseOffsetPagination, UseOnline, UsePageLeave, UsePointer, UsePointerLock, UsePreferredColorScheme, UsePreferredContrast, UsePreferredDark, UsePreferredLanguages, UsePreferredReducedMotion, UseScreenSafeArea, UseTimeAgo, UseTimestamp, UseVirtualList, type UseVirtualListProps, UseWindowFocus, UseWindowSize, vOnClickOutside as VOnClickOutside, vOnLongPress as VOnLongPress, vElementHover, vElementSize, vElementVisibility, vInfiniteScroll, vIntersectionObserver, vOnClickOutside, vOnKeyStroke, vOnLongPress, vResizeObserver, vScroll, vScrollLock };
