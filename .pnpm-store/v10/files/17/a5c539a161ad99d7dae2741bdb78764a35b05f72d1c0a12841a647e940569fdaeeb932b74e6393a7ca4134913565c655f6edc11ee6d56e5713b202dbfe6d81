import { BaseTransitionProps, FunctionalComponent, ObjectDirective, Directive, App, SetupContext, RenderFunction, ComponentOptions, ComponentObjectPropsOptions, EmitsOptions, ComputedOptions, MethodOptions, ComponentOptionsMixin, ComponentInjectOptions, SlotsType, Component, ComponentProvideOptions, ExtractPropTypes, EmitsToProps, ComponentOptionsBase, CreateComponentPublicInstanceWithMixins, ComponentPublicInstance, DefineComponent, ComponentCustomElementInterface, CreateAppFunction, ConcreteComponent, VNodeRef, RootRenderFunction, RootHydrateFunction } from '@vue/runtime-core';
export * from '@vue/runtime-core';
import * as CSS from 'csstype';

declare const TRANSITION = "transition";
declare const ANIMATION = "animation";
type AnimationTypes = typeof TRANSITION | typeof ANIMATION;
export interface TransitionProps extends BaseTransitionProps<Element> {
    name?: string;
    type?: AnimationTypes;
    css?: boolean;
    duration?: number | {
        enter: number;
        leave: number;
    };
    enterFromClass?: string;
    enterActiveClass?: string;
    enterToClass?: string;
    appearFromClass?: string;
    appearActiveClass?: string;
    appearToClass?: string;
    leaveFromClass?: string;
    leaveActiveClass?: string;
    leaveToClass?: string;
}
/**
 * DOM Transition is a higher-order-component based on the platform-agnostic
 * base Transition component, with DOM-specific logic.
 */
export declare const Transition: FunctionalComponent<TransitionProps>;

export type TransitionGroupProps = Omit<TransitionProps, 'mode'> & {
    tag?: string;
    moveClass?: string;
};
export declare const TransitionGroup: {
    new (): {
        $props: TransitionGroupProps;
    };
};

declare const vShowOriginalDisplay: unique symbol;
declare const vShowHidden: unique symbol;
interface VShowElement extends HTMLElement {
    [vShowOriginalDisplay]: string;
    [vShowHidden]: boolean;
}
export declare const vShow: ObjectDirective<VShowElement> & {
    name?: 'show';
};

declare const systemModifiers: readonly ["ctrl", "shift", "alt", "meta"];
type SystemModifiers = (typeof systemModifiers)[number];
type CompatModifiers = keyof typeof keyNames;
type VOnModifiers = SystemModifiers | ModifierGuards | CompatModifiers;
type ModifierGuards = 'shift' | 'ctrl' | 'alt' | 'meta' | 'left' | 'right' | 'stop' | 'prevent' | 'self' | 'middle' | 'exact';
/**
 * @private
 */
export declare const withModifiers: <T extends (event: Event, ...args: unknown[]) => any>(fn: T & {
    _withMods?: {
        [key: string]: T;
    };
}, modifiers: VOnModifiers[]) => T;
declare const keyNames: Record<'esc' | 'space' | 'up' | 'left' | 'right' | 'down' | 'delete', string>;
/**
 * @private
 */
export declare const withKeys: <T extends (event: KeyboardEvent) => any>(fn: T & {
    _withKeys?: {
        [k: string]: T;
    };
}, modifiers: string[]) => T;
type VOnDirective = Directive<any, any, VOnModifiers>;

type AssignerFn = (value: any) => void;
declare const assignKey: unique symbol;
type ModelDirective<T, Modifiers extends string = string> = ObjectDirective<T & {
    [assignKey]: AssignerFn;
    _assigning?: boolean;
}, any, Modifiers>;
export declare const vModelText: ModelDirective<HTMLInputElement | HTMLTextAreaElement, 'trim' | 'number' | 'lazy'>;
export declare const vModelCheckbox: ModelDirective<HTMLInputElement>;
export declare const vModelRadio: ModelDirective<HTMLInputElement>;
export declare const vModelSelect: ModelDirective<HTMLSelectElement, 'number'>;
export declare const vModelDynamic: ObjectDirective<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>;
type VModelDirective = typeof vModelText | typeof vModelCheckbox | typeof vModelSelect | typeof vModelRadio | typeof vModelDynamic;

export type VueElementConstructor<P = {}> = {
    new (initialProps?: Record<string, any>): VueElement & P;
};
export interface CustomElementOptions {
    styles?: string[];
    shadowRoot?: boolean;
    nonce?: string;
    configureApp?: (app: App) => void;
}
export declare function defineCustomElement<Props, RawBindings = object>(setup: (props: Props, ctx: SetupContext) => RawBindings | RenderFunction, options?: Pick<ComponentOptions, 'name' | 'inheritAttrs' | 'emits'> & CustomElementOptions & {
    props?: (keyof Props)[];
}): VueElementConstructor<Props>;
export declare function defineCustomElement<Props, RawBindings = object>(setup: (props: Props, ctx: SetupContext) => RawBindings | RenderFunction, options?: Pick<ComponentOptions, 'name' | 'inheritAttrs' | 'emits'> & CustomElementOptions & {
    props?: ComponentObjectPropsOptions<Props>;
}): VueElementConstructor<Props>;
export declare function defineCustomElement<RuntimePropsOptions extends ComponentObjectPropsOptions = ComponentObjectPropsOptions, PropsKeys extends string = string, RuntimeEmitsOptions extends EmitsOptions = {}, EmitsKeys extends string = string, Data = {}, SetupBindings = {}, Computed extends ComputedOptions = {}, Methods extends MethodOptions = {}, Mixin extends ComponentOptionsMixin = ComponentOptionsMixin, Extends extends ComponentOptionsMixin = ComponentOptionsMixin, InjectOptions extends ComponentInjectOptions = {}, InjectKeys extends string = string, Slots extends SlotsType = {}, LocalComponents extends Record<string, Component> = {}, Directives extends Record<string, Directive> = {}, Exposed extends string = string, Provide extends ComponentProvideOptions = ComponentProvideOptions, InferredProps = string extends PropsKeys ? ComponentObjectPropsOptions extends RuntimePropsOptions ? {} : ExtractPropTypes<RuntimePropsOptions> : {
    [key in PropsKeys]?: any;
}, ResolvedProps = InferredProps & EmitsToProps<RuntimeEmitsOptions>>(options: CustomElementOptions & {
    props?: (RuntimePropsOptions & ThisType<void>) | PropsKeys[];
} & ComponentOptionsBase<ResolvedProps, SetupBindings, Data, Computed, Methods, Mixin, Extends, RuntimeEmitsOptions, EmitsKeys, {}, // Defaults
InjectOptions, InjectKeys, Slots, LocalComponents, Directives, Exposed, Provide> & ThisType<CreateComponentPublicInstanceWithMixins<Readonly<ResolvedProps>, SetupBindings, Data, Computed, Methods, Mixin, Extends, RuntimeEmitsOptions, EmitsKeys, {}, false, InjectOptions, Slots, LocalComponents, Directives, Exposed>>, extraOptions?: CustomElementOptions): VueElementConstructor<ResolvedProps>;
export declare function defineCustomElement<T extends {
    new (...args: any[]): ComponentPublicInstance<any>;
}>(options: T, extraOptions?: CustomElementOptions): VueElementConstructor<T extends DefineComponent<infer P, any, any, any> ? P : unknown>;
/*! #__NO_SIDE_EFFECTS__ */
export declare const defineSSRCustomElement: typeof defineCustomElement;
declare const BaseClass: typeof HTMLElement;
type InnerComponentDef = ConcreteComponent & CustomElementOptions;
export declare class VueElement extends BaseClass implements ComponentCustomElementInterface {
    /**
     * Component def - note this may be an AsyncWrapper, and this._def will
     * be overwritten by the inner component when resolved.
     */
    private _def;
    private _props;
    private _createApp;
    _isVueCE: boolean;
    private _connected;
    private _resolved;
    private _numberProps;
    private _styleChildren;
    private _pendingResolve;
    private _parent;
    /**
     * dev only
     */
    private _styles?;
    /**
     * dev only
     */
    private _childStyles?;
    private _ob?;
    private _slots?;
    constructor(
    /**
     * Component def - note this may be an AsyncWrapper, and this._def will
     * be overwritten by the inner component when resolved.
     */
    _def: InnerComponentDef, _props?: Record<string, any>, _createApp?: CreateAppFunction<Element>);
    connectedCallback(): void;
    private _setParent;
    disconnectedCallback(): void;
    /**
     * resolve inner component definition (handle possible async component)
     */
    private _resolveDef;
    private _mount;
    private _resolveProps;
    protected _setAttr(key: string): void;
    private _update;
    private _createVNode;
    private _applyStyles;
    /**
     * Only called when shadowRoot is false
     */
    private _parseSlots;
    /**
     * Only called when shadowRoot is false
     */
    private _renderSlots;
}
export declare function useHost(caller?: string): VueElement | null;
/**
 * Retrieve the shadowRoot of the current custom element. Only usable in setup()
 * of a `defineCustomElement` component.
 */
export declare function useShadowRoot(): ShadowRoot | null;

export declare function useCssModule(name?: string): Record<string, string>;

/**
 * Runtime helper for SFC's CSS variable injection feature.
 * @private
 */
export declare function useCssVars(getter: (ctx: any) => Record<string, string>): void;

export interface CSSProperties extends CSS.Properties<string | number>, CSS.PropertiesHyphen<string | number> {
    /**
     * The index signature was removed to enable closed typing for style
     * using CSSType. You're able to use type assertion or module augmentation
     * to add properties or an index signature of your own.
     *
     * For examples and more information, visit:
     * https://github.com/frenic/csstype#what-should-i-do-when-i-get-type-errors
     */
    [v: `--${string}`]: string | number | undefined;
}
type Booleanish = boolean | 'true' | 'false';
type Numberish = number | string;
export interface AriaAttributes {
    /** Identifies the currently active element when DOM focus is on a composite widget, textbox, group, or application. */
    'aria-activedescendant'?: string;
    /** Indicates whether assistive technologies will present all, or only parts of, the changed region based on the change notifications defined by the aria-relevant attribute. */
    'aria-atomic'?: Booleanish;
    /**
     * Indicates whether inputting text could trigger display of one or more predictions of the user's intended value for an input and specifies how predictions would be
     * presented if they are made.
     */
    'aria-autocomplete'?: 'none' | 'inline' | 'list' | 'both';
    /** Indicates an element is being modified and that assistive technologies MAY want to wait until the modifications are complete before exposing them to the user. */
    'aria-busy'?: Booleanish;
    /**
     * Indicates the current "checked" state of checkboxes, radio buttons, and other widgets.
     * @see aria-pressed @see aria-selected.
     */
    'aria-checked'?: Booleanish | 'mixed';
    /**
     * Defines the total number of columns in a table, grid, or treegrid.
     * @see aria-colindex.
     */
    'aria-colcount'?: Numberish;
    /**
     * Defines an element's column index or position with respect to the total number of columns within a table, grid, or treegrid.
     * @see aria-colcount @see aria-colspan.
     */
    'aria-colindex'?: Numberish;
    /**
     * Defines the number of columns spanned by a cell or gridcell within a table, grid, or treegrid.
     * @see aria-colindex @see aria-rowspan.
     */
    'aria-colspan'?: Numberish;
    /**
     * Identifies the element (or elements) whose contents or presence are controlled by the current element.
     * @see aria-owns.
     */
    'aria-controls'?: string;
    /** Indicates the element that represents the current item within a container or set of related elements. */
    'aria-current'?: Booleanish | 'page' | 'step' | 'location' | 'date' | 'time';
    /**
     * Identifies the element (or elements) that describes the object.
     * @see aria-labelledby
     */
    'aria-describedby'?: string;
    /**
     * Identifies the element that provides a detailed, extended description for the object.
     * @see aria-describedby.
     */
    'aria-details'?: string;
    /**
     * Indicates that the element is perceivable but disabled, so it is not editable or otherwise operable.
     * @see aria-hidden @see aria-readonly.
     */
    'aria-disabled'?: Booleanish;
    /**
     * Indicates what functions can be performed when a dragged object is released on the drop target.
     * @deprecated in ARIA 1.1
     */
    'aria-dropeffect'?: 'none' | 'copy' | 'execute' | 'link' | 'move' | 'popup';
    /**
     * Identifies the element that provides an error message for the object.
     * @see aria-invalid @see aria-describedby.
     */
    'aria-errormessage'?: string;
    /** Indicates whether the element, or another grouping element it controls, is currently expanded or collapsed. */
    'aria-expanded'?: Booleanish;
    /**
     * Identifies the next element (or elements) in an alternate reading order of content which, at the user's discretion,
     * allows assistive technology to override the general default of reading in document source order.
     */
    'aria-flowto'?: string;
    /**
     * Indicates an element's "grabbed" state in a drag-and-drop operation.
     * @deprecated in ARIA 1.1
     */
    'aria-grabbed'?: Booleanish;
    /** Indicates the availability and type of interactive popup element, such as menu or dialog, that can be triggered by an element. */
    'aria-haspopup'?: Booleanish | 'menu' | 'listbox' | 'tree' | 'grid' | 'dialog';
    /**
     * Indicates whether the element is exposed to an accessibility API.
     * @see aria-disabled.
     */
    'aria-hidden'?: Booleanish;
    /**
     * Indicates the entered value does not conform to the format expected by the application.
     * @see aria-errormessage.
     */
    'aria-invalid'?: Booleanish | 'grammar' | 'spelling';
    /** Indicates keyboard shortcuts that an author has implemented to activate or give focus to an element. */
    'aria-keyshortcuts'?: string;
    /**
     * Defines a string value that labels the current element.
     * @see aria-labelledby.
     */
    'aria-label'?: string;
    /**
     * Identifies the element (or elements) that labels the current element.
     * @see aria-describedby.
     */
    'aria-labelledby'?: string;
    /** Defines the hierarchical level of an element within a structure. */
    'aria-level'?: Numberish;
    /** Indicates that an element will be updated, and describes the types of updates the user agents, assistive technologies, and user can expect from the live region. */
    'aria-live'?: 'off' | 'assertive' | 'polite';
    /** Indicates whether an element is modal when displayed. */
    'aria-modal'?: Booleanish;
    /** Indicates whether a text box accepts multiple lines of input or only a single line. */
    'aria-multiline'?: Booleanish;
    /** Indicates that the user may select more than one item from the current selectable descendants. */
    'aria-multiselectable'?: Booleanish;
    /** Indicates whether the element's orientation is horizontal, vertical, or unknown/ambiguous. */
    'aria-orientation'?: 'horizontal' | 'vertical';
    /**
     * Identifies an element (or elements) in order to define a visual, functional, or contextual parent/child relationship
     * between DOM elements where the DOM hierarchy cannot be used to represent the relationship.
     * @see aria-controls.
     */
    'aria-owns'?: string;
    /**
     * Defines a short hint (a word or short phrase) intended to aid the user with data entry when the control has no value.
     * A hint could be a sample value or a brief description of the expected format.
     */
    'aria-placeholder'?: string;
    /**
     * Defines an element's number or position in the current set of listitems or treeitems. Not required if all elements in the set are present in the DOM.
     * @see aria-setsize.
     */
    'aria-posinset'?: Numberish;
    /**
     * Indicates the current "pressed" state of toggle buttons.
     * @see aria-checked @see aria-selected.
     */
    'aria-pressed'?: Booleanish | 'mixed';
    /**
     * Indicates that the element is not editable, but is otherwise operable.
     * @see aria-disabled.
     */
    'aria-readonly'?: Booleanish;
    /**
     * Indicates what notifications the user agent will trigger when the accessibility tree within a live region is modified.
     * @see aria-atomic.
     */
    'aria-relevant'?: 'additions' | 'additions removals' | 'additions text' | 'all' | 'removals' | 'removals additions' | 'removals text' | 'text' | 'text additions' | 'text removals';
    /** Indicates that user input is required on the element before a form may be submitted. */
    'aria-required'?: Booleanish;
    /** Defines a human-readable, author-localized description for the role of an element. */
    'aria-roledescription'?: string;
    /**
     * Defines the total number of rows in a table, grid, or treegrid.
     * @see aria-rowindex.
     */
    'aria-rowcount'?: Numberish;
    /**
     * Defines an element's row index or position with respect to the total number of rows within a table, grid, or treegrid.
     * @see aria-rowcount @see aria-rowspan.
     */
    'aria-rowindex'?: Numberish;
    /**
     * Defines the number of rows spanned by a cell or gridcell within a table, grid, or treegrid.
     * @see aria-rowindex @see aria-colspan.
     */
    'aria-rowspan'?: Numberish;
    /**
     * Indicates the current "selected" state of various widgets.
     * @see aria-checked @see aria-pressed.
     */
    'aria-selected'?: Booleanish;
    /**
     * Defines the number of items in the current set of listitems or treeitems. Not required if all elements in the set are present in the DOM.
     * @see aria-posinset.
     */
    'aria-setsize'?: Numberish;
    /** Indicates if items in a table or grid are sorted in ascending or descending order. */
    'aria-sort'?: 'none' | 'ascending' | 'descending' | 'other';
    /** Defines the maximum allowed value for a range widget. */
    'aria-valuemax'?: Numberish;
    /** Defines the minimum allowed value for a range widget. */
    'aria-valuemin'?: Numberish;
    /**
     * Defines the current value for a range widget.
     * @see aria-valuetext.
     */
    'aria-valuenow'?: Numberish;
    /** Defines the human readable text alternative of aria-valuenow for a range widget. */
    'aria-valuetext'?: string;
}
export type StyleValue = false | null | undefined | string | CSSProperties | Array<StyleValue>;
export interface HTMLAttributes extends AriaAttributes, EventHandlers<Events> {
    innerHTML?: string;
    class?: any;
    style?: StyleValue;
    accesskey?: string;
    contenteditable?: Booleanish | 'inherit' | 'plaintext-only';
    contextmenu?: string;
    dir?: string;
    draggable?: Booleanish;
    hidden?: Booleanish | '' | 'hidden' | 'until-found';
    id?: string;
    inert?: Booleanish;
    lang?: string;
    placeholder?: string;
    spellcheck?: Booleanish;
    tabindex?: Numberish;
    title?: string;
    translate?: 'yes' | 'no';
    radiogroup?: string;
    role?: string;
    about?: string;
    datatype?: string;
    inlist?: any;
    prefix?: string;
    property?: string;
    resource?: string;
    typeof?: string;
    vocab?: string;
    autocapitalize?: string;
    autocorrect?: string;
    autosave?: string;
    color?: string;
    itemprop?: string;
    itemscope?: Booleanish;
    itemtype?: string;
    itemid?: string;
    itemref?: string;
    results?: Numberish;
    security?: string;
    unselectable?: 'on' | 'off';
    /**
     * Hints at the type of data that might be entered by the user while editing the element or its contents
     * @see https://html.spec.whatwg.org/multipage/interaction.html#input-modalities:-the-inputmode-attribute
     */
    inputmode?: 'none' | 'text' | 'tel' | 'url' | 'email' | 'numeric' | 'decimal' | 'search';
    /**
     * Specify that a standard HTML element should behave like a defined custom built-in element
     * @see https://html.spec.whatwg.org/multipage/custom-elements.html#attr-is
     */
    is?: string;
}
type HTMLAttributeReferrerPolicy = '' | 'no-referrer' | 'no-referrer-when-downgrade' | 'origin' | 'origin-when-cross-origin' | 'same-origin' | 'strict-origin' | 'strict-origin-when-cross-origin' | 'unsafe-url';
export interface AnchorHTMLAttributes extends HTMLAttributes {
    download?: any;
    href?: string;
    hreflang?: string;
    media?: string;
    ping?: string;
    rel?: string;
    target?: string;
    type?: string;
    referrerpolicy?: HTMLAttributeReferrerPolicy;
}
export interface AreaHTMLAttributes extends HTMLAttributes {
    alt?: string;
    coords?: string;
    download?: any;
    href?: string;
    hreflang?: string;
    media?: string;
    referrerpolicy?: HTMLAttributeReferrerPolicy;
    rel?: string;
    shape?: string;
    target?: string;
}
export interface AudioHTMLAttributes extends MediaHTMLAttributes {
}
export interface BaseHTMLAttributes extends HTMLAttributes {
    href?: string;
    target?: string;
}
export interface BlockquoteHTMLAttributes extends HTMLAttributes {
    cite?: string;
}
export interface ButtonHTMLAttributes extends HTMLAttributes {
    autofocus?: Booleanish;
    disabled?: Booleanish;
    form?: string;
    formaction?: string;
    formenctype?: string;
    formmethod?: string;
    formnovalidate?: Booleanish;
    formtarget?: string;
    name?: string;
    type?: 'submit' | 'reset' | 'button';
    value?: string | ReadonlyArray<string> | number;
}
export interface CanvasHTMLAttributes extends HTMLAttributes {
    height?: Numberish;
    width?: Numberish;
}
export interface ColHTMLAttributes extends HTMLAttributes {
    span?: Numberish;
    width?: Numberish;
}
export interface ColgroupHTMLAttributes extends HTMLAttributes {
    span?: Numberish;
}
export interface DataHTMLAttributes extends HTMLAttributes {
    value?: string | ReadonlyArray<string> | number;
}
export interface DetailsHTMLAttributes extends HTMLAttributes {
    name?: string;
    open?: Booleanish;
    onToggle?: (payload: ToggleEvent) => void;
}
export interface DelHTMLAttributes extends HTMLAttributes {
    cite?: string;
    datetime?: string;
}
export interface DialogHTMLAttributes extends HTMLAttributes {
    open?: Booleanish;
    onClose?: (payload: Event) => void;
}
export interface EmbedHTMLAttributes extends HTMLAttributes {
    height?: Numberish;
    src?: string;
    type?: string;
    width?: Numberish;
}
export interface FieldsetHTMLAttributes extends HTMLAttributes {
    disabled?: Booleanish;
    form?: string;
    name?: string;
}
export interface FormHTMLAttributes extends HTMLAttributes {
    acceptcharset?: string;
    action?: string;
    autocomplete?: string;
    enctype?: string;
    method?: string;
    name?: string;
    novalidate?: Booleanish;
    target?: string;
}
export interface HtmlHTMLAttributes extends HTMLAttributes {
    manifest?: string;
}
export interface IframeHTMLAttributes extends HTMLAttributes {
    allow?: string;
    allowfullscreen?: Booleanish;
    allowtransparency?: Booleanish;
    /** @deprecated */
    frameborder?: Numberish;
    height?: Numberish;
    loading?: 'eager' | 'lazy';
    /** @deprecated */
    marginheight?: Numberish;
    /** @deprecated */
    marginwidth?: Numberish;
    name?: string;
    referrerpolicy?: HTMLAttributeReferrerPolicy;
    sandbox?: string;
    /** @deprecated */
    scrolling?: string;
    seamless?: Booleanish;
    src?: string;
    srcdoc?: string;
    width?: Numberish;
}
export interface ImgHTMLAttributes extends HTMLAttributes {
    alt?: string;
    crossorigin?: 'anonymous' | 'use-credentials' | '';
    decoding?: 'async' | 'auto' | 'sync';
    height?: Numberish;
    loading?: 'eager' | 'lazy';
    referrerpolicy?: HTMLAttributeReferrerPolicy;
    sizes?: string;
    src?: string;
    srcset?: string;
    usemap?: string;
    width?: Numberish;
}
export interface InsHTMLAttributes extends HTMLAttributes {
    cite?: string;
    datetime?: string;
}
export type InputTypeHTMLAttribute = 'button' | 'checkbox' | 'color' | 'date' | 'datetime-local' | 'email' | 'file' | 'hidden' | 'image' | 'month' | 'number' | 'password' | 'radio' | 'range' | 'reset' | 'search' | 'submit' | 'tel' | 'text' | 'time' | 'url' | 'week' | (string & {});
export interface InputHTMLAttributes extends HTMLAttributes {
    accept?: string;
    alt?: string;
    autocomplete?: string;
    autofocus?: Booleanish;
    capture?: boolean | 'user' | 'environment';
    checked?: Booleanish | any[] | Set<any>;
    crossorigin?: string;
    disabled?: Booleanish;
    enterKeyHint?: 'enter' | 'done' | 'go' | 'next' | 'previous' | 'search' | 'send';
    form?: string;
    formaction?: string;
    formenctype?: string;
    formmethod?: string;
    formnovalidate?: Booleanish;
    formtarget?: string;
    height?: Numberish;
    indeterminate?: boolean;
    list?: string;
    max?: Numberish;
    maxlength?: Numberish;
    min?: Numberish;
    minlength?: Numberish;
    multiple?: Booleanish;
    name?: string;
    pattern?: string;
    placeholder?: string;
    readonly?: Booleanish;
    required?: Booleanish;
    size?: Numberish;
    src?: string;
    step?: Numberish;
    type?: InputTypeHTMLAttribute;
    value?: any;
    width?: Numberish;
}
export interface KeygenHTMLAttributes extends HTMLAttributes {
    autofocus?: Booleanish;
    challenge?: string;
    disabled?: Booleanish;
    form?: string;
    keytype?: string;
    keyparams?: string;
    name?: string;
}
export interface LabelHTMLAttributes extends HTMLAttributes {
    for?: string;
    form?: string;
}
export interface LiHTMLAttributes extends HTMLAttributes {
    value?: string | ReadonlyArray<string> | number;
}
export interface LinkHTMLAttributes extends HTMLAttributes {
    as?: string;
    crossorigin?: string;
    href?: string;
    hreflang?: string;
    integrity?: string;
    media?: string;
    referrerpolicy?: HTMLAttributeReferrerPolicy;
    rel?: string;
    sizes?: string;
    type?: string;
    charset?: string;
}
export interface MapHTMLAttributes extends HTMLAttributes {
    name?: string;
}
export interface MenuHTMLAttributes extends HTMLAttributes {
    type?: string;
}
export interface MediaHTMLAttributes extends HTMLAttributes {
    autoplay?: Booleanish;
    controls?: Booleanish;
    controlslist?: string;
    crossorigin?: string;
    loop?: Booleanish;
    mediagroup?: string;
    muted?: Booleanish;
    playsinline?: Booleanish;
    preload?: string;
    src?: string;
}
export interface MetaHTMLAttributes extends HTMLAttributes {
    charset?: string;
    content?: string;
    httpequiv?: string;
    name?: string;
}
export interface MeterHTMLAttributes extends HTMLAttributes {
    form?: string;
    high?: Numberish;
    low?: Numberish;
    max?: Numberish;
    min?: Numberish;
    optimum?: Numberish;
    value?: string | ReadonlyArray<string> | number;
}
export interface QuoteHTMLAttributes extends HTMLAttributes {
    cite?: string;
}
export interface ObjectHTMLAttributes extends HTMLAttributes {
    classid?: string;
    data?: string;
    form?: string;
    height?: Numberish;
    name?: string;
    type?: string;
    usemap?: string;
    width?: Numberish;
    wmode?: string;
}
export interface OlHTMLAttributes extends HTMLAttributes {
    reversed?: Booleanish;
    start?: Numberish;
    type?: '1' | 'a' | 'A' | 'i' | 'I';
}
export interface OptgroupHTMLAttributes extends HTMLAttributes {
    disabled?: Booleanish;
    label?: string;
}
export interface OptionHTMLAttributes extends HTMLAttributes {
    disabled?: Booleanish;
    label?: string;
    selected?: Booleanish;
    value?: any;
}
export interface OutputHTMLAttributes extends HTMLAttributes {
    for?: string;
    form?: string;
    name?: string;
}
export interface ParamHTMLAttributes extends HTMLAttributes {
    name?: string;
    value?: string | ReadonlyArray<string> | number;
}
export interface ProgressHTMLAttributes extends HTMLAttributes {
    max?: Numberish;
    value?: string | ReadonlyArray<string> | number;
}
export interface ScriptHTMLAttributes extends HTMLAttributes {
    async?: Booleanish;
    /** @deprecated */
    charset?: string;
    crossorigin?: string;
    defer?: Booleanish;
    integrity?: string;
    nomodule?: Booleanish;
    referrerpolicy?: HTMLAttributeReferrerPolicy;
    nonce?: string;
    src?: string;
    type?: string;
}
export interface SelectHTMLAttributes extends HTMLAttributes {
    autocomplete?: string;
    autofocus?: Booleanish;
    disabled?: Booleanish;
    form?: string;
    multiple?: Booleanish;
    name?: string;
    required?: Booleanish;
    size?: Numberish;
    value?: any;
}
export interface SourceHTMLAttributes extends HTMLAttributes {
    media?: string;
    sizes?: string;
    src?: string;
    srcset?: string;
    type?: string;
}
export interface StyleHTMLAttributes extends HTMLAttributes {
    media?: string;
    nonce?: string;
    scoped?: Booleanish;
    type?: string;
}
export interface TableHTMLAttributes extends HTMLAttributes {
    cellpadding?: Numberish;
    cellspacing?: Numberish;
    summary?: string;
    width?: Numberish;
}
export interface TextareaHTMLAttributes extends HTMLAttributes {
    autocomplete?: string;
    autofocus?: Booleanish;
    cols?: Numberish;
    dirname?: string;
    disabled?: Booleanish;
    form?: string;
    maxlength?: Numberish;
    minlength?: Numberish;
    name?: string;
    placeholder?: string;
    readonly?: Booleanish;
    required?: Booleanish;
    rows?: Numberish;
    value?: string | ReadonlyArray<string> | number | null;
    wrap?: string;
}
export interface TdHTMLAttributes extends HTMLAttributes {
    align?: 'left' | 'center' | 'right' | 'justify' | 'char';
    colspan?: Numberish;
    headers?: string;
    rowspan?: Numberish;
    scope?: string;
    abbr?: string;
    height?: Numberish;
    width?: Numberish;
    valign?: 'top' | 'middle' | 'bottom' | 'baseline';
}
export interface ThHTMLAttributes extends HTMLAttributes {
    align?: 'left' | 'center' | 'right' | 'justify' | 'char';
    colspan?: Numberish;
    headers?: string;
    rowspan?: Numberish;
    scope?: string;
    abbr?: string;
}
export interface TimeHTMLAttributes extends HTMLAttributes {
    datetime?: string;
}
export interface TrackHTMLAttributes extends HTMLAttributes {
    default?: Booleanish;
    kind?: string;
    label?: string;
    src?: string;
    srclang?: string;
}
export interface VideoHTMLAttributes extends MediaHTMLAttributes {
    height?: Numberish;
    playsinline?: Booleanish;
    poster?: string;
    width?: Numberish;
    disablePictureInPicture?: Booleanish;
    disableRemotePlayback?: Booleanish;
}
export interface WebViewHTMLAttributes extends HTMLAttributes {
    allowfullscreen?: Booleanish;
    allowpopups?: Booleanish;
    autoFocus?: Booleanish;
    autosize?: Booleanish;
    blinkfeatures?: string;
    disableblinkfeatures?: string;
    disableguestresize?: Booleanish;
    disablewebsecurity?: Booleanish;
    guestinstance?: string;
    httpreferrer?: string;
    nodeintegration?: Booleanish;
    partition?: string;
    plugins?: Booleanish;
    preload?: string;
    src?: string;
    useragent?: string;
    webpreferences?: string;
}
export interface SVGAttributes extends AriaAttributes, EventHandlers<Events> {
    innerHTML?: string;
    /**
     * SVG Styling Attributes
     * @see https://www.w3.org/TR/SVG/styling.html#ElementSpecificStyling
     */
    class?: any;
    style?: StyleValue;
    color?: string;
    height?: Numberish;
    id?: string;
    lang?: string;
    max?: Numberish;
    media?: string;
    method?: string;
    min?: Numberish;
    name?: string;
    target?: string;
    type?: string;
    width?: Numberish;
    role?: string;
    tabindex?: Numberish;
    crossOrigin?: 'anonymous' | 'use-credentials' | '';
    'accent-height'?: Numberish;
    accumulate?: 'none' | 'sum';
    additive?: 'replace' | 'sum';
    'alignment-baseline'?: 'auto' | 'baseline' | 'before-edge' | 'text-before-edge' | 'middle' | 'central' | 'after-edge' | 'text-after-edge' | 'ideographic' | 'alphabetic' | 'hanging' | 'mathematical' | 'inherit';
    allowReorder?: 'no' | 'yes';
    alphabetic?: Numberish;
    amplitude?: Numberish;
    'arabic-form'?: 'initial' | 'medial' | 'terminal' | 'isolated';
    ascent?: Numberish;
    attributeName?: string;
    attributeType?: string;
    autoReverse?: Numberish;
    azimuth?: Numberish;
    baseFrequency?: Numberish;
    'baseline-shift'?: Numberish;
    baseProfile?: Numberish;
    bbox?: Numberish;
    begin?: Numberish;
    bias?: Numberish;
    by?: Numberish;
    calcMode?: Numberish;
    'cap-height'?: Numberish;
    clip?: Numberish;
    'clip-path'?: string;
    clipPathUnits?: Numberish;
    'clip-rule'?: Numberish;
    'color-interpolation'?: Numberish;
    'color-interpolation-filters'?: 'auto' | 'sRGB' | 'linearRGB' | 'inherit';
    'color-profile'?: Numberish;
    'color-rendering'?: Numberish;
    contentScriptType?: Numberish;
    contentStyleType?: Numberish;
    cursor?: Numberish;
    cx?: Numberish;
    cy?: Numberish;
    d?: string;
    decelerate?: Numberish;
    descent?: Numberish;
    diffuseConstant?: Numberish;
    direction?: Numberish;
    display?: Numberish;
    divisor?: Numberish;
    'dominant-baseline'?: Numberish;
    dur?: Numberish;
    dx?: Numberish;
    dy?: Numberish;
    edgeMode?: Numberish;
    elevation?: Numberish;
    'enable-background'?: Numberish;
    end?: Numberish;
    exponent?: Numberish;
    externalResourcesRequired?: Numberish;
    fill?: string;
    'fill-opacity'?: Numberish;
    'fill-rule'?: 'nonzero' | 'evenodd' | 'inherit';
    filter?: string;
    filterRes?: Numberish;
    filterUnits?: Numberish;
    'flood-color'?: Numberish;
    'flood-opacity'?: Numberish;
    focusable?: Numberish;
    'font-family'?: string;
    'font-size'?: Numberish;
    'font-size-adjust'?: Numberish;
    'font-stretch'?: Numberish;
    'font-style'?: Numberish;
    'font-variant'?: Numberish;
    'font-weight'?: Numberish;
    format?: Numberish;
    from?: Numberish;
    fx?: Numberish;
    fy?: Numberish;
    g1?: Numberish;
    g2?: Numberish;
    'glyph-name'?: Numberish;
    'glyph-orientation-horizontal'?: Numberish;
    'glyph-orientation-vertical'?: Numberish;
    glyphRef?: Numberish;
    gradientTransform?: string;
    gradientUnits?: string;
    hanging?: Numberish;
    'horiz-adv-x'?: Numberish;
    'horiz-origin-x'?: Numberish;
    href?: string;
    ideographic?: Numberish;
    'image-rendering'?: Numberish;
    in2?: Numberish;
    in?: string;
    intercept?: Numberish;
    k1?: Numberish;
    k2?: Numberish;
    k3?: Numberish;
    k4?: Numberish;
    k?: Numberish;
    kernelMatrix?: Numberish;
    kernelUnitLength?: Numberish;
    kerning?: Numberish;
    keyPoints?: Numberish;
    keySplines?: Numberish;
    keyTimes?: Numberish;
    lengthAdjust?: Numberish;
    'letter-spacing'?: Numberish;
    'lighting-color'?: Numberish;
    limitingConeAngle?: Numberish;
    local?: Numberish;
    'marker-end'?: string;
    markerHeight?: Numberish;
    'marker-mid'?: string;
    'marker-start'?: string;
    markerUnits?: Numberish;
    markerWidth?: Numberish;
    mask?: string;
    maskContentUnits?: Numberish;
    maskUnits?: Numberish;
    mathematical?: Numberish;
    mode?: Numberish;
    numOctaves?: Numberish;
    offset?: Numberish;
    opacity?: Numberish;
    operator?: Numberish;
    order?: Numberish;
    orient?: Numberish;
    orientation?: Numberish;
    origin?: Numberish;
    overflow?: Numberish;
    'overline-position'?: Numberish;
    'overline-thickness'?: Numberish;
    'paint-order'?: Numberish;
    'panose-1'?: Numberish;
    pathLength?: Numberish;
    patternContentUnits?: string;
    patternTransform?: Numberish;
    patternUnits?: string;
    'pointer-events'?: Numberish;
    points?: string;
    pointsAtX?: Numberish;
    pointsAtY?: Numberish;
    pointsAtZ?: Numberish;
    preserveAlpha?: Numberish;
    preserveAspectRatio?: string;
    primitiveUnits?: Numberish;
    r?: Numberish;
    radius?: Numberish;
    refX?: Numberish;
    refY?: Numberish;
    renderingIntent?: Numberish;
    repeatCount?: Numberish;
    repeatDur?: Numberish;
    requiredExtensions?: Numberish;
    requiredFeatures?: Numberish;
    restart?: Numberish;
    result?: string;
    rotate?: Numberish;
    rx?: Numberish;
    ry?: Numberish;
    scale?: Numberish;
    seed?: Numberish;
    'shape-rendering'?: Numberish;
    slope?: Numberish;
    spacing?: Numberish;
    specularConstant?: Numberish;
    specularExponent?: Numberish;
    speed?: Numberish;
    spreadMethod?: string;
    startOffset?: Numberish;
    stdDeviation?: Numberish;
    stemh?: Numberish;
    stemv?: Numberish;
    stitchTiles?: Numberish;
    'stop-color'?: string;
    'stop-opacity'?: Numberish;
    'strikethrough-position'?: Numberish;
    'strikethrough-thickness'?: Numberish;
    string?: Numberish;
    stroke?: string;
    'stroke-dasharray'?: Numberish;
    'stroke-dashoffset'?: Numberish;
    'stroke-linecap'?: 'butt' | 'round' | 'square' | 'inherit';
    'stroke-linejoin'?: 'miter' | 'round' | 'bevel' | 'inherit';
    'stroke-miterlimit'?: Numberish;
    'stroke-opacity'?: Numberish;
    'stroke-width'?: Numberish;
    surfaceScale?: Numberish;
    systemLanguage?: Numberish;
    tableValues?: Numberish;
    targetX?: Numberish;
    targetY?: Numberish;
    'text-anchor'?: string;
    'text-decoration'?: Numberish;
    textLength?: Numberish;
    'text-rendering'?: Numberish;
    to?: Numberish;
    transform?: string;
    u1?: Numberish;
    u2?: Numberish;
    'underline-position'?: Numberish;
    'underline-thickness'?: Numberish;
    unicode?: Numberish;
    'unicode-bidi'?: Numberish;
    'unicode-range'?: Numberish;
    'unitsPer-em'?: Numberish;
    'v-alphabetic'?: Numberish;
    values?: string;
    'vector-effect'?: Numberish;
    version?: string;
    'vert-adv-y'?: Numberish;
    'vert-origin-x'?: Numberish;
    'vert-origin-y'?: Numberish;
    'v-hanging'?: Numberish;
    'v-ideographic'?: Numberish;
    viewBox?: string;
    viewTarget?: Numberish;
    visibility?: Numberish;
    'v-mathematical'?: Numberish;
    widths?: Numberish;
    'word-spacing'?: Numberish;
    'writing-mode'?: Numberish;
    x1?: Numberish;
    x2?: Numberish;
    x?: Numberish;
    xChannelSelector?: string;
    'x-height'?: Numberish;
    xlinkActuate?: string;
    xlinkArcrole?: string;
    xlinkHref?: string;
    xlinkRole?: string;
    xlinkShow?: string;
    xlinkTitle?: string;
    xlinkType?: string;
    xmlns?: string;
    xmlnsXlink?: string;
    y1?: Numberish;
    y2?: Numberish;
    y?: Numberish;
    yChannelSelector?: string;
    z?: Numberish;
    zoomAndPan?: string;
}
export interface IntrinsicElementAttributes {
    a: AnchorHTMLAttributes;
    abbr: HTMLAttributes;
    address: HTMLAttributes;
    area: AreaHTMLAttributes;
    article: HTMLAttributes;
    aside: HTMLAttributes;
    audio: AudioHTMLAttributes;
    b: HTMLAttributes;
    base: BaseHTMLAttributes;
    bdi: HTMLAttributes;
    bdo: HTMLAttributes;
    blockquote: BlockquoteHTMLAttributes;
    body: HTMLAttributes;
    br: HTMLAttributes;
    button: ButtonHTMLAttributes;
    canvas: CanvasHTMLAttributes;
    caption: HTMLAttributes;
    cite: HTMLAttributes;
    code: HTMLAttributes;
    col: ColHTMLAttributes;
    colgroup: ColgroupHTMLAttributes;
    data: DataHTMLAttributes;
    datalist: HTMLAttributes;
    dd: HTMLAttributes;
    del: DelHTMLAttributes;
    details: DetailsHTMLAttributes;
    dfn: HTMLAttributes;
    dialog: DialogHTMLAttributes;
    div: HTMLAttributes;
    dl: HTMLAttributes;
    dt: HTMLAttributes;
    em: HTMLAttributes;
    embed: EmbedHTMLAttributes;
    fieldset: FieldsetHTMLAttributes;
    figcaption: HTMLAttributes;
    figure: HTMLAttributes;
    footer: HTMLAttributes;
    form: FormHTMLAttributes;
    h1: HTMLAttributes;
    h2: HTMLAttributes;
    h3: HTMLAttributes;
    h4: HTMLAttributes;
    h5: HTMLAttributes;
    h6: HTMLAttributes;
    head: HTMLAttributes;
    header: HTMLAttributes;
    hgroup: HTMLAttributes;
    hr: HTMLAttributes;
    html: HtmlHTMLAttributes;
    i: HTMLAttributes;
    iframe: IframeHTMLAttributes;
    img: ImgHTMLAttributes;
    input: InputHTMLAttributes;
    ins: InsHTMLAttributes;
    kbd: HTMLAttributes;
    keygen: KeygenHTMLAttributes;
    label: LabelHTMLAttributes;
    legend: HTMLAttributes;
    li: LiHTMLAttributes;
    link: LinkHTMLAttributes;
    main: HTMLAttributes;
    map: MapHTMLAttributes;
    mark: HTMLAttributes;
    menu: MenuHTMLAttributes;
    meta: MetaHTMLAttributes;
    meter: MeterHTMLAttributes;
    nav: HTMLAttributes;
    noindex: HTMLAttributes;
    noscript: HTMLAttributes;
    object: ObjectHTMLAttributes;
    ol: OlHTMLAttributes;
    optgroup: OptgroupHTMLAttributes;
    option: OptionHTMLAttributes;
    output: OutputHTMLAttributes;
    p: HTMLAttributes;
    param: ParamHTMLAttributes;
    picture: HTMLAttributes;
    pre: HTMLAttributes;
    progress: ProgressHTMLAttributes;
    q: QuoteHTMLAttributes;
    rp: HTMLAttributes;
    rt: HTMLAttributes;
    ruby: HTMLAttributes;
    s: HTMLAttributes;
    samp: HTMLAttributes;
    script: ScriptHTMLAttributes;
    section: HTMLAttributes;
    select: SelectHTMLAttributes;
    small: HTMLAttributes;
    source: SourceHTMLAttributes;
    span: HTMLAttributes;
    strong: HTMLAttributes;
    style: StyleHTMLAttributes;
    sub: HTMLAttributes;
    summary: HTMLAttributes;
    sup: HTMLAttributes;
    table: TableHTMLAttributes;
    template: HTMLAttributes;
    tbody: HTMLAttributes;
    td: TdHTMLAttributes;
    textarea: TextareaHTMLAttributes;
    tfoot: HTMLAttributes;
    th: ThHTMLAttributes;
    thead: HTMLAttributes;
    time: TimeHTMLAttributes;
    title: HTMLAttributes;
    tr: HTMLAttributes;
    track: TrackHTMLAttributes;
    u: HTMLAttributes;
    ul: HTMLAttributes;
    var: HTMLAttributes;
    video: VideoHTMLAttributes;
    wbr: HTMLAttributes;
    webview: WebViewHTMLAttributes;
    svg: SVGAttributes;
    animate: SVGAttributes;
    animateMotion: SVGAttributes;
    animateTransform: SVGAttributes;
    circle: SVGAttributes;
    clipPath: SVGAttributes;
    defs: SVGAttributes;
    desc: SVGAttributes;
    ellipse: SVGAttributes;
    feBlend: SVGAttributes;
    feColorMatrix: SVGAttributes;
    feComponentTransfer: SVGAttributes;
    feComposite: SVGAttributes;
    feConvolveMatrix: SVGAttributes;
    feDiffuseLighting: SVGAttributes;
    feDisplacementMap: SVGAttributes;
    feDistantLight: SVGAttributes;
    feDropShadow: SVGAttributes;
    feFlood: SVGAttributes;
    feFuncA: SVGAttributes;
    feFuncB: SVGAttributes;
    feFuncG: SVGAttributes;
    feFuncR: SVGAttributes;
    feGaussianBlur: SVGAttributes;
    feImage: SVGAttributes;
    feMerge: SVGAttributes;
    feMergeNode: SVGAttributes;
    feMorphology: SVGAttributes;
    feOffset: SVGAttributes;
    fePointLight: SVGAttributes;
    feSpecularLighting: SVGAttributes;
    feSpotLight: SVGAttributes;
    feTile: SVGAttributes;
    feTurbulence: SVGAttributes;
    filter: SVGAttributes;
    foreignObject: SVGAttributes;
    g: SVGAttributes;
    image: SVGAttributes;
    line: SVGAttributes;
    linearGradient: SVGAttributes;
    marker: SVGAttributes;
    mask: SVGAttributes;
    metadata: SVGAttributes;
    mpath: SVGAttributes;
    path: SVGAttributes;
    pattern: SVGAttributes;
    polygon: SVGAttributes;
    polyline: SVGAttributes;
    radialGradient: SVGAttributes;
    rect: SVGAttributes;
    stop: SVGAttributes;
    switch: SVGAttributes;
    symbol: SVGAttributes;
    text: SVGAttributes;
    textPath: SVGAttributes;
    tspan: SVGAttributes;
    use: SVGAttributes;
    view: SVGAttributes;
}
export interface Events {
    onCopy: ClipboardEvent;
    onCut: ClipboardEvent;
    onPaste: ClipboardEvent;
    onCompositionend: CompositionEvent;
    onCompositionstart: CompositionEvent;
    onCompositionupdate: CompositionEvent;
    onDrag: DragEvent;
    onDragend: DragEvent;
    onDragenter: DragEvent;
    onDragexit: DragEvent;
    onDragleave: DragEvent;
    onDragover: DragEvent;
    onDragstart: DragEvent;
    onDrop: DragEvent;
    onFocus: FocusEvent;
    onFocusin: FocusEvent;
    onFocusout: FocusEvent;
    onBlur: FocusEvent;
    onChange: Event;
    onBeforeinput: Event;
    onInput: Event;
    onReset: Event;
    onSubmit: Event;
    onInvalid: Event;
    onLoad: Event;
    onError: Event;
    onKeydown: KeyboardEvent;
    onKeypress: KeyboardEvent;
    onKeyup: KeyboardEvent;
    onAuxclick: MouseEvent;
    onClick: MouseEvent;
    onContextmenu: MouseEvent;
    onDblclick: MouseEvent;
    onMousedown: MouseEvent;
    onMouseenter: MouseEvent;
    onMouseleave: MouseEvent;
    onMousemove: MouseEvent;
    onMouseout: MouseEvent;
    onMouseover: MouseEvent;
    onMouseup: MouseEvent;
    onAbort: Event;
    onCanplay: Event;
    onCanplaythrough: Event;
    onDurationchange: Event;
    onEmptied: Event;
    onEncrypted: Event;
    onEnded: Event;
    onLoadeddata: Event;
    onLoadedmetadata: Event;
    onLoadstart: Event;
    onPause: Event;
    onPlay: Event;
    onPlaying: Event;
    onProgress: Event;
    onRatechange: Event;
    onSeeked: Event;
    onSeeking: Event;
    onStalled: Event;
    onSuspend: Event;
    onTimeupdate: Event;
    onVolumechange: Event;
    onWaiting: Event;
    onSelect: Event;
    onScroll: Event;
    onScrollend: Event;
    onTouchcancel: TouchEvent;
    onTouchend: TouchEvent;
    onTouchmove: TouchEvent;
    onTouchstart: TouchEvent;
    onPointerdown: PointerEvent;
    onPointermove: PointerEvent;
    onPointerup: PointerEvent;
    onPointercancel: PointerEvent;
    onPointerenter: PointerEvent;
    onPointerleave: PointerEvent;
    onPointerover: PointerEvent;
    onPointerout: PointerEvent;
    onWheel: WheelEvent;
    onAnimationstart: AnimationEvent;
    onAnimationend: AnimationEvent;
    onAnimationiteration: AnimationEvent;
    onTransitionend: TransitionEvent;
    onTransitionstart: TransitionEvent;
}
type EventHandlers<E> = {
    [K in keyof E]?: E[K] extends (...args: any) => any ? E[K] : (payload: E[K]) => void;
};

export type ReservedProps = {
    key?: PropertyKey;
    ref?: VNodeRef;
    ref_for?: boolean;
    ref_key?: string;
};
export type NativeElements = {
    [K in keyof IntrinsicElementAttributes]: IntrinsicElementAttributes[K] & ReservedProps;
};

/**
 * This is a stub implementation to prevent the need to use dom types.
 *
 * To enable proper types, add `"dom"` to `"lib"` in your `tsconfig.json`.
 */
type DomStub = {};
type DomType<T> = typeof globalThis extends {
    window: unknown;
} ? T : DomStub;
declare module '@vue/reactivity' {
    interface RefUnwrapBailTypes {
        runtimeDOMBailTypes: DomType<Node | Window>;
    }
}
declare module '@vue/runtime-core' {
    interface GlobalComponents {
        Transition: DefineComponent<TransitionProps>;
        TransitionGroup: DefineComponent<TransitionGroupProps>;
    }
    interface GlobalDirectives {
        vShow: typeof vShow;
        vOn: VOnDirective;
        vBind: VModelDirective;
        vIf: Directive<any, boolean>;
        VOnce: Directive;
        VSlot: Directive;
    }
}
export declare const render: RootRenderFunction<Element | ShadowRoot>;
export declare const hydrate: RootHydrateFunction;
export declare const createApp: CreateAppFunction<Element>;
export declare const createSSRApp: CreateAppFunction<Element>;

