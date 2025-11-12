import * as _formkit_core from '@formkit/core';
import { FormKitLibrary, FormKitPlugin, FormKitGroupValue, FormKitTypeDefinition, FormKitNode, FormKitFrameworkContext, FormKitMessage, FormKitClasses, FormKitSectionsSchema, FormKitSchemaNode, FormKitSchemaCondition, FormKitExtendableSchemaRoot, FormKitSchemaDOMNode, FormKitSchemaComponent, FormKitSchemaFormKit, FormKitMiddleware, FormKitSchemaDefinition, FormKitSchemaAttributes } from '@formkit/core';

/**
 * Creates a plugin based on a list of {@link @formkit/core#FormKitLibrary | FormKitLibrary}.
 *
 * @param libraries - One or many {@link @formkit/core#FormKitLibrary | FormKitLibrary}.
 *
 * @returns {@link @formkit/core#FormKitPlugin | FormKitPlugin}
 *
 * @public
 */
declare function createLibraryPlugin(...libraries: FormKitLibrary[]): FormKitPlugin;

/**
 * These are props that are used as conditionals in one or more inputs, and as
 * such they need to be defined on all input types. These should all be defined
 * explicitly as "undefined" here, and then defined as their specific type
 * in the FormKitInputProps interface only on the inputs that use them.
 * @public
 */
interface FormKitConditionalProps {
    onValue: undefined;
    offValue: undefined;
    options: undefined;
    number: undefined;
}
/**
 * An attempt to capture all non-undefined values. This is used to define
 * various conditionals where undefined is not a concrete type, but all other
 * values need to take one logical branch.
 *
 * @public
 */
type AllReals = number | string | boolean | CallableFunction | Array<any> | null | Record<any, any>;
/**
 * This is the base interface for providing prop definitions to the FormKit
 * component. It is used to define the props that are available to the each
 * component in the FormKit library by using a discriminated union type. The
 * structure of this interface is:
 *
 * ```ts
 * interface FormKitInputProps {
 *  typeString: { type: 'string'; value?: string } // <-- All unique props
 * }
 * ```
 *
 * All inputs will also inherit all props from FormKitBaseInputProps.
 *
 * Note: It is important that all inputs provide a type and a value prop.
 * @public
 */
interface FormKitInputProps<Props extends FormKitInputs<Props>> {
    button: {
        type: 'button';
        value?: undefined;
    };
    checkbox: {
        type: 'checkbox';
        options?: FormKitOptionsProp;
        onValue?: any;
        offValue?: any;
        value?: Props['options'] extends Record<infer T, string> ? T[] : Props['options'] extends FormKitOptionsItem[] ? Array<Props['options'][number]['value']> : Props['options'] extends Array<infer T> ? T[] : (Props['onValue'] extends AllReals ? Props['onValue'] : true) | (Props['offValue'] extends AllReals ? Props['offValue'] : false);
    };
    color: {
        type: 'color';
        value?: string;
    };
    date: {
        type: 'date';
        value?: string;
    };
    'datetime-local': {
        type: 'datetime-local';
        value?: string;
    };
    email: {
        type: 'email';
        value?: string;
    };
    file: {
        type: 'file';
        value?: FormKitFile[];
    };
    form: {
        type: 'form';
        value?: FormKitGroupValue;
        actions?: boolean | string;
        submitAttrs?: Record<string, any>;
        submitBehavior?: 'disabled' | 'live';
        incompleteMessage?: false | string;
    };
    group: {
        type: 'group';
        value?: FormKitGroupValue;
    };
    hidden: {
        type: 'hidden';
        value?: Props['number'] extends AllReals ? number : string;
        number?: 'integer' | 'float' | 'true' | true;
    };
    list: {
        type: 'list';
        value?: unknown[];
        dynamic?: boolean | 'true' | 'false';
        sync?: boolean | 'true' | 'false';
    };
    meta: {
        type: 'meta';
        value?: any;
    };
    month: {
        type: 'month';
        value?: string;
    };
    number: {
        type: 'number';
        value?: Props['number'] extends AllReals ? number : string;
        number?: 'integer' | 'float' | 'true' | true;
    };
    password: {
        type: 'password';
        value?: string;
    };
    radio: {
        type: 'radio';
        options: FormKitOptionsProp;
        value?: FormKitOptionsValue<Props['options']>;
    };
    range: {
        type: 'range';
        value?: Props['number'] extends AllReals ? number : string;
        number?: 'integer' | 'float' | 'true' | true;
    };
    search: {
        type: 'search';
        value?: Props['number'] extends AllReals ? number | string : string;
        number?: 'integer' | 'float' | 'true' | true;
    };
    select: {
        type: 'select';
        options?: FormKitOptionsPropWithGroups;
        value?: FormKitOptionsValue<Props['options']>;
    };
    submit: {
        type: 'submit';
        value?: string;
    };
    tel: {
        type: 'tel';
        value?: Props['number'] extends AllReals ? number | string : string;
        number?: 'integer' | 'float' | 'true' | true;
    };
    text: {
        type: 'text';
        value?: Props['number'] extends AllReals ? number | string : string;
        number?: 'integer' | 'float' | 'true' | true;
    };
    textarea: {
        type: 'textarea';
        value?: string;
    };
    time: {
        type: 'time';
        value?: string;
    };
    url: {
        type: 'url';
        value?: string;
    };
    week: {
        type: 'week';
        value?: string;
    };
    _: {
        type?: (Props['type'] extends FormKitTypeDefinition<any> ? Props['type'] : never & {}) | (Props['type'] extends keyof FormKitInputProps<Props> ? Props['type'] : never);
        value?: Props['type'] extends FormKitTypeDefinition<infer T> ? T : Props['type'] extends AllReals ? never : string;
    };
}
/**
 * A merger of input props, base props, and conditional props. This is then
 * used as the structure for the FormKitInputs type.
 * @public
 */
type MergedProps<Props extends FormKitInputs<Props>> = {
    [K in keyof FormKitInputProps<Props>]: Omit<Partial<FormKitBaseProps>, keyof FormKitInputProps<Props>[K]> & Omit<Partial<FormKitRuntimeProps<Props>>, keyof FormKitInputProps<Props>[K]> & Omit<Partial<FormKitConditionalProps>, keyof FormKitInputProps<Props>[K]> & Partial<K extends keyof FormKitInputEventsAsProps<Props> ? Omit<FormKitEventsAsProps, keyof FormKitInputEventsAsProps<Props>[K]> & FormKitInputEventsAsProps<Props>[K] : FormKitEventsAsProps> & FormKitInputProps<Props>[K];
};
/**
 * Merge all events into a single type. This is then used as the structure for
 *
 * @public
 */
type MergedEvents<Props extends FormKitInputs<Props>> = InputType<Props> extends keyof FormKitInputEvents<Props> ? FormKitBaseEvents<Props> & FormKitInputEvents<Props>[InputType<Props>] : FormKitBaseEvents<Props>;
/**
 * Selects the "type" from the props if it exists, otherwise it defaults to
 * "text".
 *
 * @public
 */
type InputType<Props extends FormKitInputs<Props>> = Props['type'] extends FormKitTypeDefinition<any> ? Props['type'] : Props['type'] extends string ? Props['type'] : 'text';
/**
 * All FormKit events should be included for a given set of props.
 *
 * @public
 */
type FormKitEvents<Props extends FormKitInputs<Props>> = MergedEvents<Props>;
/**
 * All FormKit inputs should be included for this type.
 * @public
 */
type FormKitInputs<Props extends FormKitInputs<Props>> = MergedProps<Props>[keyof MergedProps<Props>];
/**
 * Unique events emitted by each FormKit input. The shape of this interface is:
 *
 * ```ts
 * interface FormKitInputEvents<Props extends Inputs> {
 *   typeString: { customEvent: (value: PropType<Props, 'value'>) => any } // <-- All unique events
 * }
 * ```
 *
 * All inputs will also inherit all events from FormKitBaseInputEvents.
 * @public
 */
interface FormKitInputEvents<Props extends FormKitInputs<Props>> {
    form: {
        (event: 'submit-raw', e: Event, node: FormKitNode): any;
        (event: 'submit-invalid', node: FormKitNode): any;
        (event: 'submit', data: any, node: FormKitNode): any;
    };
}
/**
 * Extracts the type from a given prop.
 * @public
 */
type PropType<Props extends FormKitInputs<Props>, T extends keyof FormKitInputs<Props>> = Props['type'] extends FormKitTypeDefinition<infer T> ? T extends 'value' ? Props['type'] : T : Extract<FormKitInputs<Props>, {
    type: Props['type'] extends keyof FormKitInputProps<Props> ? Props['type'] : 'text';
}>[T];
/**
 * The proper shape of data to be passed to options prop.
 * @public
 */
type FormKitOptionsValue<Options> = Options extends FormKitOptionsProp ? Options extends Record<infer T, string> ? T : Options extends FormKitOptionsItem[] ? Options[number]['value'] : Options extends Array<infer T> ? T : unknown : unknown;
/**
 * General input events available to all FormKit inputs.
 * @public
 */
interface FormKitBaseEvents<Props extends FormKitInputs<Props>> {
    (event: 'input', value: PropType<Props, 'value'>, node: FormKitNode): any;
    (event: 'inputRaw', value: PropType<Props, 'value'>, node: FormKitNode): any;
    (event: 'input-raw', value: PropType<Props, 'value'>, node: FormKitNode): any;
    (event: 'update:modelValue', value: PropType<Props, 'value'>): any;
    (event: 'update:model-value', value: PropType<Props, 'value'>): any;
    (event: 'node', node: FormKitNode): any;
}
/**
 * In a perfect world this interface would not be required at all. However, Vue
 * expects the interfaces to be defined as method overloads. Unfortunately since
 * our events interface uses generics UnionToIntersection is not able to be used
 * meaning that we lose event data if we store the events as a standard
 * interface with property keys. The only way we have found to reliably get
 * Volar (as of June 2023) to properly recognize all defined events is to use
 * a the "standard" method overload approach (see FormKitBaseEvents).
 *
 * (Basically we cannot use the events in this interface to automatically
 * produce the FormKitBaseEvents without Volar loosing event data)
 *
 * This means we have no way to get the event names out of the interface so we
 * cannot properly use them in our props. This matters for things like TSX
 * support where the event names need to be available as `onEventName` props.
 *
 * This interface is used to manually patch that gap in the type system. These
 * types should match up 1-1 with the events defined in FormKitBaseEvents as
 * well as FormKitInputEvents.
 *
 * @public
 */
interface FormKitEventsAsProps {
    onInput: (value: unknown, node: FormKitNode) => any;
    onInputRaw: (value: unknown, node: FormKitNode) => any;
    'onUpdate:modelValue': (value: unknown, node: FormKitNode) => any;
    onNode: (node: FormKitNode) => any;
}
/**
 * See the comment tome on {@link FormKitEventsAsProps} for why this type is
 * necessary.
 *
 * @public
 */
interface FormKitInputEventsAsProps<Props extends FormKitInputs<Props>> {
    form: {
        onSubmitRaw: (e: Event, node: FormKitNode) => any;
        onSubmitInvalid: (node: FormKitNode) => any;
        onSubmit: (data: any, node: FormKitNode) => any;
    };
}
/**
 * The shape of the context object that is passed to each slot.
 * @public
 */
interface FormKitSlotData<Props extends FormKitInputs<Props>, E extends Record<string, any> = {}> {
    (context: FormKitFrameworkContext<PropType<Props, 'value'>> & E): any;
}
/**
 * Nearly all inputs in FormKit have a "base" set of slots. This is the
 * "sandwich" around the input itself, like the wrappers, help text, error
 * messages etc. Several other input’s slots extend this base interface.
 * @public
 */
interface FormKitBaseSlots<Props extends FormKitInputs<Props>> {
    help: FormKitSlotData<Props>;
    inner: FormKitSlotData<Props>;
    input: FormKitSlotData<Props>;
    label: FormKitSlotData<Props>;
    message: FormKitSlotData<Props, {
        message: FormKitMessage;
    }>;
    messages: FormKitSlotData<Props>;
    outer: FormKitSlotData<Props>;
    prefix: FormKitSlotData<Props>;
    prefixIcon: FormKitSlotData<Props>;
    suffix: FormKitSlotData<Props>;
    suffixIcon: FormKitSlotData<Props>;
    wrapper: FormKitSlotData<Props>;
}
/**
 * The slots available to the FormKitText input, these extend the base slots.
 * @public
 */
interface FormKitTextSlots<Props extends FormKitInputs<Props>> extends FormKitBaseSlots<Props> {
}
/**
 * The data available to slots that have an option in scope.
 * @public
 */
interface OptionSlotData<Props extends FormKitInputs<Props>> {
    option: FormKitOptionsItem<PropType<Props, 'value'>>;
}
/**
 * The slots available to the select input, these extend the base slots.
 * @public
 */
interface FormKitSelectSlots<Props extends FormKitInputs<Props>> extends FormKitBaseSlots<Props> {
    default: FormKitSlotData<Props>;
    option: FormKitSlotData<Props, OptionSlotData<Props>>;
    selectIcon: FormKitSlotData<Props>;
}
/**
 * The slots available to the checkbox inputs even when options are not provided, these extend the base slots.
 * @public
 */
interface FormKitCheckboxSlots<Props extends FormKitInputs<Props>> extends FormKitBaseSlots<Props> {
    decorator: FormKitSlotData<Props, OptionSlotData<Props>>;
    decoratorIcon: FormKitSlotData<Props, OptionSlotData<Props>>;
}
/**
 * The slots available to the radio and checkbox inputs when options are
 * provided.
 * @public
 */
interface FormKitBoxSlots<Props extends FormKitInputs<Props>> {
    fieldset: FormKitSlotData<Props>;
    legend: FormKitSlotData<Props>;
    help: FormKitSlotData<Props>;
    options: FormKitSlotData<Props>;
    option: FormKitSlotData<Props, OptionSlotData<Props>>;
    wrapper: FormKitSlotData<Props, OptionSlotData<Props>>;
    inner: FormKitSlotData<Props, OptionSlotData<Props>>;
    input: FormKitSlotData<Props, OptionSlotData<Props>>;
    label: FormKitSlotData<Props, OptionSlotData<Props>>;
    prefix: FormKitSlotData<Props, OptionSlotData<Props>>;
    suffix: FormKitSlotData<Props, OptionSlotData<Props>>;
    decorator: FormKitSlotData<Props, OptionSlotData<Props>>;
    decoratorIcon: FormKitSlotData<Props, OptionSlotData<Props>>;
    optionHelp: FormKitSlotData<Props, OptionSlotData<Props>>;
    box: FormKitSlotData<Props, OptionSlotData<Props>>;
    icon: FormKitSlotData<Props, OptionSlotData<Props>>;
    message: FormKitSlotData<Props, {
        message: FormKitMessage;
    }>;
    messages: FormKitSlotData<Props>;
}
/**
 * The slots available to the file input, these extend the base slots.
 * @public
 */
interface FormKitFileSlots<Props extends FormKitInputs<Props>> extends FormKitBaseSlots<Props> {
    fileList: FormKitSlotData<Props>;
    fileItem: FormKitSlotData<Props>;
    fileItemIcon: FormKitSlotData<Props, {
        file: FormKitFile;
    }>;
    fileName: FormKitSlotData<Props, {
        file: FormKitFile;
    }>;
    fileRemove: FormKitSlotData<Props, {
        file: FormKitFile;
    }>;
    fileRemoveIcon: FormKitSlotData<Props, {
        file: FormKitFile;
    }>;
    noFiles: FormKitSlotData<Props>;
}
/**
 * The slots available to the button input, these extend the base slots.
 *
 * @public
 */
type FormKitButtonSlots<Props extends FormKitInputs<Props>> = Omit<FormKitBaseSlots<Props>, 'inner'> & {
    default: FormKitSlotData<Props>;
};
/**
 * Slots provided by each FormKit input. The shape of this interface is:
 *
 * ```ts
 * interface FormKitInputSlots<Props extends Inputs> {
 *   typeString: { default: (value: PropType<Props, 'value'>) => any } // <-- All unique slots
 * }
 * ```
 *
 * There is no automatic inheritance of slots — each slot must be explicitly
 * defined for each input.
 * @public
 */
interface FormKitInputSlots<Props extends FormKitInputs<Props>> {
    text: FormKitTextSlots<Props>;
    color: FormKitTextSlots<Props>;
    date: FormKitTextSlots<Props>;
    'datetime-local': FormKitTextSlots<Props>;
    email: FormKitTextSlots<Props>;
    month: FormKitTextSlots<Props>;
    number: FormKitTextSlots<Props>;
    password: FormKitTextSlots<Props>;
    search: FormKitTextSlots<Props>;
    tel: FormKitTextSlots<Props>;
    time: FormKitTextSlots<Props>;
    url: FormKitTextSlots<Props>;
    week: FormKitTextSlots<Props>;
    range: FormKitTextSlots<Props>;
    textarea: FormKitTextSlots<Props>;
    select: FormKitSelectSlots<Props>;
    radio: Props['options'] extends AllReals ? FormKitBoxSlots<Props> : FormKitBaseSlots<Props>;
    list: {
        default: FormKitSlotData<Props>;
    };
    hidden: {
        input: FormKitSlotData<Props>;
    };
    meta: {
        wrapper: FormKitSlotData<Props>;
    };
    group: {
        default: FormKitSlotData<Props>;
    };
    form: {
        form: FormKitSlotData<Props>;
        default: FormKitSlotData<Props>;
        message: FormKitSlotData<Props, {
            message: FormKitMessage;
        }>;
        messages: FormKitSlotData<Props>;
        actions: FormKitSlotData<Props>;
        submit: FormKitSlotData<Props>;
    };
    file: FormKitFileSlots<Props>;
    checkbox: Props['options'] extends AllReals ? FormKitBoxSlots<Props> : FormKitCheckboxSlots<Props>;
    submit: FormKitButtonSlots<Props>;
    button: FormKitButtonSlots<Props>;
}
/**
 * Options should always be formatted as an array of objects with label and value
 * properties.
 *
 * @public
 */
interface FormKitOptionsItem<V = unknown> {
    label: string;
    value: V;
    attrs?: {
        disabled?: boolean;
    } & Record<string, any>;
    __original?: any;
    [index: string]: any;
}
/**
 * Option groups should always be formatted as an array of objects with group and nested options
 *
 * @public
 */
interface FormKitOptionsGroupItemProp {
    group: string;
    options: FormKitOptionsProp;
    attrs?: Record<string, any>;
}
/**
 * Option groups should always be formatted as an array of objects with group and nested options
 *
 * @public
 */
interface FormKitOptionsGroupItem {
    group: string;
    options: FormKitOptionsList;
    attrs?: Record<string, any>;
}
/**
 * An array of option items.
 *
 * @public
 */
type FormKitOptionsList = FormKitOptionsItem[];
/**
 * An array of option items with a group.
 *
 * @public
 */
type FormKitOptionsListWithGroups = Array<FormKitOptionsItem | FormKitOptionsGroupItem>;
/**
 * An array of option items with a group support — where the `option` of the
 * groups can be any valid FormKitOptionsProp type.
 *
 * @public
 */
type FormKitOptionsListWithGroupsProp = Array<FormKitOptionsItem | FormKitOptionsGroupItemProp>;
/**
 * Allows for prop extensions to be defined by using an interface whose keys
 * are ignored, but values are applied to a union type. This allows for any
 * third party code to extend the options prop by using module augmentation
 * to add new values to the union type.
 *
 * @public
 */
interface FormKitOptionsPropExtensions {
    arrayOfStrings: string[];
    arrayOfNumbers: number[];
    optionsList: FormKitOptionsList;
    valueLabelPojo: Record<string | number, string>;
}
/**
 * The types of options that can be passed to the options prop.
 *
 * @public
 */
type FormKitOptionsProp = FormKitOptionsPropExtensions[keyof FormKitOptionsPropExtensions];
/**
 * The types of options that can be passed to the options prop.
 *
 * @public
 */
type FormKitOptionsPropWithGroups = FormKitOptionsProp | FormKitOptionsListWithGroupsProp;
/**
 * Typings for all the built in runtime props.
 *
 * Warning: As of writing these are only specific to Vue’s runtime prop
 * requirements and should not be used as any kind of external API as they are
 * subject to change.
 *
 * @public
 */
interface FormKitRuntimeProps<Props extends FormKitInputs<Props>, V = unknown> {
    /**
     * An object of configuration data for the input and its children.
     */
    config: Record<string, any>;
    /**
     * An object of classes to be applied to the input.
     */
    classes: Record<string, string | Record<string, boolean> | FormKitClasses>;
    /**
     * Amount of time to debounce input before committing.
     */
    delay: number;
    /**
     * An array of errors for the input.
     */
    errors: string[];
    /**
     * A object of values
     */
    inputErrors: Record<string, string[]>;
    /**
     * An explicit index to mount a child of a list at.
     */
    index: number;
    /**
     * A globally unique identifier for the input — this passes through to the
     * id attribute.
     */
    id: string;
    /**
     * The dynamic value of the input.
     */
    modelValue: PropType<Props, 'value'>;
    /**
     * The name of the input.
     */
    name: string;
    /**
     * An explicit parent node for the input.
     */
    parent: FormKitNode;
    /**
     * An array of plugins to apply to the input.
     */
    plugins: FormKitPlugin[];
    /**
     * An object of sections to merge with the input’s internal schema.
     */
    sectionsSchema: FormKitSectionsSchema;
    /**
     * A boolean indicating whether the input should be synced with the model.
     */
    sync: boolean | undefined;
    /**
     * The type of the input.
     */
    type: string | FormKitTypeDefinition<V>;
    /**
     * A validation string or array of validation rules.
     */
    validation: string | Array<[rule: string, ...args: any]>;
    /**
     * An object of validation messages to use for the input.
     */
    validationMessages: Record<string, string | ((ctx: {
        node: FormKitNode;
        name: string;
        args: any[];
    }) => string)>;
    /**
     * An object of additional validation rules to use for the input.
     */
    validationRules: Record<string, (node: FormKitNode, ...args: any[]) => boolean | Promise<boolean>>;
    /**
     * Use this to override the default validation label in validation messages.
     */
    validationLabel: string | ((node: FormKitNode) => string);
}
/**
 * Base props that should be applied to all FormKit inputs. These are not actual
 * runtime props and are pulled from the context.attrs object. Many of these are
 * just html attributes that are passed through to the input element.
 *
 * @public
 */
interface FormKitBaseProps {
    /**
     * HTML Attribute, read more here: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input#accept
     */
    accept: string;
    action: string;
    actions: 'true' | 'false' | boolean;
    dirtyBehavior: 'touched' | 'compare';
    disabled: 'true' | 'false' | boolean;
    enctype: string;
    help: string;
    ignore: 'true' | 'false' | boolean;
    label: string;
    library: Record<string, any>;
    max: string | number;
    method: string;
    min: string | number;
    multiple: 'true' | 'false' | boolean;
    preserve: 'true' | 'false' | boolean;
    preserveErrors: 'true' | 'false' | boolean;
    placeholder: string;
    step: string | number;
    validationVisibility: 'live' | 'blur' | 'dirty' | 'submit';
}
/**
 * All the explicit FormKit props that need to be passed to FormKit’s Vue
 * component instance.
 * @public
 */
declare const runtimeProps: string[];
/**
 * A helper to determine if an option is a group or an option.
 * @param option - An option
 *
 * @public
 */
declare function isGroupOption(option: FormKitOptionsItem | FormKitOptionsGroupItem | FormKitOptionsGroupItemProp): option is FormKitOptionsGroupItem;

/**
 * A function to normalize an array of objects, array of strings, or object of
 * key-values to use an array of objects with value and label properties.
 *
 * @param options - An un-normalized {@link FormKitOptionsProp | FormKitOptionsProp}.
 *
 * @returns A list of {@link FormKitOptionsList | FormKitOptionsList}.
 *
 * @public
 */
declare function normalizeOptions<T extends FormKitOptionsPropWithGroups>(options: T, i?: {
    count: number;
}): T extends FormKitOptionsProp ? FormKitOptionsList : FormKitOptionsListWithGroups;
/**
 * A feature that converts the options prop to usable values, to be used by a
 * feature or a plugin.
 *
 * @param node - A {@link @formkit/core#FormKitNode | FormKitNode}.
 *
 * @public
 */
declare function options(node: FormKitNode): void;

/**
 * A function that is called with an extensions argument and returns a valid
 * schema node.
 *
 * @public
 */
interface FormKitSchemaExtendableSection {
    (extensions: FormKitSectionsSchema): FormKitSchemaNode;
    _s?: string;
}
/**
 * A function that when called, returns a function that can in turn be called
 * with an extension parameter.
 *
 * @public
 */
interface FormKitSection<T = FormKitSchemaExtendableSection> {
    (...children: Array<FormKitSchemaExtendableSection | string | FormKitSchemaCondition>): T;
}
/**
 * Creates a new reusable section.
 *
 * @param section - A single section of schema
 * @param el - The element or a function that returns a schema node.
 * @param root - When true, returns a FormKitExtendableSchemaRoot. When false,
 * returns a FormKitSchemaExtendableSection.
 *
 * @returns Returns a {@link @formkit/core#FormKitExtendableSchemaRoot
 * | FormKitExtendableSchemaRoot} or a {@link
 * @formkit/core#FormKitSchemaExtendableSection | FormKitSchemaExtendableSection}.
 *
 * @public
 */
declare function createSection(section: string, el: string | null | (() => FormKitSchemaNode), fragment: true): FormKitSection<FormKitExtendableSchemaRoot>;
/**
 * @param section - A single section of schema
 * @param el - The element or a function that returns a schema node.
 *
 * @public
 */
declare function createSection(section: string, el: string | null | (() => FormKitSchemaNode)): FormKitSection<FormKitSchemaExtendableSection>;
/**
 * @param section - A single section of schema
 * @param el - The element or a function that returns a schema node.
 * @param root - When false, returns a FormKitSchemaExtendableSection.
 *
 * @public
 */
declare function createSection(section: string, el: string | (() => FormKitSchemaNode), fragment: false): FormKitSection<FormKitSchemaExtendableSection>;
/**
 * Type guard for schema objects.
 *
 * @param schema - returns `true` if the node is a schema node but not a string
 * or conditional.
 *
 * @returns `boolean`
 *
 * @public
 */
declare function isSchemaObject(schema: Partial<FormKitSchemaNode> | null): schema is FormKitSchemaDOMNode | FormKitSchemaComponent | FormKitSchemaFormKit;
/**
 * Extends a single schema node with an extension. The extension can be any
 * partial node including strings.
 *
 * @param schema - The base schema node.
 * @param extension - The values to extend on the base schema node.
 *
 * @returns {@link @formkit/core#FormKitSchemaNode | FormKitSchemaNode}
 *
 * @public
 */
declare function extendSchema(schema: FormKitSchemaNode, extension?: Partial<FormKitSchemaNode> | null): FormKitSchemaNode;

/**
 * A feature that adds checkbox selection support.
 *
 * @param node - A {@link @formkit/core#FormKitNode | FormKitNode}.
 *
 * @public
 */
declare function checkboxes(node: FormKitNode): void;

/**
 * Adds icon props definition.
 *
 * @param sectionKey - the location the icon should be loaded.
 * @param defaultIcon - the icon that should be loaded if a match is found in the user's CSS.
 *
 * @returns A {@link @formkit/core#FormKitPlugin | FormKitPlugin}.
 *
 * @public
 */
declare function defaultIcon(sectionKey: string, defaultIcon: string): (node: FormKitNode) => void;

/**
 * A feature that allows disabling children of this node.
 *
 * @param node - A {@link @formkit/core#FormKitNode | FormKitNode}.
 *
 * @public
 */
declare function disables(node: FormKitNode): void;

declare global {
    interface Window {
        _FormKit_File_Drop: boolean;
    }
}
/**
 * A feature to add file handling support to an input.
 *
 * @param node - A {@link @formkit/core#FormKitNode | FormKitNode}.
 *
 * @public
 */
declare function files(node: FormKitNode): void;

/**
 * A feature to add a submit handler and actions section.
 *
 * @param node - A {@link @formkit/core#FormKitNode | FormKitNode}.
 *
 * @public
 */
declare function form$1(node: FormKitNode): void;

/**
 * A feature that applies `ignore="true"` by default.
 *
 * @param node - A {@link @formkit/core#FormKitNode | FormKitNode}.
 *
 * @public
 */
declare function ignore(node: FormKitNode): void;

/**
 * A feature that ensures the input has an `initialValue` prop.
 *
 * @param node - A {@link @formkit/core#FormKitNode | FormKitNode}.
 *
 * @public
 */
declare function initialValue(node: FormKitNode): void;

/**
 * Creates a new feature that generates a localization message of type ui
 * for use on a given component.
 *
 * @param key - The key of the message.
 * @param value - The value of the message.
 *
 * @returns A {@link @formkit/core#FormKitPlugin | FormKitPlugin}.
 *
 * @public
 */
declare function localize(key: string, value?: string): (node: FormKitNode) => void;

/**
 * A feature that normalizes box types (checkboxes, radios).
 *
 * @param node - A {@link @formkit/core#FormKitNode | FormKitNode}.
 *
 * @returns A {@link @formkit/node#FormKitMiddleware | FormKitMiddleware}.
 *
 * @public
 */
declare function normalizeBoxes(node: FormKitNode): FormKitMiddleware<{
    prop: string | symbol;
    value: any;
}>;

/**
 * A feature that allows casting to numbers.
 *
 * @param node - A {@link @formkit/core#FormKitNode | FormKitNode}.
 *
 * @public
 */
declare function casts(node: FormKitNode): void;

/**
 * A feature to check if the value being checked is the current value.
 *
 * @param node - A {@link @formkit/core#FormKitNode | FormKitNode}.
 *
 * @public
 */
declare function radios(node: FormKitNode): void;

declare function resetRadio(): void;
/**
 * Automatically rename any radio inputs.
 * @param node - A formkit node.
 * @returns
 *
 * @public
 */
declare function renamesRadios(node: FormKitNode): void;

/**
 * Converts the options prop to usable values.
 * @param node - A formkit node.
 * @public
 */
declare function select$1(node: FormKitNode): void;

/**
 * Actions section that shows the action buttons
 *
 * @public
 */
declare const actions: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Box section used for grouping options
 *
 * @public
 */
declare const box: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Option help section
 *
 * @public
 */
declare const boxHelp: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Box Inner section
 *
 * @public
 */
declare const boxInner: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Label section for options
 *
 * @public
 */
declare const boxLabel: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Option section used to show an option
 *
 * @public
 */
declare const boxOption: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Options section used to wrap all option sections in a list
 *
 * @public
 */
declare const boxOptions: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Wrapper section for options
 *
 * @public
 */
declare const boxWrapper: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Input section for a button
 *
 * @public
 */
declare const buttonInput: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Default section for a button
 *
 * @public
 */
declare const buttonLabel: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Decorator section
 *
 * @public
 */
declare const decorator: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Fieldset section, used to describe help
 *
 * @public
 */
declare const fieldset: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Input section for a file input
 *
 * @public
 */
declare const fileInput: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * File item section for showing a file name
 *
 * @public
 */
declare const fileItem: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * File list section to show all file names
 *
 * @public
 */
declare const fileList: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * File name section to show the file name
 *
 * @public
 */
declare const fileName: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * File remove section to show a remove button for files
 *
 * @public
 */
declare const fileRemove: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Form section
 *
 * @public
 */
declare const formInput: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * A simple fragment section
 *
 * @public
 */
declare const fragment: FormKitSection<_formkit_core.FormKitExtendableSchemaRoot>;

/**
 * Help section that shows help text
 *
 * @public
 */
declare const help: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Icon section used by all icons
 *
 * @public
 */
declare const icon: (sectionKey: string, el?: string) => FormKitSchemaExtendableSection;

/**
 * Inner section
 *
 * @public
 */
declare const inner: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Label section with label element
 *
 * @public
 */
declare const label: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Legend section, used instead of label when its grouping fields.
 *
 * @public
 */
declare const legend: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Message section, shows a group of messages.
 *
 * @public
 */
declare const message: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Messages section where all messages will be displayed.
 *
 * @public
 */
declare const messages: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * No file section that shows when there is no files
 *
 * @public
 */
declare const noFiles: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Option section used to show options
 *
 * @public
 */
declare const optGroup: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Option section used to show options
 *
 * @public
 */
declare const option: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Options slot section that displays options when used with slots
 *
 * @public
 */
declare const optionSlot: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Outer section where most data attributes are assigned.
 *
 * @public
 */
declare const outer: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Prefix section
 *
 * @public
 */
declare const prefix: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Input section used by selects
 *
 * @public
 */
declare const selectInput: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Submit section that displays a submit button from a form
 *
 * @public
 */
declare const submitInput: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Suffix section
 *
 * @public
 */
declare const suffix: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Input section
 *
 * @public
 */
declare const textInput: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Input section used by textarea inputs
 *
 * @public
 */
declare const textareaInput: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Wrapper input section
 *
 * @public
 */
declare const wrapper: FormKitSection<FormKitSchemaExtendableSection>;

/**
 * Either a schema node, or a function that returns a schema node.
 *
 * @public
 */
type FormKitInputSchema = ((children?: FormKitSchemaDefinition) => FormKitSchemaNode) | FormKitSchemaNode;
/**
 * A type narrowed type that represents a formkit schema "section". These are
 * always in the shape:
 * ```js
 * {
 *   if: string,
 *   then: '$slots.sectionName',
 *   else: {
 *    meta: {
 *      section: 'sectionName'
 *    },
 *    $el: 'div' // or $cmp...
 *   }
 * }
 * ```
 *
 * @public
 */
type FormKitSchemaSection = FormKitSchemaCondition & {
    else: FormKitSchemaDOMNode | (FormKitSchemaComponent & {
        meta: {
            section: string;
        };
    });
};
/**
 * Checks if the current schema node is a slot condition.
 *
 * @example
 *
 * ```js
 * {
 *  if: '$slot.name',
 *  then: '$slot.name',
 *  else: []
 * } // this schema node would return true.
 * ```
 *
 * @param node - A {@link @formkit/core#FormKitSchemaNode | FormKitSchemaNode}.
 *
 * @returns `boolean`
 *
 * @public
 */
declare function isSlotCondition(node: FormKitSchemaNode): node is {
    if: string;
    then: string;
    else: FormKitSchemaNode | FormKitSchemaNode[];
};
/**
 * Finds a section by name in a schema.
 *
 * @param schema - A {@link @formkit/core#FormKitSchemaDefinition | FormKitSchemaDefinition} array.
 * @param target - The name of the section to find.
 *
 * @returns a tuple of the schema and the section or a tuple of `false` and `false` if not found.
 *
 * @public
 */
declare function findSection(schema: FormKitSchemaDefinition, target: string): [false, false] | [
    FormKitSchemaNode[] | FormKitSchemaCondition | false | undefined,
    FormKitSchemaCondition
];
/**
 * Runs a callback over every section in a schema. if stopOnCallbackReturn is true
 * and the callback returns a value, the iteration will stop and return that value.
 *
 * @param schema - A {@link @formkit/core#FormKitSchemaNode | FormKitSchemaNode} array.
 * @param callback - A callback to run on every section.
 * @param stopOnCallbackReturn - If true, the loop will stop if the callback returns a value.
 * @param schemaParent - The parent of the current schema node.
 *
 * @returns
 *
 * @public
 */
declare function eachSection<T>(schema: FormKitSchemaDefinition, callback: (section: FormKitSchemaComponent | FormKitSchemaDOMNode, sectionConditional: FormKitSchemaCondition, sectionParent: FormKitSchemaNode[] | FormKitSchemaCondition | undefined) => T, stopOnCallbackReturn?: boolean, schemaParent?: FormKitSchemaNode[] | FormKitSchemaCondition): T | void;
/**
 * Creates an input schema with all of the wrapping base schema.
 *
 * @param inputSection - Content to store in the input section key location.
 *
 * @returns {@link @formkit/core#FormKitExtendableSchemaRoot | FormKitExtendableSchemaRoot}
 *
 * @public
 */
declare function useSchema(inputSection: FormKitSection, sectionsSchema?: FormKitSectionsSchema): FormKitSchemaExtendableSection;
/**
 * Applies attributes to a given schema section by applying a higher order
 * function that merges a given set of attributes into the node.
 *
 * @param attrs - Attributes to apply to a {@link FormKitSchemaExtendableSection
 * | FormKitSchemaExtendableSection}.
 * @param section - A section to apply attributes to.
 *
 * @returns {@link FormKitSchemaExtendableSection | FormKitSchemaExtendableSection}
 *
 * @public
 */
declare function $attrs(attrs: FormKitSchemaAttributes | (() => FormKitSchemaAttributes), section: FormKitSchemaExtendableSection): FormKitSchemaExtendableSection;
/**
 * Applies a condition to a given schema section.
 *
 * @param condition - A schema condition to apply to a section.
 * @param then - The section that applies if the condition is true.
 * @param otherwise - (else) The section that applies if the condition is false.
 *
 * @returns {@link FormKitSchemaExtendableSection | FormKitSchemaExtendableSection}
 *
 * @public
 */
declare function $if(condition: string, then: FormKitSchemaExtendableSection, otherwise?: FormKitSchemaExtendableSection): FormKitSchemaExtendableSection;
/**
 * Applies a condition to a given schema section.
 *
 * @param varName - The name of the variable that holds the current instance.
 * @param inName - The variable we are iterating over.
 * @param section - A section to repeat.
 *
 * @returns {@link FormKitSchemaExtendableSection | FormKitSchemaExtendableSection}
 *
 * @public
 */
declare function $for(varName: string, inName: string, section: FormKitSchemaExtendableSection): (extensions: FormKitSectionsSchema) => FormKitSchemaNode;
/**
 * Extends a schema node with a given set of extensions.
 *
 * @param section - A section to apply an extension to.
 * @param extendWith - A partial schema snippet to apply to the section.
 *
 * @returns {@link FormKitSchemaExtendableSection | FormKitSchemaExtendableSection}
 *
 * @public
 */
declare function $extend(section: FormKitSchemaExtendableSection, extendWith: Partial<FormKitSchemaNode>): FormKitSchemaExtendableSection;
/**
 * Creates a root schema section.
 *
 * @param section - A section to make a root from.
 *
 * @returns {@link FormKitSchemaExtendableSection | FormKitSchemaExtendableSection}
 *
 * @public
 */
declare function $root(section: FormKitSchemaExtendableSection): FormKitExtendableSchemaRoot;
declare function resetCounts(): void;

/**
 * Input definition for a button.
 * @public
 */
declare const button: FormKitTypeDefinition;

/**
 * Input definition for a checkbox(ess).
 * @public
 */
declare const checkbox: FormKitTypeDefinition;

/**
 * Input definition for a file input.
 * @public
 */
declare const file: FormKitTypeDefinition;

/**
 * Input definition for a form.
 * @public
 */
declare const form: FormKitTypeDefinition;

/**
 * Input definition for a group.
 * @public
 */
declare const group: FormKitTypeDefinition;

/**
 * Input definition for a hidden input.
 * @public
 */
declare const hidden: FormKitTypeDefinition;

/**
 * Input definition for a list.
 * @public
 */
declare const list: FormKitTypeDefinition;

/**
 * Input definition for a meta input.
 * @public
 */
declare const meta: FormKitTypeDefinition;

/**
 * Input definition for a radio.
 * @public
 */
declare const radio: FormKitTypeDefinition;

/**
 * Input definition for a select.
 * @public
 */
declare const select: FormKitTypeDefinition;

/**
 * Input definition for a textarea.
 * @public
 */
declare const textarea: FormKitTypeDefinition;

/**
 * Input definition for a text.
 * @public
 */
declare const text: FormKitTypeDefinition;

/**
 * A single file object in FormKit’s synthetic "FileList".
 *
 * @public
 */
interface FormKitFile {
    name: string;
    file?: File;
}
/**
 * A synthetic array-based "FileList".
 *
 * @public
 */
type FormKitFileValue = FormKitFile[];

declare const inputs: {
    button: _formkit_core.FormKitTypeDefinition;
    submit: _formkit_core.FormKitTypeDefinition;
    checkbox: _formkit_core.FormKitTypeDefinition;
    file: _formkit_core.FormKitTypeDefinition;
    form: _formkit_core.FormKitTypeDefinition;
    group: _formkit_core.FormKitTypeDefinition;
    hidden: _formkit_core.FormKitTypeDefinition;
    list: _formkit_core.FormKitTypeDefinition;
    meta: _formkit_core.FormKitTypeDefinition;
    radio: _formkit_core.FormKitTypeDefinition;
    select: _formkit_core.FormKitTypeDefinition;
    textarea: _formkit_core.FormKitTypeDefinition;
    text: _formkit_core.FormKitTypeDefinition;
    color: _formkit_core.FormKitTypeDefinition;
    date: _formkit_core.FormKitTypeDefinition;
    datetimeLocal: _formkit_core.FormKitTypeDefinition;
    email: _formkit_core.FormKitTypeDefinition;
    month: _formkit_core.FormKitTypeDefinition;
    number: _formkit_core.FormKitTypeDefinition;
    password: _formkit_core.FormKitTypeDefinition;
    search: _formkit_core.FormKitTypeDefinition;
    tel: _formkit_core.FormKitTypeDefinition;
    time: _formkit_core.FormKitTypeDefinition;
    url: _formkit_core.FormKitTypeDefinition;
    week: _formkit_core.FormKitTypeDefinition;
    range: _formkit_core.FormKitTypeDefinition;
};

export { $attrs, $extend, $for, $if, $root, type AllReals, type FormKitBaseEvents, type FormKitBaseProps, type FormKitBaseSlots, type FormKitBoxSlots, type FormKitButtonSlots, type FormKitCheckboxSlots, type FormKitConditionalProps, type FormKitEvents, type FormKitEventsAsProps, type FormKitFile, type FormKitFileSlots, type FormKitFileValue, type FormKitInputEvents, type FormKitInputEventsAsProps, type FormKitInputProps, type FormKitInputSchema, type FormKitInputSlots, type FormKitInputs, type FormKitOptionsGroupItem, type FormKitOptionsGroupItemProp, type FormKitOptionsItem, type FormKitOptionsList, type FormKitOptionsListWithGroups, type FormKitOptionsListWithGroupsProp, type FormKitOptionsProp, type FormKitOptionsPropExtensions, type FormKitOptionsPropWithGroups, type FormKitOptionsValue, type FormKitRuntimeProps, type FormKitSchemaExtendableSection, type FormKitSchemaSection, type FormKitSection, type FormKitSelectSlots, type FormKitSlotData, type FormKitTextSlots, type InputType, type MergedEvents, type MergedProps, type OptionSlotData, type PropType, actions, box, boxHelp, boxInner, boxLabel, boxOption, boxOptions, boxWrapper, button, buttonInput, buttonLabel, casts, checkbox, checkboxes, text as color, createLibraryPlugin, createSection, text as date, text as datetimeLocal, decorator, defaultIcon, disables as disablesChildren, eachSection, text as email, extendSchema, fieldset, file, fileInput, fileItem, fileList, fileName, fileRemove, files, findSection, form, formInput, form$1 as forms, fragment, group, help, hidden, icon, ignore as ignores, initialValue, inner, inputs, isGroupOption, isSchemaObject, isSlotCondition, label, legend, list, localize, message, messages, meta, text as month, noFiles, normalizeBoxes, normalizeOptions, text as number, optGroup, option, optionSlot, options, outer, text as password, prefix, radio, radios, text as range, renamesRadios, resetCounts, resetRadio, runtimeProps, text as search, select, selectInput, select$1 as selects, button as submit, submitInput, suffix, text as tel, text, textInput, textarea, textareaInput, text as time, text as url, useSchema, text as week, wrapper };
