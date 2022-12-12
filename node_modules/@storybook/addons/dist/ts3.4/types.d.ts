/// <reference types="webpack-env" />
import { AnyFramework, InputType, StoryContext as StoryContextForFramework, LegacyStoryFn as LegacyStoryFnForFramework, PartialStoryFn as PartialStoryFnForFramework, ArgsStoryFn as ArgsStoryFnForFramework, StoryFn as StoryFnForFramework, DecoratorFunction as DecoratorFunctionForFramework, LoaderFunction as LoaderFunctionForFramework, StoryId, StoryKind, StoryName, Args } from '@storybook/csf';
import { Addon } from './index';
export { StoryId, StoryKind, StoryName, StoryIdentifier, ViewMode, Args, } from '@storybook/csf';
export interface ArgType<TArg = unknown> extends InputType {
    defaultValue?: TArg;
}
export declare type ArgTypes<TArgs = Args> = {
    [key in keyof Partial<TArgs>]: ArgType<TArgs[key]>;
} & {
    [key in string]: ArgType<unknown>;
};
export declare type Comparator<T> = ((a: T, b: T) => boolean) | ((a: T, b: T) => number);
export declare type StorySortMethod = 'configure' | 'alphabetical';
export interface StorySortObjectParameter {
    method?: StorySortMethod;
    order?: any[];
    locales?: string;
    includeNames?: boolean;
}
interface StoryIndexEntry {
    id: StoryId;
    name: StoryName;
    title: string;
    importPath: string;
}
export declare type StorySortComparator = Comparator<[
    StoryId,
    any,
    Parameters,
    Parameters
]>;
export declare type StorySortParameter = StorySortComparator | StorySortObjectParameter;
export declare type StorySortComparatorV7 = Comparator<StoryIndexEntry>;
export declare type StorySortParameterV7 = StorySortComparatorV7 | StorySortObjectParameter;
export interface OptionsParameter extends Object {
    storySort?: StorySortParameter;
    theme?: {
        base: string;
        brandTitle?: string;
    };
    [key: string]: any;
}
export interface Parameters {
    fileName?: string;
    options?: OptionsParameter;
    /** The layout property defines basic styles added to the preview body where the story is rendered. If you pass 'none', no styles are applied. */
    layout?: 'centered' | 'fullscreen' | 'padded' | 'none';
    docsOnly?: boolean;
    [key: string]: any;
}
export declare type StoryContext = StoryContextForFramework<AnyFramework>;
export declare type StoryContextUpdate = Partial<StoryContext>;
declare type ReturnTypeFramework<ReturnType> = {
    component: any;
    storyResult: ReturnType;
};
export declare type PartialStoryFn<ReturnType = unknown> = PartialStoryFnForFramework<ReturnTypeFramework<ReturnType>>;
export declare type LegacyStoryFn<ReturnType = unknown> = LegacyStoryFnForFramework<ReturnTypeFramework<ReturnType>>;
export declare type ArgsStoryFn<ReturnType = unknown> = ArgsStoryFnForFramework<ReturnTypeFramework<ReturnType>>;
export declare type StoryFn<ReturnType = unknown> = StoryFnForFramework<ReturnTypeFramework<ReturnType>>;
export declare type DecoratorFunction<StoryFnReturnType = unknown> = DecoratorFunctionForFramework<ReturnTypeFramework<StoryFnReturnType>>;
export declare type LoaderFunction = LoaderFunctionForFramework<ReturnTypeFramework<unknown>>;
export declare enum types {
    TAB = "tab",
    PANEL = "panel",
    TOOL = "tool",
    TOOLEXTRA = "toolextra",
    PREVIEW = "preview",
    NOTES_ELEMENT = "notes-element"
}
export declare type Types = types | string;
export declare function isSupportedType(type: Types): boolean;
export interface WrapperSettings {
    options: object;
    parameters: {
        [key: string]: any;
    };
}
export declare type StoryWrapper = (storyFn: LegacyStoryFn, context: StoryContext, settings: WrapperSettings) => any;
export declare type MakeDecoratorResult = (...args: any) => any;
export interface AddStoryArgs<StoryFnReturnType = unknown> {
    id: StoryId;
    kind: StoryKind;
    name: StoryName;
    storyFn: StoryFn<StoryFnReturnType>;
    parameters: Parameters;
}
export interface ClientApiAddon<StoryFnReturnType = unknown> extends Addon {
    apply: (a: StoryApi<StoryFnReturnType>, b: any[]) => any;
}
export interface ClientApiAddons<StoryFnReturnType> {
    [key: string]: ClientApiAddon<StoryFnReturnType>;
}
export interface IStorybookStory {
    name: string;
    render: (context: any) => any;
}
export interface IStorybookSection {
    kind: string;
    stories: IStorybookStory[];
}
export declare type ClientApiReturnFn<StoryFnReturnType = unknown> = (...args: any[]) => StoryApi<StoryFnReturnType>;
export interface StoryApi<StoryFnReturnType = unknown> {
    kind: StoryKind;
    add: (storyName: StoryName, storyFn: StoryFn<StoryFnReturnType>, parameters?: Parameters) => StoryApi<StoryFnReturnType>;
    addDecorator: (decorator: DecoratorFunction<StoryFnReturnType>) => StoryApi<StoryFnReturnType>;
    addLoader: (decorator: LoaderFunction) => StoryApi<StoryFnReturnType>;
    addParameters: (parameters: Parameters) => StoryApi<StoryFnReturnType>;
    [k: string]: string | ClientApiReturnFn<StoryFnReturnType>;
}
export interface ClientStoryApi<StoryFnReturnType = unknown> {
    storiesOf(kind: StoryKind, module: NodeModule): StoryApi<StoryFnReturnType>;
    addDecorator(decorator: DecoratorFunction<StoryFnReturnType>): StoryApi<StoryFnReturnType>;
    addParameters(parameter: Parameters): StoryApi<StoryFnReturnType>;
}
declare type LoadFn = () => any;
declare type RequireContext = any;
export declare type Loadable = RequireContext | [
    RequireContext
] | LoadFn;
export declare type BaseDecorators<StoryFnReturnType> = Array<(story: () => StoryFnReturnType, context: StoryContext) => StoryFnReturnType>;
export interface BaseAnnotations<Args, StoryFnReturnType> {
    /**
     * Dynamic data that are provided (and possibly updated by) Storybook and its addons.
     * @see [Arg story inputs](https://storybook.js.org/docs/react/api/csf#args-story-inputs)
     */
    args?: Partial<Args>;
    /**
     * ArgTypes encode basic metadata for args, such as `name`, `description`, `defaultValue` for an arg. These get automatically filled in by Storybook Docs.
     * @see [Control annotations](https://github.com/storybookjs/storybook/blob/91e9dee33faa8eff0b342a366845de7100415367/addons/controls/README.md#control-annotations)
     */
    argTypes?: ArgTypes<Args>;
    /**
     * Custom metadata for a story.
     * @see [Parameters](https://storybook.js.org/docs/basics/writing-stories/#parameters)
     */
    parameters?: Parameters;
    /**
     * Wrapper components or Storybook decorators that wrap a story.
     *
     * Decorators defined in Meta will be applied to every story variation.
     * @see [Decorators](https://storybook.js.org/docs/addons/introduction/#1-decorators)
     */
    decorators?: BaseDecorators<StoryFnReturnType>;
    /**
     * Define a custom render function for the story(ies). If not passed, a default render function by the framework will be used.
     */
    render?: (args: Args, context: StoryContext) => StoryFnReturnType;
    /**
     * Function that is executed after the story is rendered.
     */
    play?: (context: StoryContext) => Promise<void> | void;
}
export interface Annotations<Args, StoryFnReturnType> extends BaseAnnotations<Args, StoryFnReturnType> {
    /**
     * Used to only include certain named exports as stories. Useful when you want to have non-story exports such as mock data or ignore a few stories.
     * @example
     * includeStories: ['SimpleStory', 'ComplexStory']
     * includeStories: /.*Story$/
     *
     * @see [Non-story exports](https://storybook.js.org/docs/formats/component-story-format/#non-story-exports)
     */
    includeStories?: string[] | RegExp;
    /**
     * Used to exclude certain named exports. Useful when you want to have non-story exports such as mock data or ignore a few stories.
     * @example
     * excludeStories: ['simpleData', 'complexData']
     * excludeStories: /.*Data$/
     *
     * @see [Non-story exports](https://storybook.js.org/docs/formats/component-story-format/#non-story-exports)
     */
    excludeStories?: string[] | RegExp;
}
export interface BaseMeta<ComponentType> {
    /**
     * Title of the story which will be presented in the navigation. **Should be unique.**
     *
     * Stories can be organized in a nested structure using "/" as a separator.
     *
     * Since CSF 3.0 this property is optional.
     *
     * @example
     * export default {
     *   ...
     *   title: 'Design System/Atoms/Button'
     * }
     *
     * @see [Story Hierarchy](https://storybook.js.org/docs/basics/writing-stories/#story-hierarchy)
     */
    title?: string;
    /**
     * Manually set the id of a story, which in particular is useful if you want to rename stories without breaking permalinks.
     *
     * Storybook will prioritize the id over the title for ID generation, if provided, and will prioritize the story.storyName over the export key for display.
     *
     * @see [Sidebar and URLs](https://storybook.js.org/docs/react/configure/sidebar-and-urls#permalinking-to-stories)
     */
    id?: string;
    /**
     * The primary component for your story.
     *
     * Used by addons for automatic prop table generation and display of other component metadata.
     */
    component?: ComponentType;
    /**
     * Auxiliary subcomponents that are part of the stories.
     *
     * Used by addons for automatic prop table generation and display of other component metadata.
     *
     * @example
     * import { Button, ButtonGroup } from './components';
     *
     * export default {
     *   ...
     *   subcomponents: { Button, ButtonGroup }
     * }
     *
     * By defining them each component will have its tab in the args table.
     */
    subcomponents?: Record<string, ComponentType>;
}
export declare type BaseStoryObject<Args, StoryFnReturnType> = {
    /**
     * Override the display name in the UI
     */
    storyName?: string;
};
export declare type BaseStoryFn<Args, StoryFnReturnType> = {
    (args: Args, context: StoryContext): StoryFnReturnType;
} & BaseStoryObject<Args, StoryFnReturnType>;
export declare type BaseStory<Args, StoryFnReturnType> = BaseStoryFn<Args, StoryFnReturnType> | BaseStoryObject<Args, StoryFnReturnType>;
