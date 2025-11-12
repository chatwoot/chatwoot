/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */
/**
 * Use this module if you want to create your own base class extending
 * {@link ReactiveElement}.
 * @packageDocumentation
 */
import { CSSResultGroup, CSSResultOrNative } from './css-tag.js';
import type { ReactiveController, ReactiveControllerHost } from './reactive-controller.js';
export * from './css-tag.js';
export type { ReactiveController, ReactiveControllerHost, } from './reactive-controller.js';
/**
 * Contains types that are part of the unstable debug API.
 *
 * Everything in this API is not stable and may change or be removed in the future,
 * even on patch releases.
 */
export declare namespace ReactiveUnstable {
    /**
     * When Lit is running in dev mode and `window.emitLitDebugLogEvents` is true,
     * we will emit 'lit-debug' events to window, with live details about the update and render
     * lifecycle. These can be useful for writing debug tooling and visualizations.
     *
     * Please be aware that running with window.emitLitDebugLogEvents has performance overhead,
     * making certain operations that are normally very cheap (like a no-op render) much slower,
     * because we must copy data and dispatch events.
     */
    namespace DebugLog {
        type Entry = Update;
        interface Update {
            kind: 'update';
        }
    }
}
/**
 * Converts property values to and from attribute values.
 */
export interface ComplexAttributeConverter<Type = unknown, TypeHint = unknown> {
    /**
     * Called to convert an attribute value to a property
     * value.
     */
    fromAttribute?(value: string | null, type?: TypeHint): Type;
    /**
     * Called to convert a property value to an attribute
     * value.
     *
     * It returns unknown instead of string, to be compatible with
     * https://github.com/WICG/trusted-types (and similar efforts).
     */
    toAttribute?(value: Type, type?: TypeHint): unknown;
}
declare type AttributeConverter<Type = unknown, TypeHint = unknown> = ComplexAttributeConverter<Type> | ((value: string | null, type?: TypeHint) => Type);
/**
 * Defines options for a property accessor.
 */
export interface PropertyDeclaration<Type = unknown, TypeHint = unknown> {
    /**
     * When set to `true`, indicates the property is internal private state. The
     * property should not be set by users. When using TypeScript, this property
     * should be marked as `private` or `protected`, and it is also a common
     * practice to use a leading `_` in the name. The property is not added to
     * `observedAttributes`.
     */
    readonly state?: boolean;
    /**
     * Indicates how and whether the property becomes an observed attribute.
     * If the value is `false`, the property is not added to `observedAttributes`.
     * If true or absent, the lowercased property name is observed (e.g. `fooBar`
     * becomes `foobar`). If a string, the string value is observed (e.g
     * `attribute: 'foo-bar'`).
     */
    readonly attribute?: boolean | string;
    /**
     * Indicates the type of the property. This is used only as a hint for the
     * `converter` to determine how to convert the attribute
     * to/from a property.
     */
    readonly type?: TypeHint;
    /**
     * Indicates how to convert the attribute to/from a property. If this value
     * is a function, it is used to convert the attribute value a the property
     * value. If it's an object, it can have keys for `fromAttribute` and
     * `toAttribute`. If no `toAttribute` function is provided and
     * `reflect` is set to `true`, the property value is set directly to the
     * attribute. A default `converter` is used if none is provided; it supports
     * `Boolean`, `String`, `Number`, `Object`, and `Array`. Note,
     * when a property changes and the converter is used to update the attribute,
     * the property is never updated again as a result of the attribute changing,
     * and vice versa.
     */
    readonly converter?: AttributeConverter<Type, TypeHint>;
    /**
     * Indicates if the property should reflect to an attribute.
     * If `true`, when the property is set, the attribute is set using the
     * attribute name determined according to the rules for the `attribute`
     * property option and the value of the property converted using the rules
     * from the `converter` property option.
     */
    readonly reflect?: boolean;
    /**
     * A function that indicates if a property should be considered changed when
     * it is set. The function should take the `newValue` and `oldValue` and
     * return `true` if an update should be requested.
     */
    hasChanged?(value: Type, oldValue: Type): boolean;
    /**
     * Indicates whether an accessor will be created for this property. By
     * default, an accessor will be generated for this property that requests an
     * update when set. If this flag is `true`, no accessor will be created, and
     * it will be the user's responsibility to call
     * `this.requestUpdate(propertyName, oldValue)` to request an update when
     * the property changes.
     */
    readonly noAccessor?: boolean;
}
/**
 * Map of properties to PropertyDeclaration options. For each property an
 * accessor is made, and the property is processed according to the
 * PropertyDeclaration options.
 */
export interface PropertyDeclarations {
    readonly [key: string]: PropertyDeclaration;
}
declare type PropertyDeclarationMap = Map<PropertyKey, PropertyDeclaration>;
/**
 * A Map of property keys to values.
 *
 * Takes an optional type parameter T, which when specified as a non-any,
 * non-unknown type, will make the Map more strongly-typed, associating the map
 * keys with their corresponding value type on T.
 *
 * Use `PropertyValues<this>` when overriding ReactiveElement.update() and
 * other lifecycle methods in order to get stronger type-checking on keys
 * and values.
 */
export declare type PropertyValues<T = any> = T extends object ? PropertyValueMap<T> : Map<PropertyKey, unknown>;
/**
 * Do not use, instead prefer {@linkcode PropertyValues}.
 */
export interface PropertyValueMap<T> extends Map<PropertyKey, unknown> {
    get<K extends keyof T>(k: K): T[K];
    set<K extends keyof T>(key: K, value: T[K]): this;
    has<K extends keyof T>(k: K): boolean;
    delete<K extends keyof T>(k: K): boolean;
}
export declare const defaultConverter: ComplexAttributeConverter;
export interface HasChanged {
    (value: unknown, old: unknown): boolean;
}
/**
 * Change function that returns true if `value` is different from `oldValue`.
 * This method is used as the default for a property's `hasChanged` function.
 */
export declare const notEqual: HasChanged;
/**
 * The Closure JS Compiler doesn't currently have good support for static
 * property semantics where "this" is dynamic (e.g.
 * https://github.com/google/closure-compiler/issues/3177 and others) so we use
 * this hack to bypass any rewriting by the compiler.
 */
declare const finalized = "finalized";
/**
 * A string representing one of the supported dev mode warning categories.
 */
export declare type WarningKind = 'change-in-update' | 'migration';
export declare type Initializer = (element: ReactiveElement) => void;
/**
 * Base element class which manages element properties and attributes. When
 * properties change, the `update` method is asynchronously called. This method
 * should be supplied by subclassers to render updates as desired.
 * @noInheritDoc
 */
export declare abstract class ReactiveElement extends HTMLElement implements ReactiveControllerHost {
    /**
     * Read or set all the enabled warning categories for this class.
     *
     * This property is only used in development builds.
     *
     * @nocollapse
     * @category dev-mode
     */
    static enabledWarnings?: WarningKind[];
    /**
     * Enable the given warning category for this class.
     *
     * This method only exists in development builds, so it should be accessed
     * with a guard like:
     *
     * ```ts
     * // Enable for all ReactiveElement subclasses
     * ReactiveElement.enableWarning?.('migration');
     *
     * // Enable for only MyElement and subclasses
     * MyElement.enableWarning?.('migration');
     * ```
     *
     * @nocollapse
     * @category dev-mode
     */
    static enableWarning?: (warningKind: WarningKind) => void;
    /**
     * Disable the given warning category for this class.
     *
     * This method only exists in development builds, so it should be accessed
     * with a guard like:
     *
     * ```ts
     * // Disable for all ReactiveElement subclasses
     * ReactiveElement.disableWarning?.('migration');
     *
     * // Disable for only MyElement and subclasses
     * MyElement.disableWarning?.('migration');
     * ```
     *
     * @nocollapse
     * @category dev-mode
     */
    static disableWarning?: (warningKind: WarningKind) => void;
    /**
     * Adds an initializer function to the class that is called during instance
     * construction.
     *
     * This is useful for code that runs against a `ReactiveElement`
     * subclass, such as a decorator, that needs to do work for each
     * instance, such as setting up a `ReactiveController`.
     *
     * ```ts
     * const myDecorator = (target: typeof ReactiveElement, key: string) => {
     *   target.addInitializer((instance: ReactiveElement) => {
     *     // This is run during construction of the element
     *     new MyController(instance);
     *   });
     * }
     * ```
     *
     * Decorating a field will then cause each instance to run an initializer
     * that adds a controller:
     *
     * ```ts
     * class MyElement extends LitElement {
     *   @myDecorator foo;
     * }
     * ```
     *
     * Initializers are stored per-constructor. Adding an initializer to a
     * subclass does not add it to a superclass. Since initializers are run in
     * constructors, initializers will run in order of the class hierarchy,
     * starting with superclasses and progressing to the instance's class.
     *
     * @nocollapse
     */
    static addInitializer(initializer: Initializer): void;
    static _initializers?: Initializer[];
    /**
     * Maps attribute names to properties; for example `foobar` attribute to
     * `fooBar` property. Created lazily on user subclasses when finalizing the
     * class.
     * @nocollapse
     */
    private static __attributeToPropertyMap;
    /**
     * Marks class as having finished creating properties.
     */
    protected static [finalized]: boolean;
    /**
     * Memoized list of all element properties, including any superclass properties.
     * Created lazily on user subclasses when finalizing the class.
     * @nocollapse
     * @category properties
     */
    static elementProperties: PropertyDeclarationMap;
    /**
     * User-supplied object that maps property names to `PropertyDeclaration`
     * objects containing options for configuring reactive properties. When
     * a reactive property is set the element will update and render.
     *
     * By default properties are public fields, and as such, they should be
     * considered as primarily settable by element users, either via attribute or
     * the property itself.
     *
     * Generally, properties that are changed by the element should be private or
     * protected fields and should use the `state: true` option. Properties
     * marked as `state` do not reflect from the corresponding attribute
     *
     * However, sometimes element code does need to set a public property. This
     * should typically only be done in response to user interaction, and an event
     * should be fired informing the user; for example, a checkbox sets its
     * `checked` property when clicked and fires a `changed` event. Mutating
     * public properties should typically not be done for non-primitive (object or
     * array) properties. In other cases when an element needs to manage state, a
     * private property set with the `state: true` option should be used. When
     * needed, state properties can be initialized via public properties to
     * facilitate complex interactions.
     * @nocollapse
     * @category properties
     */
    static properties: PropertyDeclarations;
    /**
     * Memoized list of all element styles.
     * Created lazily on user subclasses when finalizing the class.
     * @nocollapse
     * @category styles
     */
    static elementStyles: Array<CSSResultOrNative>;
    /**
     * Array of styles to apply to the element. The styles should be defined
     * using the {@linkcode css} tag function, via constructible stylesheets, or
     * imported from native CSS module scripts.
     *
     * Note on Content Security Policy:
     *
     * Element styles are implemented with `<style>` tags when the browser doesn't
     * support adopted StyleSheets. To use such `<style>` tags with the style-src
     * CSP directive, the style-src value must either include 'unsafe-inline' or
     * `nonce-<base64-value>` with `<base64-value>` replaced be a server-generated
     * nonce.
     *
     * To provide a nonce to use on generated `<style>` elements, set
     * `window.litNonce` to a server-generated nonce in your page's HTML, before
     * loading application code:
     *
     * ```html
     * <script>
     *   // Generated and unique per request:
     *   window.litNonce = 'a1b2c3d4';
     * </script>
     * ```
     * @nocollapse
     * @category styles
     */
    static styles?: CSSResultGroup;
    /**
     * The set of properties defined by this class that caused an accessor to be
     * added during `createProperty`.
     * @nocollapse
     */
    private static __reactivePropertyKeys?;
    /**
     * Returns a list of attributes corresponding to the registered properties.
     * @nocollapse
     * @category attributes
     */
    static get observedAttributes(): string[];
    /**
     * Creates a property accessor on the element prototype if one does not exist
     * and stores a {@linkcode PropertyDeclaration} for the property with the
     * given options. The property setter calls the property's `hasChanged`
     * property option or uses a strict identity check to determine whether or not
     * to request an update.
     *
     * This method may be overridden to customize properties; however,
     * when doing so, it's important to call `super.createProperty` to ensure
     * the property is setup correctly. This method calls
     * `getPropertyDescriptor` internally to get a descriptor to install.
     * To customize what properties do when they are get or set, override
     * `getPropertyDescriptor`. To customize the options for a property,
     * implement `createProperty` like this:
     *
     * ```ts
     * static createProperty(name, options) {
     *   options = Object.assign(options, {myOption: true});
     *   super.createProperty(name, options);
     * }
     * ```
     *
     * @nocollapse
     * @category properties
     */
    static createProperty(name: PropertyKey, options?: PropertyDeclaration): void;
    /**
     * Returns a property descriptor to be defined on the given named property.
     * If no descriptor is returned, the property will not become an accessor.
     * For example,
     *
     * ```ts
     * class MyElement extends LitElement {
     *   static getPropertyDescriptor(name, key, options) {
     *     const defaultDescriptor =
     *         super.getPropertyDescriptor(name, key, options);
     *     const setter = defaultDescriptor.set;
     *     return {
     *       get: defaultDescriptor.get,
     *       set(value) {
     *         setter.call(this, value);
     *         // custom action.
     *       },
     *       configurable: true,
     *       enumerable: true
     *     }
     *   }
     * }
     * ```
     *
     * @nocollapse
     * @category properties
     */
    protected static getPropertyDescriptor(name: PropertyKey, key: string | symbol, options: PropertyDeclaration): PropertyDescriptor | undefined;
    /**
     * Returns the property options associated with the given property.
     * These options are defined with a `PropertyDeclaration` via the `properties`
     * object or the `@property` decorator and are registered in
     * `createProperty(...)`.
     *
     * Note, this method should be considered "final" and not overridden. To
     * customize the options for a given property, override
     * {@linkcode createProperty}.
     *
     * @nocollapse
     * @final
     * @category properties
     */
    static getPropertyOptions(name: PropertyKey): PropertyDeclaration<unknown, unknown>;
    /**
     * Creates property accessors for registered properties, sets up element
     * styling, and ensures any superclasses are also finalized. Returns true if
     * the element was finalized.
     * @nocollapse
     */
    protected static finalize(): boolean;
    /**
     * Options used when calling `attachShadow`. Set this property to customize
     * the options for the shadowRoot; for example, to create a closed
     * shadowRoot: `{mode: 'closed'}`.
     *
     * Note, these options are used in `createRenderRoot`. If this method
     * is customized, options should be respected if possible.
     * @nocollapse
     * @category rendering
     */
    static shadowRootOptions: ShadowRootInit;
    /**
     * Takes the styles the user supplied via the `static styles` property and
     * returns the array of styles to apply to the element.
     * Override this method to integrate into a style management system.
     *
     * Styles are deduplicated preserving the _last_ instance in the list. This
     * is a performance optimization to avoid duplicated styles that can occur
     * especially when composing via subclassing. The last item is kept to try
     * to preserve the cascade order with the assumption that it's most important
     * that last added styles override previous styles.
     *
     * @nocollapse
     * @category styles
     */
    protected static finalizeStyles(styles?: CSSResultGroup): Array<CSSResultOrNative>;
    /**
     * Node or ShadowRoot into which element DOM should be rendered. Defaults
     * to an open shadowRoot.
     * @category rendering
     */
    readonly renderRoot: HTMLElement | ShadowRoot;
    /**
     * Returns the property name for the given attribute `name`.
     * @nocollapse
     */
    private static __attributeNameForProperty;
    private __instanceProperties?;
    private __updatePromise;
    /**
     * True if there is a pending update as a result of calling `requestUpdate()`.
     * Should only be read.
     * @category updates
     */
    isUpdatePending: boolean;
    /**
     * Is set to `true` after the first update. The element code cannot assume
     * that `renderRoot` exists before the element `hasUpdated`.
     * @category updates
     */
    hasUpdated: boolean;
    /**
     * Map with keys of properties that should be reflected when updated.
     */
    private __reflectingProperties?;
    /**
     * Name of currently reflecting property
     */
    private __reflectingProperty;
    /**
     * Set of controllers.
     */
    private __controllers?;
    constructor();
    /**
     * Internal only override point for customizing work done when elements
     * are constructed.
     */
    private __initialize;
    /**
     * Registers a `ReactiveController` to participate in the element's reactive
     * update cycle. The element automatically calls into any registered
     * controllers during its lifecycle callbacks.
     *
     * If the element is connected when `addController()` is called, the
     * controller's `hostConnected()` callback will be immediately called.
     * @category controllers
     */
    addController(controller: ReactiveController): void;
    /**
     * Removes a `ReactiveController` from the element.
     * @category controllers
     */
    removeController(controller: ReactiveController): void;
    /**
     * Fixes any properties set on the instance before upgrade time.
     * Otherwise these would shadow the accessor and break these properties.
     * The properties are stored in a Map which is played back after the
     * constructor runs. Note, on very old versions of Safari (<=9) or Chrome
     * (<=41), properties created for native platform properties like (`id` or
     * `name`) may not have default values set in the element constructor. On
     * these browsers native properties appear on instances and therefore their
     * default value will overwrite any element default (e.g. if the element sets
     * this.id = 'id' in the constructor, the 'id' will become '' since this is
     * the native platform default).
     */
    private __saveInstanceProperties;
    /**
     * Returns the node into which the element should render and by default
     * creates and returns an open shadowRoot. Implement to customize where the
     * element's DOM is rendered. For example, to render into the element's
     * childNodes, return `this`.
     *
     * @return Returns a node into which to render.
     * @category rendering
     */
    protected createRenderRoot(): Element | ShadowRoot;
    /**
     * On first connection, creates the element's renderRoot, sets up
     * element styling, and enables updating.
     * @category lifecycle
     */
    connectedCallback(): void;
    /**
     * Note, this method should be considered final and not overridden. It is
     * overridden on the element instance with a function that triggers the first
     * update.
     * @category updates
     */
    protected enableUpdating(_requestedUpdate: boolean): void;
    /**
     * Allows for `super.disconnectedCallback()` in extensions while
     * reserving the possibility of making non-breaking feature additions
     * when disconnecting at some point in the future.
     * @category lifecycle
     */
    disconnectedCallback(): void;
    /**
     * Synchronizes property values when attributes change.
     *
     * Specifically, when an attribute is set, the corresponding property is set.
     * You should rarely need to implement this callback. If this method is
     * overridden, `super.attributeChangedCallback(name, _old, value)` must be
     * called.
     *
     * See [using the lifecycle callbacks](https://developer.mozilla.org/en-US/docs/Web/Web_Components/Using_custom_elements#using_the_lifecycle_callbacks)
     * on MDN for more information about the `attributeChangedCallback`.
     * @category attributes
     */
    attributeChangedCallback(name: string, _old: string | null, value: string | null): void;
    private __propertyToAttribute;
    /**
     * Requests an update which is processed asynchronously. This should be called
     * when an element should update based on some state not triggered by setting
     * a reactive property. In this case, pass no arguments. It should also be
     * called when manually implementing a property setter. In this case, pass the
     * property `name` and `oldValue` to ensure that any configured property
     * options are honored.
     *
     * @param name name of requesting property
     * @param oldValue old value of requesting property
     * @param options property options to use instead of the previously
     *     configured options
     * @category updates
     */
    requestUpdate(name?: PropertyKey, oldValue?: unknown, options?: PropertyDeclaration): void;
    /**
     * Sets up the element to asynchronously update.
     */
    private __enqueueUpdate;
    /**
     * Schedules an element update. You can override this method to change the
     * timing of updates by returning a Promise. The update will await the
     * returned Promise, and you should resolve the Promise to allow the update
     * to proceed. If this method is overridden, `super.scheduleUpdate()`
     * must be called.
     *
     * For instance, to schedule updates to occur just before the next frame:
     *
     * ```ts
     * override protected async scheduleUpdate(): Promise<unknown> {
     *   await new Promise((resolve) => requestAnimationFrame(() => resolve()));
     *   super.scheduleUpdate();
     * }
     * ```
     * @category updates
     */
    protected scheduleUpdate(): void | Promise<unknown>;
    /**
     * Performs an element update. Note, if an exception is thrown during the
     * update, `firstUpdated` and `updated` will not be called.
     *
     * Call `performUpdate()` to immediately process a pending update. This should
     * generally not be needed, but it can be done in rare cases when you need to
     * update synchronously.
     *
     * Note: To ensure `performUpdate()` synchronously completes a pending update,
     * it should not be overridden. In LitElement 2.x it was suggested to override
     * `performUpdate()` to also customizing update scheduling. Instead, you should now
     * override `scheduleUpdate()`. For backwards compatibility with LitElement 2.x,
     * scheduling updates via `performUpdate()` continues to work, but will make
     * also calling `performUpdate()` to synchronously process updates difficult.
     *
     * @category updates
     */
    protected performUpdate(): void | Promise<unknown>;
    /**
     * Invoked before `update()` to compute values needed during the update.
     *
     * Implement `willUpdate` to compute property values that depend on other
     * properties and are used in the rest of the update process.
     *
     * ```ts
     * willUpdate(changedProperties) {
     *   // only need to check changed properties for an expensive computation.
     *   if (changedProperties.has('firstName') || changedProperties.has('lastName')) {
     *     this.sha = computeSHA(`${this.firstName} ${this.lastName}`);
     *   }
     * }
     *
     * render() {
     *   return html`SHA: ${this.sha}`;
     * }
     * ```
     *
     * @category updates
     */
    protected willUpdate(_changedProperties: PropertyValues): void;
    private __markUpdated;
    /**
     * Returns a Promise that resolves when the element has completed updating.
     * The Promise value is a boolean that is `true` if the element completed the
     * update without triggering another update. The Promise result is `false` if
     * a property was set inside `updated()`. If the Promise is rejected, an
     * exception was thrown during the update.
     *
     * To await additional asynchronous work, override the `getUpdateComplete`
     * method. For example, it is sometimes useful to await a rendered element
     * before fulfilling this Promise. To do this, first await
     * `super.getUpdateComplete()`, then any subsequent state.
     *
     * @return A promise of a boolean that resolves to true if the update completed
     *     without triggering another update.
     * @category updates
     */
    get updateComplete(): Promise<boolean>;
    /**
     * Override point for the `updateComplete` promise.
     *
     * It is not safe to override the `updateComplete` getter directly due to a
     * limitation in TypeScript which means it is not possible to call a
     * superclass getter (e.g. `super.updateComplete.then(...)`) when the target
     * language is ES5 (https://github.com/microsoft/TypeScript/issues/338).
     * This method should be overridden instead. For example:
     *
     * ```ts
     * class MyElement extends LitElement {
     *   override async getUpdateComplete() {
     *     const result = await super.getUpdateComplete();
     *     await this._myChild.updateComplete;
     *     return result;
     *   }
     * }
     * ```
     *
     * @return A promise of a boolean that resolves to true if the update completed
     *     without triggering another update.
     * @category updates
     */
    protected getUpdateComplete(): Promise<boolean>;
    /**
     * Controls whether or not `update()` should be called when the element requests
     * an update. By default, this method always returns `true`, but this can be
     * customized to control when to update.
     *
     * @param _changedProperties Map of changed properties with old values
     * @category updates
     */
    protected shouldUpdate(_changedProperties: PropertyValues): boolean;
    /**
     * Updates the element. This method reflects property values to attributes.
     * It can be overridden to render and keep updated element DOM.
     * Setting properties inside this method will *not* trigger
     * another update.
     *
     * @param _changedProperties Map of changed properties with old values
     * @category updates
     */
    protected update(_changedProperties: PropertyValues): void;
    /**
     * Invoked whenever the element is updated. Implement to perform
     * post-updating tasks via DOM APIs, for example, focusing an element.
     *
     * Setting properties inside this method will trigger the element to update
     * again after this update cycle completes.
     *
     * @param _changedProperties Map of changed properties with old values
     * @category updates
     */
    protected updated(_changedProperties: PropertyValues): void;
    /**
     * Invoked when the element is first updated. Implement to perform one time
     * work on the element after update.
     *
     * ```ts
     * firstUpdated() {
     *   this.renderRoot.getElementById('my-text-area').focus();
     * }
     * ```
     *
     * Setting properties inside this method will trigger the element to update
     * again after this update cycle completes.
     *
     * @param _changedProperties Map of changed properties with old values
     * @category updates
     */
    protected firstUpdated(_changedProperties: PropertyValues): void;
}
//# sourceMappingURL=reactive-element.d.ts.map