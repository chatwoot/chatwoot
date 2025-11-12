import { FormKitOptions, FormKitNode, FormKitSchemaNode, FormKitTypeDefinition, FormKitSectionsSchema, FormKitSchemaDefinition, FormKitRootConfig, FormKitSchemaCondition, FormKitGroupValue, FormKitFrameworkContext, FormKitLibrary, FormKitPlugin } from '@formkit/core';
export { clearErrors, errorHandler, reset, setErrors, submitForm } from '@formkit/core';
import * as vue from 'vue';
import { SetupContext, Component, VNodeProps, AllowedComponentProps, ComponentCustomProps, VNode, RendererNode, RendererElement, InjectionKey, PropType, Plugin, Ref, App } from 'vue';
import { FormKitInputs, FormKitSection, InputType, FormKitInputSlots, FormKitEvents } from '@formkit/inputs';
import { FormKitValidationRule } from '@formkit/validation';
import { FormKitLocaleRegistry, FormKitLocale } from '@formkit/i18n';
export { changeLocale } from '@formkit/i18n';
import { FormKitIconLoaderUrl, FormKitIconLoader } from '@formkit/themes';

/**
 * A composable for creating a new FormKit node.
 *
 * @param type - The type of node (input, group, list)
 * @param attrs - The FormKit "props" — which is really the attrs list.
 *
 * @returns {@link @formkit/core#FormKitNode | FormKitNode}
 *
 * @public
 */
declare function useInput<Props extends FormKitInputs<Props>, Context extends SetupContext<any, any>>(props: Props, context: Context, options?: FormKitOptions): FormKitNode;

/**
 * Creates a new input from schema or a Vue component with the "standard"
 * FormKit features in place such as labels, help text, validation messages, and
 * class support.
 *
 * @param schemaOrComponent - The actual schema of the input or the component.
 * @param definitionOptions - Any options in the FormKitTypeDefinition you want
 * to define.
 *
 * @returns {@link @formkit/core#FormKitTypeDefinition | FormKitTypeDefinition}
 *
 * @public
 */
declare function createInput<V = unknown>(schemaOrComponent: FormKitSchemaNode | FormKitSection | Component, definitionOptions?: Partial<FormKitTypeDefinition<V>>, sectionsSchema?: FormKitSectionsSchema): FormKitTypeDefinition<V>;

declare function defineFormKitConfig(config: DefaultConfigOptions | (() => DefaultConfigOptions)): () => DefaultConfigOptions;

/**
 * The type definition for the FormKit’s slots, this is not intended to be used
 * directly.
 * @public
 */
type Slots<Props extends FormKitInputs<Props>> = InputType<Props> extends keyof FormKitInputSlots<Props> ? FormKitInputSlots<Props>[InputType<Props>] : {};
/**
 * The TypeScript definition for the FormKit component.
 * @public
 */
type FormKitComponent = <Props extends FormKitInputs<Props>>(props: Props & VNodeProps & AllowedComponentProps & ComponentCustomProps, context?: Pick<FormKitSetupContext<Props>, 'attrs' | 'emit' | 'slots'>, setup?: FormKitSetupContext<Props>) => VNode<RendererNode, RendererElement, {
    [key: string]: any;
}> & {
    __ctx?: FormKitSetupContext<Props>;
};
/**
 * Type definition for the FormKit component Vue context.
 * @public
 */
interface FormKitSetupContext<Props extends FormKitInputs<Props>> {
    props: {} & Props;
    expose(exposed: {}): void;
    attrs: any;
    slots: Slots<Props>;
    emit: FormKitEvents<Props>;
}
/**
 * The symbol that represents the formkit parent injection value.
 *
 * @public
 */
declare const parentSymbol: InjectionKey<FormKitNode>;
/**
 * The symbol that represents the formkit component callback injection value.
 * This is used by tooling to know which component "owns" this node — some
 * effects are linked to that component, for example, hot module reloading.
 *
 * @internal
 */
declare const componentSymbol: InjectionKey<(node: FormKitNode) => void>;
/**
 * Returns the node that is currently having its schema created.
 *
 * @public
 */
declare const getCurrentSchemaNode: () => FormKitNode | null;
/**
 * The root FormKit component. Use it to craft all inputs and structure of your
 * forms. For example:
 *
 * ```vue
 * <FormKit
 *  type="text"
 *  label="Name"
 *  help="Please enter your name"
 *  validation="required|length:2"
 * />
 * ```
 *
 * @public
 */
declare const formkitComponent: FormKitComponent;

/**
 * A library of components available to the schema (in addition to globally
 * registered ones)
 *
 * @public
 */
interface FormKitComponentLibrary {
    [index: string]: Component;
}
/**
 * The actual signature of a VNode in Vue.
 *
 * @public
 */
type VirtualNode = VNode<RendererNode, RendererElement, {
    [key: string]: any;
}>;
/**
 * The types of values that can be rendered by Vue.
 *
 * @public
 */
type Renderable = null | string | number | boolean | VirtualNode;
/**
 * A list of renderable items.
 *
 * @public
 */
type RenderableList = Renderable | Renderable[] | (Renderable | Renderable[])[];
/**
 * An object of slots
 *
 * @public
 */
type RenderableSlots = Record<string, RenderableSlot>;
/**
 * A slot function that can be rendered.
 *
 * @public
 */
type RenderableSlot = (data?: Record<string, any>, key?: object) => RenderableList;
/**
 * The FormKitSchema vue component:
 *
 * @public
 */
declare const FormKitSchema: vue.DefineComponent<{
    schema: {
        type: PropType<FormKitSchemaDefinition>;
        required: true;
    };
    data: {
        type: PropType<Record<string, any>>;
        default: () => {};
    };
    library: {
        type: PropType<FormKitComponentLibrary>;
        default: () => {};
    };
    memoKey: {
        type: StringConstructor;
        required: false;
    };
}, () => string | number | boolean | VirtualNode | (Renderable | Renderable[])[] | RenderableSlots | null, unknown, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, "mounted"[], "mounted", vue.PublicProps, Readonly<vue.ExtractPropTypes<{
    schema: {
        type: PropType<FormKitSchemaDefinition>;
        required: true;
    };
    data: {
        type: PropType<Record<string, any>>;
        default: () => {};
    };
    library: {
        type: PropType<FormKitComponentLibrary>;
        default: () => {};
    };
    memoKey: {
        type: StringConstructor;
        required: false;
    };
}>> & {
    onMounted?: ((...args: any[]) => any) | undefined;
}, {
    data: Record<string, any>;
    library: FormKitComponentLibrary;
}, {}>;

declare module 'vue' {
    interface ComponentCustomProperties {
        $formkit: FormKitVuePlugin;
    }
    interface GlobalComponents {
        FormKit: FormKitComponent;
        FormKitSchema: typeof FormKitSchema;
    }
}
/**
 * The global instance of the FormKit plugin.
 *
 * @public
 */
interface FormKitVuePlugin {
    get: (id: string) => FormKitNode | undefined;
    setLocale: (locale: string) => void;
    setErrors: (formId: string, errors: string[] | Record<string, string | string[]>, inputErrors?: string[] | Record<string, string | string[]>) => void;
    clearErrors: (formId: string) => void;
    submit: (formId: string) => void;
    reset: (formId: string, resetTo?: unknown) => void;
}
/**
 * The symbol key for accessing the FormKit node options.
 *
 * @public
 */
declare const optionsSymbol: InjectionKey<FormKitOptions>;
/**
 * The symbol key for accessing FormKit root configuration.
 *
 * @public
 */
declare const configSymbol: InjectionKey<FormKitRootConfig>;
/**
 * Create the FormKit plugin.
 *
 * @public
 */
declare const plugin: Plugin;

/**
 * The symbol that represents the formkit’s root element injection value.
 *
 * @public
 */
declare const rootSymbol: InjectionKey<Ref<Document | ShadowRoot | undefined>>;
/**
 * The FormKitRoot wrapper component used to provide context to FormKit about
 * whether a FormKit input is booting in a Document or ShadowRoot. This is
 * generally only necessary when booting FormKit nodes in contexts that do not
 * have a document. For example, if running code like this:
 *
 * ```ts
 * document.getElementById(node.props.id)
 * ```
 *
 * does not work because the `document` is not available or is not in the same
 * scope, you can place a `<FormKitRoot>` component somewhere near the root of
 * of your shadowRoot and it will inform any FormKitNode child (at any depth)
 * that it is running in a shadow root. The "root" (`Document` or `ShadowRoot`)
 * will be made available to all child nodes at `node.context._root`
 *
 * @public
 */
declare const FormKitRoot: vue.DefineSetupFnComponent<Record<string, any>, {}, {}, Record<string, any> & {}, vue.PublicProps>;

/**
 * Renders FormKit components fetched from a remote schema repository.
 * This is a kitchen sink component that is used for testing purposes.
 * It shows inputs in various states and configurations.
 *
 * @public
 */
declare const FormKitKitchenSink: vue.DefineComponent<{
    schemas: {
        type: ArrayConstructor;
        required: false;
    };
    pro: {
        type: BooleanConstructor;
        default: boolean;
    };
    addons: {
        type: BooleanConstructor;
        default: boolean;
    };
    forms: {
        type: BooleanConstructor;
        default: boolean;
    };
    navigation: {
        type: BooleanConstructor;
        default: boolean;
    };
}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}>, unknown, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<vue.ExtractPropTypes<{
    schemas: {
        type: ArrayConstructor;
        required: false;
    };
    pro: {
        type: BooleanConstructor;
        default: boolean;
    };
    addons: {
        type: BooleanConstructor;
        default: boolean;
    };
    forms: {
        type: BooleanConstructor;
        default: boolean;
    };
    navigation: {
        type: BooleanConstructor;
        default: boolean;
    };
}>>, {
    pro: boolean;
    addons: boolean;
    forms: boolean;
    navigation: boolean;
}, {}>;

/**
 * Renders the messages for a parent node, or any node explicitly passed to it.
 * @public
 */
declare const FormKitMessages: vue.DefineComponent<{
    node: {
        type: PropType<FormKitNode> | undefined;
        required: false;
    };
    sectionsSchema: {
        type: PropType<Record<string, FormKitSchemaCondition | Partial<FormKitSchemaNode>>>;
        default: {};
    };
    defaultPosition: {
        type: PropType<boolean | "true" | "false" | undefined>;
        default: boolean;
    };
    library: {
        type: PropType<Record<string, Component>>;
        default: () => {};
    };
}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}> | null, unknown, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<vue.ExtractPropTypes<{
    node: {
        type: PropType<FormKitNode> | undefined;
        required: false;
    };
    sectionsSchema: {
        type: PropType<Record<string, FormKitSchemaCondition | Partial<FormKitSchemaNode>>>;
        default: {};
    };
    defaultPosition: {
        type: PropType<boolean | "true" | "false" | undefined>;
        default: boolean;
    };
    library: {
        type: PropType<Record<string, Component>>;
        default: () => {};
    };
}>>, {
    library: Record<string, Component>;
    sectionsSchema: Record<string, FormKitSchemaCondition | Partial<FormKitSchemaNode>>;
    defaultPosition: boolean | "true" | "false" | undefined;
}, {}>;

/**
 * A composable to provide a given configuration to all children.
 * @param config - A FormKit configuration object or a function
 */
declare function useConfig(config?: FormKitOptions | ((...args: any[]) => FormKitOptions)): void;
interface ConfigLoaderProps {
    defaultConfig?: boolean;
    configFile?: string;
}
/**
 * The FormKitProvider component provides the FormKit config to the children.
 *
 * @public
 */
declare const FormKitProvider: vue.DefineSetupFnComponent<{
    config: any;
}, {}, {}, {
    config: any;
} & {}, vue.PublicProps>;
/**
 * The FormKitLazyProvider component performs 2 HOC functions:
 *
 * 1. It checks if a FormKit config has already been provided, if it has it will
 *   render the children immediately.
 * 2. If a config has not been provided, it will render a Suspense component
 *    which will render the children once the config has been loaded by using
 *    the FormKitConfigLoader component.
 *
 * @public
 */
declare const FormKitLazyProvider: vue.DefineSetupFnComponent<ConfigLoaderProps, {}, {}, ConfigLoaderProps & {}, vue.PublicProps>;

/**
 * Uses the FormKit context to access the current FormKit context. This must be
 * used in a component that is a child of the FormKit component.
 * @param effect - An optional effect callback to run when the context is available.
 */
declare function useFormKitContext<T = FormKitGroupValue>(effect?: (context: FormKitFrameworkContext<T>) => void): Ref<FormKitFrameworkContext<T> | undefined>;
/**
 * Allows access to a specific context by address.
 * @param address - An optional address of the context to access.
 * @param effect - An optional effect callback to run when the context is available.
 */
declare function useFormKitContext<T = FormKitGroupValue>(address?: string, effect?: (context: FormKitFrameworkContext<T>) => void): Ref<FormKitFrameworkContext<T> | undefined>;
/**
 * Allows global access to a specific context by id. The target node MUST have
 * an explicitly defined id.
 * @param id - The id of the node to access the context for.
 * @param effect - An effect callback to run when the context is available.
 */
declare function useFormKitContextById<T = any>(id: string, effect?: (context: FormKitFrameworkContext<T>) => void): Ref<FormKitFrameworkContext<T> | undefined>;
/**
 * Fetches a node by id and returns a ref to the node. The node in question
 * must have an explicitly assigned id prop. If the node is not available, the
 * ref will be undefined until the node is available.
 * @param id - The id of the node to access.
 * @param effect - An optional effect callback to run when the node is available.
 * @returns
 */
declare function useFormKitNodeById<T>(id: string, effect?: (node: FormKitNode<T>) => void): Ref<FormKitNode<T> | undefined>;

interface FormKitSummaryMessage {
    message: string;
    id: string;
    key: string;
    type: string;
}
/**
 * Renders the messages for a parent node, or any node explicitly passed to it.
 * @public
 */
declare const FormKitSummary: vue.DefineComponent<{
    node: {
        type: PropType<FormKitNode> | undefined;
        required: false;
    };
    forceShow: {
        type: BooleanConstructor;
        default: boolean;
    };
    sectionsSchema: {
        type: PropType<Record<string, FormKitSchemaCondition | Partial<FormKitSchemaNode>>>;
        default: {};
    };
}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}> | null, unknown, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {
    show: (_summaries: Array<FormKitSummaryMessage>) => boolean;
}, string, vue.PublicProps, Readonly<vue.ExtractPropTypes<{
    node: {
        type: PropType<FormKitNode> | undefined;
        required: false;
    };
    forceShow: {
        type: BooleanConstructor;
        default: boolean;
    };
    sectionsSchema: {
        type: PropType<Record<string, FormKitSchemaCondition | Partial<FormKitSchemaNode>>>;
        default: {};
    };
}>> & {
    onShow?: ((_summaries: FormKitSummaryMessage[]) => any) | undefined;
}, {
    sectionsSchema: Record<string, FormKitSchemaCondition | Partial<FormKitSchemaNode>>;
    forceShow: boolean;
}, {}>;

/**
 * Configuration for plugins
 *
 * @public
 */
interface PluginConfigs {
    rules: Record<string, FormKitValidationRule>;
    locales: FormKitLocaleRegistry;
    inputs: FormKitLibrary;
    messages: Record<string, Partial<FormKitLocale>>;
    locale: string;
    theme: string;
    iconLoaderUrl: FormKitIconLoaderUrl;
    iconLoader: FormKitIconLoader;
    icons: Record<string, string | undefined>;
}
/**
 * The allowed options for defaultConfig.
 *
 * @public
 */
type DefaultConfigOptions = FormKitOptions & Partial<PluginConfigs> & Record<string, unknown>;
/**
 * Default configuration options. Includes all validation rules,
 * en i18n messages.
 *
 * @public
 */
declare const defaultConfig: (options?: DefaultConfigOptions) => FormKitOptions;

/**
 * A plugin that creates Vue-specific context object on each given node.
 *
 * @param node - FormKitNode to create the context on.
 *
 * @public
 */
declare const vueBindings: FormKitPlugin;

/**
 * Renders an icon using the current IconLoader set at the root FormKit config
 *
 * @public
 */
declare const FormKitIcon: vue.DefineComponent<{
    icon: {
        type: StringConstructor;
        default: string;
    };
    iconLoader: {
        type: PropType<FormKitIconLoader>;
        default: null;
    };
    iconLoaderUrl: {
        type: PropType<(iconName: string) => string>;
        default: null;
    };
}, () => vue.VNode<vue.RendererNode, vue.RendererElement, {
    [key: string]: any;
}> | null, unknown, {}, {}, vue.ComponentOptionsMixin, vue.ComponentOptionsMixin, {}, string, vue.PublicProps, Readonly<vue.ExtractPropTypes<{
    icon: {
        type: StringConstructor;
        default: string;
    };
    iconLoader: {
        type: PropType<FormKitIconLoader>;
        default: null;
    };
    iconLoaderUrl: {
        type: PropType<(iconName: string) => string>;
        default: null;
    };
}>>, {
    icon: string;
    iconLoaderUrl: (iconName: string) => string;
    iconLoader: FormKitIconLoader;
}, {}>;

declare function resetCount(): void;

/**
 * Flush all callbacks registered with onSSRComplete for a given app.
 * @param app - The Vue application.
 * @public
 */
declare function ssrComplete(app: App<any>): void;
/**
 * Register a callback for when SSR is complete. No-op if not in a server
 * context.
 * @param app - The Vue application.
 * @param callback - The callback to be called after SSR is complete.
 * @public
 */
declare function onSSRComplete(app: App<any> | undefined, callback: CallableFunction): void;

/**
 * The official FormKit/Vue integration. This package is responsible for
 * integrating Vue with FormKit core and other first-party packages.
 *
 *
 * @packageDocumentation
 */
declare global {
    var __FORMKIT_CONFIGS__: FormKitRootConfig[];
}

export { type DefaultConfigOptions, formkitComponent as FormKit, type FormKitComponent, type FormKitComponentLibrary, FormKitIcon, FormKitKitchenSink, FormKitLazyProvider, FormKitMessages, FormKitProvider, FormKitRoot, FormKitSchema, type FormKitSetupContext, FormKitSummary, type FormKitSummaryMessage, type FormKitVuePlugin, type PluginConfigs, type Renderable, type RenderableList, type RenderableSlot, type RenderableSlots, type Slots, type VirtualNode, vueBindings as bindings, componentSymbol, configSymbol, createInput, defaultConfig, defineFormKitConfig, getCurrentSchemaNode, onSSRComplete, optionsSymbol, parentSymbol, plugin, resetCount, rootSymbol, ssrComplete, useConfig, useFormKitContext, useFormKitContextById, useFormKitNodeById, useInput };
