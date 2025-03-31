/**
 * All FormKitMiddleware conform to the pattern of accepting a payload and a
 * `next()` function. They can either pass the payload to the next middleware
 * explicitly (as an argument of next), or implicitly (no argument for next).
 *
 * @public
 */
type FormKitMiddleware<T = unknown> = (payload: T, next: (payload: T) => T) => T;
/**
 * The FormKitDispatcher interface is responsible creating/running "hooks".
 *
 * @public
 */
interface FormKitDispatcher<T> {
    (dispatchable: FormKitMiddleware<T>): number;
    unshift: (dispatchable: FormKitMiddleware<T>) => number;
    remove: (dispatchable: FormKitMiddleware<T>) => void;
    dispatch: (payload: T) => T;
}

/**
 * Event listener functions definition.
 *
 * @public
 */
interface FormKitEventListener {
    (event: FormKitEvent): void;
    receipt?: string;
}
/**
 * The internal structure of a FormKitEvent.
 *
 * @public
 */
interface FormKitEvent {
    payload: any;
    name: string;
    bubble: boolean;
    origin: FormKitNode;
    meta?: Record<string, unknown>;
}
/**
 * The FormKitEventEmitter definition.
 *
 * @public
 */
interface FormKitEventEmitter {
    (node: FormKitNode, event: FormKitEvent): void;
    on: (eventName: string, listener: FormKitEventListener, pos?: 'push' | 'unshift') => string;
    off: (receipt: string) => void;
    pause: (node?: FormKitNode) => void;
    play: (node?: FormKitNode) => void;
    flush: () => void;
}

/**
 * The structure of a core FormKitMessage. These messages are used to store
 * information about the state of a node.
 *
 * @public
 */
interface FormKitMessageProps {
    blocking: boolean;
    key: string;
    meta: FormKitMessageMeta;
    type: string;
    value?: string | number | boolean;
    visible: boolean;
}
/**
 * A FormKit message is immutable, so all properties should be readonly.
 *
 * @public
 */
type FormKitMessage = Readonly<FormKitMessageProps>;
/**
 * A registry of input messages that should be applied to children of the node
 * they are passed to — where the string key of the object is the address of
 * the node to apply the messages on and the value is the message itself.
 *
 * @public
 */
interface FormKitInputMessages {
    [address: string]: FormKitMessage[];
}
/**
 * Child messages that were not immediately applied due to the child not existing.
 *
 * @public
 */
type ChildMessageBuffer = Map<string, Array<[FormKitMessage[], MessageClearer | undefined]>>;
/**
 * A string or function that allows clearing messages.
 *
 * @public
 */
type MessageClearer = string | ((message: FormKitMessage) => boolean);
/**
 * Messages have can have any arbitrary meta data attached to them.
 *
 * @public
 */
interface FormKitMessageMeta {
    [index: string]: any;
    /**
     * If this property is set, then message producers (like formkit/i18n) should
     * use this key instead of the message key as the lookup for the proper
     * message to produce.
     */
    messageKey?: string;
    /**
     * If this property is set on a message then only the values in this property
     * will be passed as arguments to an i18n message localization function.
     */
    i18nArgs?: any[];
}
/**
 * Defines the actual store of messages.
 *
 * @public
 */
interface FormKitMessageStore {
    [index: string]: FormKitMessage;
}
/**
 * The message store contains all of the messages that pertain to a given node.
 *
 * @public
 */
type FormKitStore = FormKitMessageStore & {
    _n: FormKitNode;
    _b: Array<[messages: FormKitMessage[], clear?: MessageClearer]>;
    _m: ChildMessageBuffer;
    _r?: string;
    buffer: boolean;
} & FormKitStoreTraps;
/**
 * The available traps on the FormKit store.
 *
 * @public
 */
interface FormKitStoreTraps {
    apply: (messages: Array<FormKitMessage> | FormKitInputMessages, clear?: MessageClearer) => void;
    set: (message: FormKitMessageProps) => FormKitStore;
    remove: (key: string) => FormKitStore;
    filter: (callback: (message: FormKitMessage) => boolean, type?: string) => FormKitStore;
    reduce: <T>(reducer: (accumulator: T, message: FormKitMessage) => T, accumulator: T) => T;
    release: () => void;
    touch: () => void;
}
/**
 * Creates a new FormKitMessage object.
 *
 * ```ts
 * // default:
 * {
 *   blocking: false,
 *   key: token(),
 *   meta: {},
 *   type: 'state',
 *   visible: true,
 * }
 * ```
 *
 * @param conf - An object of optional properties of {@link FormKitMessage | FormKitMessage}.
 * @param node - A {@link @formkit/node#FormKitNode | FormKitNode}.
 * @returns A {@link FormKitMessageProps | FormKitMessageProps}.
 *
 * @public
 */
declare function createMessage(conf: Partial<FormKitMessage>, node?: FormKitNode): FormKitMessageProps;
/**
 * Error messages.
 *
 * @public
 */
type ErrorMessages = string | string[] | Record<string, string | string[]>;

/**
 * The FormKit ledger, a general-purpose message counting service provided by
 * FormKit core for counting messages throughout a tree.
 *
 * @public
 */
interface FormKitLedger {
    count: (name: string, condition?: FormKitCounterCondition, increment?: number) => Promise<void>;
    init: (node: FormKitNode) => void;
    merge: (child: FormKitNode) => void;
    settled: (name: string) => Promise<void>;
    unmerge: (child: FormKitNode) => void;
    value: (name: string) => number;
}
/**
 * Ledger counters require a condition function that determines if a given
 * message applies to it or not.
 *
 * @public
 */
interface FormKitCounterCondition {
    (message: FormKitMessage): boolean;
}
/**
 * The counter object used to perform instance counting within
 * a tree.
 *
 * @public
 */
interface FormKitCounter {
    condition: FormKitCounterCondition;
    count: number;
    name: string;
    node: FormKitNode;
    promise: Promise<void>;
    resolve: () => void;
}

/**
 * The value being listed out. Can be an array, an object, or a number.
 *
 * @public
 */
type FormKitListValue = string | Record<string, any> | Array<string | number | Record<string, any>> | number;
/**
 * A full loop statement in tuple syntax. Can be read like "foreach value, key? in list".
 *
 * @public
 */
type FormKitListStatement = [value: any, key: number | string, list: FormKitListValue] | [value: any, list: FormKitListValue];
/**
 * Meta attributes are not used when parsing the schema, but can be used to
 * create tooling.
 *
 * @public
 */
type FormKitSchemaMeta = {
    [key: string]: string | number | boolean | undefined | null | CallableFunction | FormKitSchemaMeta;
};
/**
 * Properties available in all schema nodes.
 *
 * @public
 */
interface FormKitSchemaProps {
    children?: string | FormKitSchemaNode[] | FormKitSchemaCondition;
    key?: string;
    if?: string;
    for?: FormKitListStatement;
    bind?: string;
    meta?: FormKitSchemaMeta;
}
/**
 * Properties available when using a DOM node.
 *
 * @public
 */
type FormKitSchemaDOMNode = {
    $el: string | null;
    attrs?: FormKitSchemaAttributes;
} & FormKitSchemaProps;
/**
 * A simple text node.
 *
 * @public
 */
type FormKitSchemaTextNode = string;
/**
 * The possible value types of attributes (in the schema).
 *
 * @public
 */
type FormKitAttributeValue = string | number | boolean | undefined | FormKitSchemaAttributes | FormKitSchemaAttributesCondition;
/**
 * Conditions nested inside attribute declarations.
 *
 * @public
 */
interface FormKitSchemaAttributesCondition {
    if: string;
    then: FormKitAttributeValue;
    else?: FormKitAttributeValue;
}
/**
 * DOM attributes are simple string dictionaries.
 *
 * @public
 */
type FormKitSchemaAttributes = {
    [index: string]: FormKitAttributeValue;
} | null | FormKitSchemaAttributesCondition;
/**
 * Properties available when defining a generic non-FormKit component.
 *
 * @public
 */
type FormKitSchemaComponent = {
    $cmp: string;
    props?: Record<string, any>;
} & FormKitSchemaProps;
/**
 * Syntactic sugar for a FormKitSchemaComponent node that uses FormKit.
 *
 * @public
 */
type FormKitSchemaFormKit = {
    $formkit: string;
} & Record<string, any> & FormKitSchemaProps;
/**
 * A schema node that determines _which_ content to render.
 *
 * @public
 */
type FormKitSchemaCondition = {
    if: string;
    then: FormKitSchemaNode | FormKitSchemaNode[];
    else?: FormKitSchemaNode | FormKitSchemaNode[];
};
/**
 * The context that is passed from one schema render to the next.
 *
 * @public
 */
interface FormKitSchemaContext {
    [index: string]: any;
    __FK_SCP: Map<symbol, Record<string, any>>;
}
/**
 * Properties available then defining a schema node.
 *
 * @public
 */
type FormKitSchemaNode = FormKitSchemaDOMNode | FormKitSchemaComponent | FormKitSchemaTextNode | FormKitSchemaCondition | FormKitSchemaFormKit;
/**
 * An entire schema object or subtree from any entry point. Can be a single
 * node, an array of nodes, or a conditional. This is the type that is passed to
 * the FormKitSchema constructor.
 *
 * @public
 */
type FormKitSchemaDefinition = FormKitSchemaNode | FormKitSchemaNode[] | FormKitSchemaCondition;
/**
 * Definition for a function that can extend a given schema node.
 *
 * @public
 */
interface FormKitSchemaComposable {
    (extendWith?: Partial<FormKitSchemaNode>, children?: string | FormKitSchemaNode[] | FormKitSchemaCondition, ...args: any[]): FormKitSchemaNode;
}
/**
 * The shape of the schema definition overrides/extensions.
 * @public
 */
type FormKitSectionsSchema = Record<string, Partial<FormKitSchemaNode> | FormKitSchemaCondition | null>;
/**
 * Defines a function that allows selectively overriding a given schema.
 *
 * @public
 */
interface FormKitExtendableSchemaRoot {
    (extensions: FormKitSectionsSchema): FormKitSchemaDefinition;
    memoKey?: string;
}
/**
 * Type narrow that a node is a DOM node.
 *
 * @param node - A schema node to check
 *
 * @returns `boolean`
 *
 * @public
 */
declare function isDOM(node: string | Record<PropertyKey, any>): node is FormKitSchemaDOMNode;
/**
 * Type narrow that a node is a DOM node.
 *
 * @param node - A schema node to check.
 *
 * @returns `boolean`
 *
 * @public
 */
declare function isComponent(node: string | Record<PropertyKey, any>): node is FormKitSchemaComponent;
/**
 * Determines if a node is conditionally rendered or not.
 *
 * @param node - A schema node to check.
 *
 * @returns `boolean`
 *
 * @public
 */
declare function isConditional(node: FormKitSchemaNode): node is FormKitSchemaCondition;
/**
 * Determines if an attribute is a conditional.
 *
 * @param node - A schema node to check.
 *
 * @returns `boolean`
 *
 * @public
 */
declare function isConditional(node: FormKitSchemaAttributesCondition | FormKitSchemaAttributes): node is FormKitSchemaAttributesCondition;
/**
 * Determines if the node is syntactic sugar or not.
 *
 * @param node - A schema node to check.
 *
 * @returns `boolean`
 *
 * @public
 */
declare function isSugar(node: FormKitSchemaNode): node is FormKitSchemaFormKit;
/**
 * Converts syntactic sugar nodes to standard nodes.
 *
 * @param node - A node to covert.
 *
 * @returns A {@link FormKitSchemaNode | FormKitSchemaNode} without the properties of {@link FormKitSchemaFormKit | FormKitSchemaFormKit}.
 *
 * @public
 */
declare function sugar<T extends FormKitSchemaNode>(node: T): Exclude<FormKitSchemaNode, string | FormKitSchemaFormKit>;

/**
 * Definition for a function that produces CSS classes.
 *
 * @public
 */
interface FormKitClasses {
    (node: FormKitNode, sectionKey: string): string | Record<string, boolean>;
}
/**
 * Function that produces a standardized object representation of CSS classes.
 *
 * @param propertyKey - the section key.
 * @param node - A {@link FormKitNode | FormKitNode}.
 * @param sectionClassList - A `string | Record<string, boolean>` or a {@link FormKitClasses | FormKitClasses}.
 *
 * @returns `Record<string, boolean>`
 *
 * @public
 */
declare function createClasses(propertyKey: string, node: FormKitNode, sectionClassList?: FormKitClasses | string | Record<string, boolean>): Record<string, boolean>;
/**
 * Combines multiple class lists into a single list.
 *
 * @param node - A {@link FormKitNode | FormKitNode}.
 * @param property - The property key to which the class list will be applied.
 * @param args - And array of `Record<string, boolean>` of CSS class list(s).
 *
 * @returns `string | null`
 *
 * @public
 */
declare function generateClassList(node: FormKitNode, property: string, ...args: Record<string, boolean>[]): string | null;

/**
 * Global configuration options.
 *
 * @public
 */
type FormKitRootConfig = Partial<FormKitConfig> & {
    _add: (node: FormKitNode) => void;
    _rm: (node: FormKitNode) => void;
};
/**
 * Creates a new instance of a global configuration option. This object is
 * essentially just a FormKitOption object, but it can be used as the root for
 * FormKitConfig's proxy and retain event "emitting".
 *
 * @param options - An object of optional properties of {@link FormKitConfig | FormKitConfig}.
 *
 * @returns A {@link FormKitRootConfig | FormKitRootConfig}.
 *
 * @public
 */
declare function createConfig(options?: Partial<FormKitConfig>): FormKitRootConfig;

/**
 * Definition of a library item — when registering a new library item, these
 * are the required and available properties.
 *
 * @public
 */
type FormKitTypeDefinition<V = unknown> = {
    /**
     * The FormKit core node type. Can only be input | list | group.
     */
    type: FormKitNodeType;
    /**
     * Groups the input into a given family of inputs, generally for styling
     * purposes only. For example the "text" family would apply to all text-like
     * inputs.
     */
    family?: string;
    /**
     * An optional name for the input’s type (e.g. "select" for a select input).
     * If used, this value takes precedence over the "type" prop string.
     */
    forceTypeProp?: string;
    /**
     * Custom props that should be added to the input.
     */
    props?: FormKitPseudoProps;
    /**
     * The schema used to create the input. Either this or the component is
     * required.
     */
    schema?: FormKitExtendableSchemaRoot | FormKitSchemaNode[] | FormKitSchemaCondition;
    /**
     * A component to use to render the input. Either this or the schema is
     * required.
     */
    component?: unknown;
    /**
     * A library of components to provide to the internal input schema.
     */
    library?: Record<string, unknown>;
    /**
     * An array of additional feature functions to load when booting the input.
     */
    features?: Array<(node: FormKitNode<V>) => void>;
    /**
     * An optional string to use as a comparison key for memoizing the schema.
     */
    schemaMemoKey?: string;
};
/**
 * A library of inputs, keyed by the name of the type.
 *
 * @public
 */
interface FormKitLibrary {
    [index: string]: FormKitTypeDefinition;
}
/**
 * The base interface definition for a FormKitPlugin. It's just a function that
 * accepts a node argument.
 *
 * @public
 */
interface FormKitPlugin {
    (node: FormKitNode): false | any | void;
    library?: (node: FormKitNode) => void;
}
/**
 * Text fragments are small pieces of text used for things like interface
 * validation messages, or errors that may be exposed for modification or
 * even translation.
 *
 * @public
 */
type FormKitTextFragment = Partial<FormKitMessageProps> & {
    key: string;
    value: string;
    type: string;
};
/**
 * The available hooks for middleware.
 *
 * @public
 */
interface FormKitHooks {
    classes: FormKitDispatcher<{
        property: string;
        classes: Record<string, boolean>;
    }>;
    commit: FormKitDispatcher<any>;
    error: FormKitDispatcher<string>;
    setErrors: FormKitDispatcher<{
        localErrors: ErrorMessages;
        childErrors?: ErrorMessages;
    }>;
    init: FormKitDispatcher<FormKitNode>;
    input: FormKitDispatcher<any>;
    submit: FormKitDispatcher<Record<string, any>>;
    message: FormKitDispatcher<FormKitMessage>;
    prop: FormKitDispatcher<{
        prop: string | symbol;
        value: any;
    }>;
    text: FormKitDispatcher<FormKitTextFragment>;
    schema: FormKitDispatcher<FormKitSchemaNode[] | FormKitSchemaCondition>;
}
/**
 * The definition of a FormKitTrap. These are somewhat like methods on each
 * FormKitNode. They are always symmetrical (get/set) — although it's acceptable
 * for either to throw an Exception.
 *
 * @public
 */
interface FormKitTrap {
    get: TrapGetter;
    set: TrapSetter;
}
/**
 * Describes the path to a particular node from the top of the tree.
 *
 * @public
 */
type FormKitAddress = Array<string | number>;
/**
 * These are the types of nodes that can be created. These are different from
 * the type of inputs available and rather describe their purpose in the tree.
 *
 * @public
 */
type FormKitNodeType = 'input' | 'list' | 'group';
/**
 * FormKit inputs of type 'group' must have keyed values by default.
 *
 * @public
 */
interface FormKitGroupValue {
    [index: string]: unknown;
    __init?: boolean;
}
/**
 * FormKit inputs of type 'list' must have array values by default.
 *
 * @public
 */
type FormKitListContextValue<T = any> = Array<T>;
/**
 * Arbitrary data that has properties. Could be a POJO, could be an array.
 *
 * @public
 */
interface KeyedValue {
    [index: number]: any;
    [index: string]: any;
}
/**
 * Define the most basic shape of a context object for type guards trying to
 * reason about a context's value.
 *
 * @public
 */
interface FormKitContextShape {
    type: FormKitNodeType;
    value: unknown;
    _value: unknown;
}
/**
 * The simplest definition for a context of type "list".
 *
 * @public
 */
interface FormKitListContext {
    type: 'list';
    value: FormKitListContextValue;
    _value: FormKitListContextValue;
}
/**
 * Signature for any of the node's getter traps. Keep in mind that because these
 * are traps and not class methods, their response types are declared explicitly
 * in the FormKitNode interface.
 *
 * @public
 */
type TrapGetter = ((node: FormKitNode, context: FormKitContext, ...args: any[]) => unknown) | false;
/**
 * The signature for a node's trap setter — these are more rare than getter
 * traps, but can be useful for blocking access to certain context properties
 * or modifying the behavior of an assignment (ex. see setParent).
 *
 * @public
 */
type TrapSetter = ((node: FormKitNode, context: FormKitContext, property: string | number | symbol, value: any) => boolean | never) | false;
/**
 * The map signature for a node's traps Map.
 *
 * @public
 */
type FormKitTraps = Map<string | symbol, FormKitTrap>;
/**
 * General "app" like configuration options, these are automatically inherited
 * by all children — they are not reactive.
 *
 * @public
 */
interface FormKitConfig {
    /**
     * The delimiter character to use for a node’s tree address. By default this
     * is a dot `.`, but if you use dots in your input names you may want to
     * change this to something else.
     */
    delimiter: string;
    /**
     * Classes to apply on the various sections. These classes are applied after
     * rootClasses has already run.
     */
    classes?: Record<string, FormKitClasses | string | Record<string, boolean>>;
    /**
     * The rootClasses function is called to allocate the base layer of classes
     * for each section. These classes can be further extended or modified by the
     * classes config, classes prop, and section-class props.
     */
    rootClasses: ((sectionKey: string, node: FormKitNode) => Record<string, boolean>) | false;
    /**
     * A root config object. This object is usually the globally defined options.
     */
    rootConfig?: FormKitRootConfig;
    /**
     * The merge strategy is a map of names to merge strategies. The merge
     * strategy is used to determine how a node’s value should be merged if there
     * are 2 nodes with the same name.
     */
    mergeStrategy?: Record<string | symbol, 'synced'>;
    [index: string]: any;
}
/**
 * The user-land per-instance "props", which are generally akin to the props
 * passed into components on the front end.
 *
 * @public
 */
type FormKitProps<V = unknown> = {
    /**
     * An instance of the current document’s root. When inside the context of a
     * custom element, this will be the ShadowRoot. In most other instances this
     * will be the Document. During SSR and other server-side contexts this will
     * be undefined.
     */
    __root?: Document | ShadowRoot;
    /**
     * An object or array of "props" that should be applied to the input. When
     * using Vue, these are pulled from the attrs and placed into the node.props
     * according to the definition provided here.
     */
    readonly __propDefs: FormKitPseudoProps;
    /**
     * The total amount of time in milliseconds to debounce the input before the
     * committing the value to the form tree.
     */
    delay: number;
    /**
     * The unique id of the input. These should *always* be globally unique.
     */
    id: string;
    /**
     * A function that defines how the validationLabel should be provided. By
     * default this is the validation-label, label, then name in decreasing
     * specificity.
     */
    validationLabelStrategy?: (node?: FormKitNode) => string;
    /**
     * An object of validation rules.
     */
    validationRules?: Record<string, (node: FormKitNode, ...args: any[]) => boolean | Promise<boolean>>;
    /**
     * An object of validation messages.
     */
    validationMessages?: Record<string, ((ctx: {
        name: string;
        args: any[];
        node: FormKitNode;
    }) => string) | string>;
    /**
     * The definition of the node’s input type (if it has one).
     */
    definition?: FormKitTypeDefinition<V>;
    /**
     * The framework’s context object. This is how FormKit’s core interacts with
     * the front end framework (Vue/React/etc). This object is created by the
     * component and is responsible for providing all the data to the framework
     * for rendering and interaction.
     */
    context?: FormKitFrameworkContext;
    /**
     * The merge strategy that is applied to this specific node. It can only be
     * inherited by a parent by using the mergeStrategy config option.
     */
    readonly mergeStrategy?: 'synced';
    [index: string]: any;
} & FormKitConfig;
/**
 * The interface of a FormKit node's context object. A FormKit node is a
 * proxy of this object.
 *
 * @public
 */
interface FormKitContext {
    /**
     * A node’s internal disturbance counter.
     */
    _d: number;
    /**
     * A node’s internal event emitter.
     */
    _e: FormKitEventEmitter;
    /**
     * A unique identifier for a node.
     */
    uid: symbol;
    /**
     * A node’s internal disturbance counter promise.
     */
    _resolve: ((value: unknown) => void) | false;
    /**
     * A node’s internal input timeout.
     */
    _tmo: number | false;
    /**
     * A node’s internal pre-commit value.
     */
    _value: unknown;
    /**
     * An array of child nodes (groups and lists)
     */
    children: Array<FormKitNode | FormKitPlaceholderNode>;
    /**
     * Configuration state for a given tree.
     */
    config: FormKitConfig;
    /**
     * The context object of the current front end framework being used.
     */
    context?: FormKitFrameworkContext;
    /**
     * Set of hooks
     */
    hook: FormKitHooks;
    /**
     * Begins as false, set to true when the node is finished being created.
     */
    isCreated: boolean;
    /**
     * Boolean determines if the node is in a settled state or not.
     */
    isSettled: boolean;
    /**
     * A counting ledger for arbitrary message counters.
     */
    ledger: FormKitLedger;
    /**
     * The name of the input — should be treated as readonly.
     */
    name: string | symbol;
    /**
     * The parent of a node.
     */
    parent: FormKitNode | null;
    /**
     * A Set of plugins registered on this node that can be inherited by children.
     */
    plugins: Set<FormKitPlugin>;
    /**
     * An proxied object of props. These are typically provided by the adapter
     * of choice.
     */
    props: Partial<FormKitProps>;
    /**
     * A promise that resolves when an input is in a settled state.
     */
    settled: Promise<unknown>;
    /**
     * The internal node store.
     */
    store: FormKitStore;
    /**
     * The traps available to a node.
     */
    traps: FormKitTraps;
    /**
     * The type of node, should only be 'input', 'list', or 'group'.
     */
    type: FormKitNodeType;
    /**
     * Only used on list nodes, this flag determines whether or not the list
     * should sync its values with the underlying node children.
     */
    sync: boolean;
    /**
     * The actual value of the node.
     */
    value: unknown;
}
/**
 * Context object to be created by and used by each respective UI framework. No
 * values are created or output by FormKitCore, but this interface
 * should be followed by each respective plugin.
 *
 * @public
 */
interface FormKitFrameworkContext<T = any> {
    [index: string]: unknown;
    /**
     * The current "live" value of the input. Not debounced.
     */
    _value: T;
    /**
     * The root document or shadow root the input is inside. This can be set by
     * using a higher-order `<FormKitRoot>` component.
     */
    __root?: Document | ShadowRoot;
    /**
     * An object of attributes that (generally) should be applied to the root
     * <input> element.
     */
    attrs: Record<string, any>;
    /**
     * Classes to apply on the various sections.
     */
    classes: Record<string, string>;
    /**
     * Event handlers.
     */
    handlers: {
        blur: (e?: FocusEvent) => void;
        touch: () => void;
        DOMInput: (e: Event) => void;
    } & Record<string, (...args: any[]) => void>;
    /**
     * Utility functions, generally for use in the input’s schema.
     */
    fns: Record<string, (...args: any[]) => any>;
    /**
     * The help text of the input.
     */
    help?: string;
    /**
     * The unique id of the input. Should also be applied as the id attribute.
     * This is generally required for accessibility reasons.
     */
    id: string;
    /**
     * An array of symbols that represent the a child’s nodes. These are not the
     * child’s nodes but are just symbols representing them. They are used to
     * iterate over the children for rendering purposes.
     */
    items: symbol[];
    /**
     * The label of the input.
     */
    label?: string;
    /**
     * A list of messages to be displayed on the input. Often these are validation
     * messages and error messages, but other `visible` core node messages do also
     * apply here. This object is only populated when the validation should be
     * actually displayed.
     */
    messages: Record<string, FormKitMessage>;
    /**
     * The core node of this input.
     */
    node: FormKitNode;
    /**
     * If this input type accepts options (like select lists and checkboxes) then
     * this will be populated with a properly structured list of options.
     */
    options?: Array<Record<string, any> & {
        label: string;
        value: any;
    }>;
    /**
     * Whether or not to render messages in the standard location.
     */
    defaultMessagePlacement: boolean;
    /**
     * A record of slots that have been passed into the top level component
     * responsible for creating the node.
     */
    slots: Record<string, CallableFunction>;
    /**
     * A collection of state trackers/details about the input.
     */
    state: FormKitFrameworkContextState;
    /**
     * The type of input "text" or "select" (retrieved from node.props.type). This
     * is not the core node type (input, group, or list).
     */
    type: string;
    /**
     * Translated ui messages that are not validation related. These are generally
     * used for interface messages like "loading" or "saving".
     */
    ui: Record<string, FormKitMessage>;
    /**
     * The current committed value of the input. This is the value that should be
     * used for most use cases.
     */
    value: T;
}
/**
 * The state inside a node’s framework context. Usually used to track things
 * like blurred and validity states.
 *
 * @public
 */
interface FormKitFrameworkContextState {
    /**
     * If the input has been blurred.
     */
    blurred: boolean;
    /**
     * True when these conditions are met:
     *
     * Either:
     * - The input has validation rules
     * - The validation rules are all passing
     * - There are no errors on the input
     * Or:
     * - The input has no validation rules
     * - The input has no errors
     * - The input is dirty and has a value
     *
     * This is not intended to be used on forms/groups/lists but instead on
     * individual inputs. Imagine placing a green checkbox next to each input
     * when the user filled it out correctly — thats what these are for.
     */
    complete: boolean;
    /**
     * If the input has had a value typed into it or a change made to it.
     */
    dirty: boolean;
    /**
     * If the input has explicit errors placed on it, or in the case of a group,
     * list, or form, this is true if any children have errors on them.
     */
    errors: boolean;
    /**
     * Determines if the input should be considered "invalid" — note that this
     * is not the opposite of the valid state. A valid input is one where the
     * input is not loading, not pending validation, not unsettled, and
     * passes all validation rules. An invalid input is one whose validation
     * rules are not explicitly not passing, and those rules are visible to the user.
     */
    invalid: boolean;
    /**
     * Whether or not the input includes the "required" validation rule. This rule
     * is uniquely called out for accessibility reasons and should be used to
     * power the `aria-required` attribute.
     */
    required: boolean;
    /**
     * True when the input has validation rules. Has nothing to do with the
     * state of those validation rules.
     */
    rules: boolean;
    /**
     * True when the input has completed its internal debounce cycle and the
     * value was committed to the form.
     */
    settled: boolean;
    /**
     * If the form has been submitted.
     */
    submitted: boolean;
    /**
     * If the input (or group/form/list) is passing all validation rules. In
     * the case of groups, forms, and lists this includes the validation state
     * of all its children.
     */
    valid: boolean;
    /**
     * If the validation-visibility has been satisfied and any validation
     * messages should be displayed.
     */
    validationVisible: boolean;
    /**
     * Allow users to add their own arbitrary states.
     */
    [index: string]: boolean;
}
/**
 * Options that can be used to instantiate a new node via `createNode()`.
 *
 * @public
 */
type FormKitOptions = Partial<Omit<FormKitContext, 'children' | 'plugins' | 'config' | 'hook'> & {
    /**
     * Config settings for the node, these are automatically exposed as props
     * but are also checked in during hierarchical for prop checking.
     */
    config: Partial<FormKitConfig>;
    /**
     * Props directly set on this node, these are not inherited.
     */
    props: Partial<FormKitProps>;
    /**
     * The children of the node.
     */
    children: FormKitNode[] | Set<FormKitNode>;
    /**
     * The explicit index of this node when used in a list. If specified, this
     * node will be created at this index atomically.
     */
    index?: number;
    /**
     * Should only be specified on list nodes — when true this indicates if the
     * list node should automatically sync its child nodes with the value of
     * the list node. In other words, if the list node’s value is an array of
     * strings, and one string is popped off, the corresponding node should be
     * removed the list and destroyed.
     */
    sync: boolean;
    /**
     * Any plugins that should be registered on this node explicitly. These will
     * automatically be inherited by any children.
     */
    plugins: FormKitPlugin[];
    /**
     * For internal use only.
     */
    alias: string;
    /**
     * For internal use only.
     */
    schemaAlias: string;
}>;
/**
 * The callback type for node.each().
 *
 * @public
 */
interface FormKitChildCallback {
    (child: FormKitNode): any;
}
/**
 * A descriptor of a child value, generally passed up a node tree.
 *
 * @public
 */
interface FormKitChildValue {
    name: string | number | symbol;
    value: any;
    from?: number | symbol;
}
/**
 * An empty interface for adding FormKit node extensions.
 * @public
 */
interface FormKitNodeExtensions {
}
/**
 * FormKit's Node object produced by createNode(). Every `<FormKit />` input has
 * 1 FormKitNode ("core node") associated with it. All inputs, forms, and groups
 * are instances of nodes. Read more about core nodes in the
 * {@link https://formkit.com/essentials/architecture#node | architecture
 * documentation.}
 *
 * @param add -
 * Add a child to a node. The node must be a group or list.
 *
 * #### Signature
 *
 * ```typescript
 * add: (node: FormKitNode, index?: number) => FormKitNode
 * ```
 *
 * #### Parameters
 *
 * - node — A {@link FormKitNode | FormKitNode}.
 * - index *optional* — A index to where it will added to.
 *
 * #### Returns
 *
 * The added {@link FormKitNode | FormKitNode}.
 *
 * @param address -
 * The address of the current node from the root of the tree.
 *
 * #### Signature
 *
 * ```typescript
 * address: FormKitAddress
 * ```
 *
 * #### Returns
 *
 * A {@link FormKitAddress | FormKitAddress}.
 *
 * @param addProps -
 * Adds props to the given node by removing them from node.props.attrs and
 * moving them to the top-level node.props object.
 *
 * #### Signature
 *
 * ```typescript
 * addProps: (props: string[]) => FormKitNode
 * ```
 *
 * #### Parameters
 *
 * - `props` — An array of strings to be added as keys for props.
 *
 * #### Returns
 *
 * The {@link FormKitNode | FormKitNode}.
 *
 * @param at -
 * Gets a node at another address. Addresses are dot-syntax paths (or arrays) of node names.
 * For example: `form.users.0.first_name`. There are a few "special" traversal tokens as well:
 *
 * - `$root` — Selects the root node.
 * - `$parent` — Selects the parent node.
 * - `$self` — Selects the current node.
 *
 * #### Signature
 *
 * ```typescript
 * at: (address: FormKitAddress | '$root' | '$parent' | '$self' | (string & {})) => FormKitNode | undefined
 * ```
 *
 * #### Parameters
 *
 * - `address` — An valid string or {@link FormKitAddress | FormKitAddress}.
 *
 * #### Returns
 *
 * The found {@link FormKitNode | FormKitNode} or `undefined`.
 *
 * @param children -
 * An array of child nodes (groups and lists).
 *
 * #### Signature
 *
 * ```typescript
 * children: Array<FormKitNode>
 * ```
 *
 * #### Returns
 *
 * An array of {@link FormKitNode | FormKitNode}.
 *
 * @param clearErrors -
 * Clears the errors of the node, and optionally all the children.
 *
 * #### Signature
 *
 * ```typescript
 * clearErrors: (clearChildren?: boolean, sourceKey?: string) => FormKitNode
 * ```
 *
 * #### Parameters
 *
 * - `clearChildren` *optional* — If it should clear the children.
 * - `sourceKey` *optional* — A source key to use for reset.
 *
 * #### Returns
 *
 * The {@link FormKitNode | FormKitNode}.
 *
 * @param config -
 * An object of {@link FormKitConfig | FormKitConfig} that is shared tree-wide
 * with various configuration options that should be applied to the entire tree.
 *
 * #### Signature
 *
 * ```typescript
 * config: FormKitConfig
 * ```
 *
 * #### Returns
 *
 * A {@link FormKitConfig | FormKitConfig}.
 *
 * @param define -
 * Defines the current input's library type definition including node type,
 * schema, and props.
 *
 * #### Signature
 *
 * ```typescript
 * define: (definition: FormKitTypeDefinition) => void
 * ```
 *
 * #### Parameters
 *
 * - `definition` — A {@link FormKitTypeDefinition | FormKitTypeDefinition}.
 *
 * @param destroy -
 * Removes the node from the global registry, its parent, and emits the
 * 'destroying' event.
 *
 * #### Signature
 *
 * ```typescript
 * destroy: () => void
 * ```
 *
 * @param each -
 * Perform given callback on each of the given node's children.
 *
 * #### Signature
 *
 * ```typescript
 * each: (callback: FormKitChildCallback) => void
 * ```
 *
 * #### Parameters
 *
 * - `callback` — A {@link FormKitChildCallback | FormKitChildCallback} to be called for each child.
 *
 * @param emit -
 * Emit an event from the node so it can be listened by {@link FormKitNode | on}.
 *
 * #### Signature
 *
 * ```typescript
 * emit: (event: string, payload?: any, bubble?: boolean, meta: Record<string, unknown>) => FormKitNode
 * ```
 *
 * #### Parameters
 *
 * - `event` — The event name to be emitted.
 * - `payload` *optional* — A value to be passed together with the event.
 * - `bubble` *optional* — If the event should bubble to the parent.
 *
 * #### Returns
 *
 * The {@link FormKitNode | FormKitNode}.
 *
 * @param extend -
 * Extend a {@link FormKitNode | FormKitNode} by adding arbitrary properties
 * that are accessible via `node.{property}()`.
 *
 * #### Signature
 *
 * ```typescript
 * extend: (property: string, trap: FormKitTrap) => FormKitNode
 * ```
 *
 * #### Parameters
 *
 * - `property` — The property to add the core node (`node.{property}`).
 * - `trap` — An object with a get and set property.
 *
 * #### Returns
 *
 * The {@link FormKitNode | FormKitNode}.
 *
 * @param find -
 * Within a given tree, find a node matching a given selector. Selectors can be simple strings or a function.
 *
 * #### Signature
 *
 * ```typescript
 * find: (
 *  selector: string,
 *  searcher?: keyof FormKitNode | FormKitSearchFunction
 * ) => FormKitNode | undefined
 * ```
 *
 * #### Parameters
 *
 * - `selector` — A selector string.
 * - `searcher` *optional* — A keyof {@link FormKitNode | FormKitNode} or {@link FormKitSearchFunction | FormKitSearchFunction}.
 *
 * #### Returns
 *
 * The found {@link FormKitNode | FormKitNode} or `undefined`.
 *
 * @param hook -
 * Set of hooks.
 *
 * #### Signature
 *
 * ```typescript
 * hook: FormKitHooks
 * ```
 *
 * #### Returns
 *
 * The {@link FormKitHooks | FormKitHooks}.
 *
 * @param index -
 * The index of a node compared to its siblings. This is only applicable in cases where a node is a child of a list.
 *
 * #### Signature
 *
 * ```typescript
 * index: number
 * ```
 *
 * #### Returns
 *
 * A `number`.
 *
 * @param input -
 * The function used to set the value of a node. All changes to a node's value
 * should use this function as it ensures the tree's state is always fully tracked.
 *
 * #### Signature
 *
 * ```typescript
 * input: (value: unknown, async?: boolean) => Promise<unknown>
 * ```
 *
 * #### Parameters
 *
 * - `value` — Any value to used for the node.
 * - `async` *optional* — If the input should happen asynchronously.
 *
 * #### Returns
 *
 * A `Promise<unknown>`.
 *
 * @param isCreated -
 * Begins as false, set to true when the node is finished being created.
 *
 * #### Signature
 *
 * ```typescript
 * isCreated: boolean
 * ```
 *
 * #### Returns
 *
 * A `boolean`.
 *
 * @param isSettled -
 * Boolean reflecting the settlement state of the node and its subtree.
 *
 * #### Signature
 *
 * ```typescript
 * isSettled: boolean
 * ```
 *
 * #### Returns
 *
 * A `boolean`.
 *
 * @param ledger -
 * A counting ledger for arbitrary message counters.
 *
 * #### Signature
 *
 * ```typescript
 * ledger: FormKitLedger
 * ```
 *
 * #### Returns
 *
 * A {@link FormKitLedger | FormKitLedger}.
 *
 * @param name -
 * The name of the input in the node tree. When a node is a child of a list,
 * this automatically becomes its index.
 *
 * #### Signature
 *
 * ```typescript
 * name: string
 * ```
 *
 * #### Returns
 *
 * A `string`.
 *
 * @param off -
 * Removes an event listener by its token.
 * Receipts can be shared among many event listeners by explicitly declaring the "receipt" property of the listener function.
 *
 * #### Signature
 *
 * ```typescript
 * off: (receipt: string) => FormKitNode
 * ```
 *
 * #### Parameters
 *
 * - `receipt` — A receipt generated by the `on` function.
 *
 * #### Returns
 *
 * A receipt `string`.
 *
 * @param on -
 * Adds an event listener for a given event, and returns a "receipt" which is a random string token.
 * This token should be used to remove the listener in the future.
 * Alternatively you can assign a "receipt" property to the listener function and that receipt will be used instead.
 * This allows multiple listeners to all be de-registered with a single off() call if they share the same receipt.
 *
 * #### Signature
 *
 * ```typescript
 * on: (eventName: string, listener: FormKitEventListener, pos: 'push' | 'unshift') => string
 * ```
 *
 * #### Parameters
 *
 * - `eventName` — The event name to listen to.
 * - `listener` — A {@link FormKitEventListener | FormKitEventListener} to run when the event happens.
 *
 * #### Returns
 *
 * A receipt `string`.
 *
 * @param parent -
 * The parent of a node.
 *
 * #### Signature
 *
 * ```typescript
 * parent: FormKitNode | null
 * ```
 *
 * #### Returns
 *
 * If found a {@link FormKitNode | FormKitNode} or `null`.
 *
 * @param props -
 * An proxied object of props. These are typically provided by the adapter
 * of choice.
 *
 * #### Signature
 *
 * ```typescript
 * props: Partial<FormKitProps>
 * ```
 *
 * #### Returns
 *
 * An optional list of {@link FormKitProps | FormKitProps}.
 *
 * @param remove -
 * Removes a child from the node.
 *
 * #### Signature
 *
 * ```typescript
 * remove: (node: FormKitNode) => FormKitNode
 * ```
 *
 * #### Parameters
 *
 * - `node` — A {@link FormKitNode | FormKitNode} to be removed.
 *
 * #### Returns
 *
 * The {@link FormKitNode | FormKitNode}.
 *
 * @param reset -
 * Resets the node’s value back to its original value.
 *
 * #### Signature
 *
 * ```typescript
 * reset: () => FormKitNode
 * ```
 *
 * #### Returns
 *
 * The {@link FormKitNode | FormKitNode}.
 *
 * @param root -
 * Retrieves the root node of a tree. This is accomplished via tree-traversal
 * on-request, and as such should not be used in frequently called functions.
 *
 * #### Signature
 *
 * ```typescript
 * root: FormKitNode
 * ```
 *
 * #### Returns
 *
 * The {@link FormKitNode | FormKitNode}.
 *
 * @param setErrors -
 * Sets errors on the input, and optionally to child inputs.
 *
 * #### Signature
 *
 * ```typescript
 * setErrors: (localErrors: ErrorMessages, childErrors?: ErrorMessages) => void
 * ```
 *
 * #### Parameters
 *
 * - `localErrors` — A {@link ErrorMessages | ErrorMessages} to be used.
 * - `childErrors` *optional* — A {@link ErrorMessages | ErrorMessages} to be used for children.
 *
 * @param settled -
 * A promise that resolves when a node and its entire subtree is settled.
 * In other words — all the inputs are done committing their values.
 *
 * #### Signature
 *
 * ```typescript
 * settled: Promise<unknown>
 * ```
 *
 * #### Returns
 *
 * A `Promise<unknown>`.
 *
 * @param store -
 * The internal node store.
 *
 * #### Signature
 *
 * ```typescript
 * store: FormKitStore
 * ```
 *
 * #### Returns
 *
 * A {@link FormKitStore | FormKitStore}.
 *
 * @param submit -
 * Triggers a submit event on the nearest form.
 *
 * #### Signature
 *
 * ```typescript
 * submit: () => void
 * ```
 *
 * @param t -
 * A text or translation function that exposes a given string to the "text"
 * hook. All text shown to users should be passed through this function
 * before being displayed — especially for core and plugin authors.
 *
 * #### Signature
 *
 * ```typescript
 * t: (key: string | FormKitTextFragment) => string
 * ```
 *
 * #### Parameters
 *
 * - `key` — A key or a {@link FormKitTextFragment | FormKitTextFragment} to find the translation for.
 *
 * #### Returns
 *
 * The translated `string`.
 *
 * @param type -
 * The type of node, should only be 'input', 'list', or 'group'.
 *
 * #### Signature
 *
 * ```typescript
 * type: FormKitNodeType
 * ```
 *
 * #### Returns
 *
 * A {@link FormKitNodeType | FormKitNodeType}.
 *
 * @param use -
 * Registers a new plugin on the node and its subtree.
 *
 * #### Signature
 *
 * ```typescript
 * use: (
 *  plugin: FormKitPlugin | FormKitPlugin[] | Set<FormKitPlugin>,
 *  run?: boolean,
 *  library?: boolean
 * ) => FormKitNode
 * ```
 *
 * #### Parameters
 *
 * - `plugin` — A {@link FormKitPlugin | FormKitPlugin} or an Array or Set of {@link FormKitPlugin | FormKitPlugin}.
 * - `run` *optional* — Should the plugin be executed on creation.
 * - `library` *optional* — Should the plugin's library function be executed on creation.
 *
 * #### Returns
 *
 * The {@link FormKitNode | FormKitNode}.
 *
 * @param value -
 * The value of the input. This should never be directly modified. Any
 * desired mutations should be made through {@link FormKitNode | input}.
 *
 * #### Signature
 *
 * ```typescript
 * readonly value: unknown
 * ```
 *
 * @param walk -
 * Performs a function on every node in its subtree (but not the node itself).
 * This is an expensive operation so it should be done very rarely and only lifecycle events that are relatively rare like boot up and shut down.
 *
 * #### Signature
 *
 * ```typescript
 * walk: (callback: FormKitChildCallback, stopOnFalse?: boolean, recurseOnFalse?: boolean) => void
 * ```
 *
 * #### Parameters
 *
 * - `callback` — A {@link FormKitChildCallback | FormKitChildCallback} to be executed for each child.
 * - `stopOnFalse` *optional* — If it should stop when the return is false.
 *
 * @public
 */
type FormKitNode<V = unknown> = {
    /**
     * Boolean true indicating this object is a valid FormKitNode
     */
    readonly __FKNode__: true;
    /**
     * The value of the input. This should never be directly modified. Any
     * desired mutations should be made through node.input()
     */
    readonly value: V;
    /**
     * The internal FormKitContext object — this is not a public API and should
     * never be used outside of the core package itself. It is only here for
     * internal use and as an escape hatch.
     */
    _c: FormKitContext;
    /**
     * Add a child to a node, the node must be a group or list.
     */
    add: (node: FormKitNode, index?: number) => FormKitNode;
    /**
     * Adds props to the given node by removing them from node.props.attrs and
     * moving them to the top-level node.props object.
     */
    addProps: (props: FormKitPseudoProps) => FormKitNode;
    /**
     * Gets a node at another address. Addresses are dot-syntax paths (or arrays)
     * of node names. For example: form.users.0.first_name. There are a few
     * "special" traversal tokens as well:
     * - $root - Selects the root node
     * - $parent - Selects the parent node
     * - $self — Selects the current node
     */
    at: (address: FormKitAddress | '$root' | '$parent' | '$self' | (string & {})) => FormKitNode | undefined;
    /**
     * The address of the current node from the root of the tree.
     */
    address: FormKitAddress;
    /**
     * An internal function used to bubble an event from a child to a parent.
     */
    bubble: (event: FormKitEvent) => FormKitNode;
    /**
     * An internal mechanism for calming a disturbance — which is a mechanism
     * used to know the state of input settlement in the tree.
     */
    calm: (childValue?: FormKitChildValue) => FormKitNode;
    /**
     * Clears the errors of the node, and optionally all the children.
     */
    clearErrors: (clearChildren?: boolean, sourceKey?: string) => FormKitNode;
    /**
     * An object that is shared tree-wide with various configuration options that
     * should be applied to the entire tree.
     */
    config: FormKitConfig;
    /**
     * Defines the current input's library type definition — including node type,
     * schema, and props.
     */
    define: (definition: FormKitTypeDefinition<V>) => void;
    /**
     * Increments a disturbance. A disturbance is a record that the input or a
     * member of its subtree is no longer "settled". Disturbed nodes are ones
     * that have had their value modified, but have not yet committed that value
     * to the rest of the tree.
     */
    disturb: () => FormKitNode;
    /**
     * Removes the node from the global registry, its parent, and emits the
     * 'destroying' event.
     */
    destroy: () => void;
    /**
     * Perform given callback on each of the given node's children.
     */
    each: (callback: FormKitChildCallback) => void;
    /**
     * Emit an event from the node.
     */
    emit: (event: string, payload?: any, bubble?: boolean, meta?: Record<string, unknown>) => FormKitNode;
    /**
     * Extend the core node by giving it a key and a trap.
     */
    extend: (key: string, trap: FormKitTrap) => FormKitNode;
    /**
     * Within a given tree, find a node matching a given selector. Selectors
     * can be simple strings or a function.
     */
    find: (selector: string, searcher?: keyof FormKitNode | FormKitSearchFunction) => FormKitNode | undefined;
    /**
     * An internal mechanism to hydrate values down a node tree.
     */
    hydrate: () => FormKitNode;
    /**
     * The index of a node compared to its siblings. This is only applicable in
     * cases where a node is a child of a list.
     */
    index: number;
    /**
     * The function used to set the value of a node. All changes to a node's value
     * should use this function as it ensures the tree's state is always fully
     * tracked.
     */
    input: (value: unknown, async?: boolean) => Promise<unknown>;
    /**
     * The name of the input in the node tree. When a node is a child of a list,
     * this automatically becomes its index.
     */
    name: string;
    /**
     * Adds an event listener for a given event, and returns a "receipt" which is
     * a random string token. This token should be used to remove the listener
     * in the future. Alternatively you can assign a "receipt" property to the
     * listener function and that receipt will be used instead — this allows
     * multiple listeners to all be de-registered with a single off() call if they
     * share the same receipt.
     */
    on: (eventName: string, listener: FormKitEventListener, pos?: 'push' | 'unshift') => string;
    /**
     * Removes an event listener by its token. Receipts can be shared among many
     * event listeners by explicitly declaring the "receipt" property of the
     * listener function.
     */
    off: (receipt: string) => FormKitNode;
    /**
     * Remove a child from a node.
     */
    remove: (node: FormKitNode | FormKitPlaceholderNode) => FormKitNode;
    /**
     * Retrieves the root node of a tree. This is accomplished via tree-traversal
     * on-request, and as such should not be used in frequently called functions.
     */
    root: FormKitNode;
    /**
     * Resets the configuration of a node.
     */
    resetConfig: () => void;
    /**
     * Reset a node’s value back to its original value.
     */
    reset: (value?: unknown) => FormKitNode;
    /**
     * Sets errors on the input, and optionally to child inputs.
     */
    setErrors: (localErrors: ErrorMessages, childErrors?: ErrorMessages) => void;
    /**
     * A promise that resolves when a node and its entire subtree is settled.
     * In other words — all the inputs are done committing their values.
     */
    settled: Promise<unknown>;
    /**
     * Triggers a submit event on the nearest form.
     */
    submit: () => void;
    /**
     * A text or translation function that exposes a given string to the "text"
     * hook. All text shown to users should be passed through this function
     * before being displayed — especially for core and plugin authors.
     */
    t: (key: string | FormKitTextFragment) => string;
    /**
     * Boolean reflecting the settlement state of the node and its subtree.
     */
    isSettled: boolean;
    /**
     * A unique identifier for the node.
     */
    uid: symbol;
    /**
     * Registers a new plugin on the node and its subtree.
     * run = should the plugin be executed or not
     * library = should the plugin's library function be executed (if there)
     */
    use: (plugin: FormKitPlugin | FormKitPlugin[] | Set<FormKitPlugin>, run?: boolean, library?: boolean) => FormKitNode;
    /**
     * Performs a function on every node in the subtree (not itself). This is an
     * expensive operation so it should be done very rarely and only lifecycle
     * events that are relatively rare like boot up and shut down.
     */
    walk: (callback: FormKitChildCallback, stopOnFalse?: boolean, skipSubtreeOnFalse?: boolean) => void;
} & Omit<FormKitContext, 'value' | 'name' | 'config'> & FormKitNodeExtensions;
/**
 * A faux node that is used as a placeholder in the children node array during
 * various node manipulations.
 * @public
 */
interface FormKitPlaceholderNode<V = unknown> {
    /**
     * Flag indicating this is a placeholder.
     */
    __FKP: true;
    /**
     * A unique symbol identifying this placeholder.
     */
    uid: symbol;
    /**
     * The type of placeholder node, if relevant.
     */
    type: FormKitNodeType;
    /**
     * A value at the placeholder location.
     */
    value: V;
    /**
     * The uncommitted value, in a placeholder will always be the same
     * as the value.
     */
    _value: V;
    /**
     * Artificially use a plugin (performs no-op)
     */
    use: (...args: any[]) => void;
    /**
     * Artificial props
     */
    props: Record<string, any>;
    /**
     * A name to use.
     */
    name: string;
    /**
     * Sets the value of the placeholder.
     */
    input: (value: unknown, async?: boolean) => Promise<unknown>;
    /**
     * A placeholder is always settled.
     */
    isSettled: boolean;
}
/**
 * A prop definition for a pseudo prop that defines a type and a default value.
 * @public
 */
type FormKitPseudoProp = {
    boolean?: true;
    default?: boolean;
    setter?: undefined;
    getter?: undefined;
} | {
    boolean?: undefined;
    default?: unknown;
    setter?: (value: unknown, node: FormKitNode) => unknown;
    getter?: (value: unknown, node: FormKitNode) => unknown;
};
/**
 * Pseudo props are "non-runtime" props. Props that are not initially declared
 * as props, and are fetch out of the attrs object (in the context of VueJS).
 * @public
 */
type FormKitPseudoProps = string[] | Record<PropertyKey, FormKitPseudoProp>;
/**
 * Breadth and depth-first searches can use a callback of this notation.
 *
 * @public
 */
type FormKitSearchFunction = (node: FormKitNode, searchTerm?: string | number) => boolean;
/**
 * If a node’s name is set to useIndex, it replaces the node’s name with the
 * index of the node relative to its parent’s children.
 *
 * @internal
 */
declare const useIndex: unique symbol;
/**
 * When propagating values up a tree, this value indicates the child should be
 * removed.
 *
 * @internal
 */
declare const valueRemoved: unique symbol;
/**
 * When propagating values up a tree, this value indicates the child should be
 * moved.
 *
 * @internal
 */
declare const valueMoved: unique symbol;
/**
 * When creating a new node and having its value injected directly at a specific
 * location.
 *
 * @internal
 */
declare const valueInserted: unique symbol;
/**
 * A simple type guard to determine if the context being evaluated is a list
 * type.
 *
 * @param arg - A {@link FormKitContextShape | FormKitContextShape}.
 *
 * @returns Returns a `boolean`.
 *
 * @public
 */
declare function isList(arg: FormKitContextShape): arg is FormKitListContext;
/**
 * Determine if a given object is a node.
 *
 * @example
 *
 * ```javascript
 * import { isNode, createNode } from '@formkit/core'
 *
 * const input = createNode({
 *   type: 'input', // defaults to 'input' if not specified
 *   value: 'hello node world',
 * })
 *
 * const obj = {};
 *
 * isNode(obj)
 * // false
 *
 * isNode(input)
 * // true
 * ```
 *
 * @param node - Any value.
 *
 * @returns Returns a `boolean`.
 *
 * @public
 */
declare function isNode(node: any): node is FormKitNode;
/**
 * Resets the global number of node registrations, useful for deterministic
 * node naming.
 *
 * @public
 */
declare function resetCount(): void;
/**
 * Create a name-based dictionary of all children in an array.
 *
 * @param children - An array of {@link FormKitNode | FormKitNode}.
 *
 * @returns A dictionary of named {@link FormKitNode | FormKitNode}.
 *
 * @public
 */
declare function names(children: FormKitNode[]): {
    [index: string]: FormKitNode;
};
/**
 * Creates the initial value for a node based on the options passed in and the
 * type of the input.
 *
 * @param options - A {@link FormKitOptions | FormKitOptions}.
 *
 * @returns `unknown`
 *
 * @public
 */
declare function createValue(options: FormKitOptions): unknown;
/**
 * Adds a plugin to the node, its children, and executes it.
 *
 * @param node - A {@link FormKitNode | FormKitNode}
 * @param context - A {@link FormKitContext | FormKitContext}
 * @param plugin -
 * {@link FormKitPlugin | FormKitPlugin}
 * {@link FormKitPlugin | FormKitPlugin[]}
 * {@link FormKitPlugin | Set<FormKitPlugin>}
 * @param run - If it will run on creation
 * @param library - If it will run on library creation
 *
 * @returns A {@link FormKitNode | FormKitNode}
 *
 * @internal
 */
declare function use(node: FormKitNode, context: FormKitContext, plugin: FormKitPlugin | FormKitPlugin[] | Set<FormKitPlugin>, run?: boolean, library?: boolean): FormKitNode;
/**
 * Perform a breadth-first search on a node subtree and locate the first
 * instance of a match.
 *
 * @param tree - A {@link FormKitNode | FormKitNode} to start from.
 * @param searchValue - A value to be searched.
 * @param searchGoal - A goal value.
 *
 * @returns A {@link FormKitNode | FormKitNode } or `undefined`.
 *
 * @public
 */
declare function bfs(tree: FormKitNode, searchValue: string | number, searchGoal?: keyof FormKitNode | FormKitSearchFunction): FormKitNode | undefined;
/**
 * Creates a placeholder node that can be used to hold a place in a the children
 * array until the actual node is created.
 * @param options - FormKitOptions
 * @internal
 */
declare function createPlaceholder(options?: FormKitOptions & {
    name?: string;
}): FormKitPlaceholderNode;
/**
 * Determines if a node is a placeholder node.
 * @param node - A {@link FormKitNode | FormKitNode}
 * @returns
 * @public
 */
declare function isPlaceholder(node: FormKitNode | FormKitPlaceholderNode): node is FormKitPlaceholderNode;
/**
 * Creates a new instance of a FormKit Node. Nodes are the atomic unit of a FormKit graph.
 *
 * @example
 *
 * ```javascript
 * import { createNode } from '@formkit/core'
 *
 * const input = createNode({
 *   type: 'input', // defaults to 'input' if not specified
 *   value: 'hello node world',
 * })
 *
 * console.log(input.value)
 * // 'hello node world'
 * ```
 *
 * @param options - An options object of {@link FormKitOptions | FormKitOptions} to override the defaults.
 *
 * @returns A {@link @formkit/core#FormKitNode | FormKitNode}.
 *
 * @public
 */
declare function createNode<V = unknown>(options?: FormKitOptions): FormKitNode<V>;

/**
 * Describes the data passing through the error and warning handlers.
 *
 * @public
 */
interface FormKitHandlerPayload {
    code: number;
    data: any;
    message?: string;
}
/**
 * FormKit's global error handler.
 *
 * @public
 */
declare const errorHandler: FormKitDispatcher<FormKitHandlerPayload>;
/**
 * FormKit's global warning handler.
 *
 * @public
 */
declare const warningHandler: FormKitDispatcher<FormKitHandlerPayload>;
/**
 * Globally emits a warning.
 *
 * @param code - The integer warning code.
 * @param data - Usually an object of information to include.
 *
 * @public
 */
declare function warn(code: number, data?: any): void;
/**
 * Emits an error. Generally should result in an exception.
 *
 * @param code - The integer error code.
 * @param data - Usually an object of information to include.
 *
 * @public
 */
declare function error(code: number, data?: any): never;

/**
 * The compiler output, a function that adds the required tokens.
 *
 * @public
 */
interface FormKitCompilerOutput {
    (tokens?: Record<string, any>): boolean | number | string;
    provide: FormKitCompilerProvider;
}
/**
 * A function that accepts a callback with a token as the only argument, and
 * must return a function that provides the true value of the token.
 *
 * @public
 */
type FormKitCompilerProvider = (callback: (requirements: string[]) => Record<string, () => any>) => FormKitCompilerOutput;
/**
 * Compiles a logical string like `"a != z || b == c"` into a single function.
 * The return value is an object with a "provide" method that iterates over all
 * requirement tokens to use as replacements.
 *
 * @example
 *
 * ```typescript
 * let name = {
 *   value: 'jon'
 * }
 * const condition = compile("$name == 'bob'").provide((token) => {
 *  return () => name.value // must return a function!
 * })
 *
 * condition() // false
 * ```
 *
 * @param expr - A string to compile.
 *
 * @returns A {@link FormKitCompilerOutput | FormKitCompilerOutput}.
 *
 * @public
 */
declare function compile(expr: string): FormKitCompilerOutput;

/**
 * Registers a node to the registry _if_ the node is a root node, _or_ if the
 * node has an explicit node.props.alias. If these two things are not true,
 * then no node is registered (idempotent).
 *
 * @param node - A {@link FormKitNode | FormKitNode}.
 *
 * @public
 */
declare function register(node: FormKitNode): void;
/**
 * Deregister a node from the registry.
 *
 * @param node - A {@link FormKitNode | FormKitNode}.
 *
 * @public
 */
declare function deregister(node: FormKitNode): void;
/**
 * Get a node by a particular id.
 *
 * @param id - Get a node by a given id.
 *
 * @returns A {@link FormKitNode | FormKitNode} or `undefined`.
 *
 * @public
 */
declare function getNode<T = unknown>(id: string): FormKitNode<T> | undefined;
/**
 * Resets the entire registry. Deregisters all nodes and removes all listeners.
 *
 * @public
 */
declare function resetRegistry(): void;
/**
 * A way of watching changes in the global registry.
 *
 * @param id - A dot-syntax id where the node is located.
 * @param callback - A callback in the format of {@link FormKitEventListener | FormKitEventListener} to notify when the node is set or removed.
 *
 * @public
 */
declare function watchRegistry(id: string, callback: FormKitEventListener): string;
/**
 * Stop watching the registry for a given receipt.
 * @param receipt - a receipt to stop watching
 */
declare function stopWatch(receipt: string): void;

/**
 * Sets errors on a form, group, or input.
 *
 * @param id - The id of a form.
 * @param localErrors - The errors to set on the form or the form’s inputs in
 * the format of {@link ErrorMessages | ErrorMessages}.
 * @param childErrors - (optional) The errors to set on the form or the form’s
 * inputs in the format of {@link ErrorMessages | ErrorMessages}.
 *
 * @public
 */
declare function setErrors(id: string, localErrors: ErrorMessages, childErrors?: ErrorMessages): void;
/**
 * Clears errors on the node and optionally its children.
 *
 * @param id - The id of the node you want to clear errors for.
 * @param clearChildren - Determines if the children of this node should have
 * their errors cleared.
 *
 * @public
 */
declare function clearErrors(id: string, clearChildren?: boolean): void;

/**
 * Submits a FormKit form programmatically.
 *
 * @param id - The id of the form.
 *
 * @public
 */
declare function submitForm(id: string, root?: ShadowRoot | Document): void;

/**
 * Resets an input to its "initial" value. If the input is a group or list it
 * resets all the children as well.
 *
 * @param id - The id of an input to reset.
 * @param resetTo - A value to reset the node to.
 *
 * @returns A {@link FormKitNode | FormKitNode} or `undefined`.
 *
 * @public
 */
declare function reset(id: string | FormKitNode, resetTo?: unknown): FormKitNode | undefined;

/**
 * The official FormKit core library. This package is responsible for most of FormKit’s internal functionality.
 * You can read documentation specifically on how it works at formkit.com.
 *
 * You can add this package by using `npm install @formkit/core` or `yarn add @formkit/core`.
 *
 * @packageDocumentation
 */
/**
 * The current version of FormKit at the time the package is published. Is replaced
 * as part of the publishing script.
 *
 * @internal
 */
declare const FORMKIT_VERSION = "__FKV__";

export { type ChildMessageBuffer, type ErrorMessages, FORMKIT_VERSION, type FormKitAddress, type FormKitAttributeValue, type FormKitChildCallback, type FormKitChildValue, type FormKitClasses, type FormKitCompilerOutput, type FormKitCompilerProvider, type FormKitConfig, type FormKitContext, type FormKitContextShape, type FormKitCounter, type FormKitCounterCondition, type FormKitDispatcher, type FormKitEvent, type FormKitEventEmitter, type FormKitEventListener, type FormKitExtendableSchemaRoot, type FormKitFrameworkContext, type FormKitFrameworkContextState, type FormKitGroupValue, type FormKitHandlerPayload, type FormKitHooks, type FormKitInputMessages, type FormKitLedger, type FormKitLibrary, type FormKitListContext, type FormKitListContextValue, type FormKitListStatement, type FormKitListValue, type FormKitMessage, type FormKitMessageMeta, type FormKitMessageProps, type FormKitMessageStore, type FormKitMiddleware, type FormKitNode, type FormKitNodeExtensions, type FormKitNodeType, type FormKitOptions, type FormKitPlaceholderNode, type FormKitPlugin, type FormKitProps, type FormKitPseudoProp, type FormKitPseudoProps, type FormKitRootConfig, type FormKitSchemaAttributes, type FormKitSchemaAttributesCondition, type FormKitSchemaComponent, type FormKitSchemaComposable, type FormKitSchemaCondition, type FormKitSchemaContext, type FormKitSchemaDOMNode, type FormKitSchemaDefinition, type FormKitSchemaFormKit, type FormKitSchemaMeta, type FormKitSchemaNode, type FormKitSchemaProps, type FormKitSchemaTextNode, type FormKitSearchFunction, type FormKitSectionsSchema, type FormKitStore, type FormKitStoreTraps, type FormKitTextFragment, type FormKitTrap, type FormKitTraps, type FormKitTypeDefinition, type KeyedValue, type MessageClearer, type TrapGetter, type TrapSetter, bfs, clearErrors, compile, createClasses, createConfig, createMessage, createNode, createPlaceholder, createValue, deregister, error, errorHandler, generateClassList, getNode, isComponent, isConditional, isDOM, isList, isNode, isPlaceholder, isSugar, names, register, reset, resetCount, resetRegistry, setErrors, stopWatch, submitForm, sugar, use, useIndex, valueInserted, valueMoved, valueRemoved, warn, warningHandler, watchRegistry };
