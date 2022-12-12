import { SBType, SBScalarType } from './SBType';
export * from './SBType';
export declare type StoryId = string;
export declare type ComponentId = string;
export declare type ComponentTitle = string;
export declare type StoryName = string;
export declare type StoryKind = ComponentTitle;
export interface StoryIdentifier {
    componentId: ComponentId;
    title: ComponentTitle;
    kind: ComponentTitle;
    id: StoryId;
    name: StoryName;
    story: StoryName;
}
export declare type Parameters = {
    [name: string]: any;
};
declare type ConditionalTest = {
    truthy?: boolean;
} | {
    exists: boolean;
} | {
    eq: any;
} | {
    neq: any;
};
declare type ConditionalValue = {
    arg: string;
} | {
    global: string;
};
export declare type Conditional = ConditionalValue & ConditionalTest;
export interface InputType {
    name?: string;
    description?: string;
    defaultValue?: any;
    type?: SBType | SBScalarType['name'];
    if?: Conditional;
    [key: string]: any;
}
export interface StrictInputType extends InputType {
    name: string;
    type?: SBType;
}
export declare type Args = {
    [name: string]: any;
};
export declare type ArgTypes<TArgs = Args> = {
    [name in keyof TArgs]: InputType;
};
export declare type StrictArgTypes<TArgs = Args> = {
    [name in keyof TArgs]: StrictInputType;
};
export declare type Globals = {
    [name: string]: any;
};
export declare type GlobalTypes = {
    [name: string]: InputType;
};
export declare type StrictGlobalTypes = {
    [name: string]: StrictInputType;
};
export declare type AnyFramework = {
    component: unknown;
    storyResult: unknown;
};
export declare type StoryContextForEnhancers<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = StoryIdentifier & {
    component?: TFramework['component'];
    subcomponents?: Record<string, TFramework['component']>;
    parameters: Parameters;
    initialArgs: TArgs;
    argTypes: StrictArgTypes<TArgs>;
};
export declare type ArgsEnhancer<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = (context: StoryContextForEnhancers<TFramework, TArgs>) => TArgs;
export declare type ArgTypesEnhancer<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = ((context: StoryContextForEnhancers<TFramework, TArgs>) => StrictArgTypes<TArgs>) & {
    secondPass?: boolean;
};
export declare type StoryContextUpdate<TArgs = Args> = {
    args?: TArgs;
    globals?: Globals;
    [key: string]: any;
};
export declare type ViewMode = 'story' | 'docs';
export declare type StoryContextForLoaders<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = StoryContextForEnhancers<TFramework, TArgs> & Required<StoryContextUpdate<TArgs>> & {
    hooks: unknown;
    viewMode: ViewMode;
    originalStoryFn: StoryFn<TFramework>;
};
export declare type LoaderFunction<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = (context: StoryContextForLoaders<TFramework, TArgs>) => Promise<Record<string, any>>;
export declare type StoryContext<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = StoryContextForLoaders<TFramework, TArgs> & {
    loaded: Record<string, any>;
    abortSignal: AbortSignal;
    canvasElement: HTMLElement;
};
export declare type PlayFunction<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = (context: StoryContext<TFramework, TArgs>) => Promise<void> | void;
export declare type PartialStoryFn<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = (update?: StoryContextUpdate<TArgs>) => TFramework['storyResult'];
export declare type LegacyStoryFn<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = (context: StoryContext<TFramework, TArgs>) => TFramework['storyResult'];
export declare type ArgsStoryFn<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = (args: TArgs, context: StoryContext<TFramework, TArgs>) => TFramework['storyResult'];
export declare type StoryFn<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = LegacyStoryFn<TFramework, TArgs> | ArgsStoryFn<TFramework, TArgs>;
export declare type DecoratorFunction<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = (fn: PartialStoryFn<TFramework, TArgs>, c: StoryContext<TFramework, TArgs>) => TFramework['storyResult'];
export declare type DecoratorApplicator<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = (storyFn: LegacyStoryFn<TFramework, TArgs>, decorators: DecoratorFunction<TFramework, TArgs>[]) => LegacyStoryFn<TFramework, TArgs>;
export declare type BaseAnnotations<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = {
    decorators?: DecoratorFunction<TFramework, Args>[];
    parameters?: Parameters;
    args?: Partial<TArgs>;
    argTypes?: Partial<ArgTypes<TArgs>>;
    loaders?: LoaderFunction<TFramework, Args>[];
    render?: ArgsStoryFn<TFramework, TArgs>;
};
export declare type ProjectAnnotations<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = BaseAnnotations<TFramework, TArgs> & {
    argsEnhancers?: ArgsEnhancer<TFramework, Args>[];
    argTypesEnhancers?: ArgTypesEnhancer<TFramework, Args>[];
    globals?: Globals;
    globalTypes?: GlobalTypes;
    applyDecorators?: DecoratorApplicator<TFramework, Args>;
};
declare type StoryDescriptor = string[] | RegExp;
export declare type ComponentAnnotations<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = BaseAnnotations<TFramework, TArgs> & {
    title?: ComponentTitle;
    id?: ComponentId;
    includeStories?: StoryDescriptor;
    excludeStories?: StoryDescriptor;
    component?: TFramework['component'];
    subcomponents?: Record<string, TFramework['component']>;
};
export declare type StoryAnnotations<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = BaseAnnotations<TFramework, TArgs> & {
    name?: StoryName;
    storyName?: StoryName;
    play?: PlayFunction<TFramework, TArgs>;
    story?: Omit<StoryAnnotations<TFramework, TArgs>, 'story'>;
};
export declare type LegacyAnnotatedStoryFn<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = StoryFn<TFramework, TArgs> & StoryAnnotations<TFramework, TArgs>;
export declare type LegacyStoryAnnotationsOrFn<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = LegacyAnnotatedStoryFn<TFramework, TArgs> | StoryAnnotations<TFramework, TArgs>;
export declare type AnnotatedStoryFn<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = ArgsStoryFn<TFramework, TArgs> & StoryAnnotations<TFramework, TArgs>;
export declare type StoryAnnotationsOrFn<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = AnnotatedStoryFn<TFramework, TArgs> | StoryAnnotations<TFramework, TArgs>;
