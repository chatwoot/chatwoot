import type { Addon, StoryId, StoryName, StoryKind, ViewMode, StoryFn, Parameters, Args, ArgTypes, StoryApi, DecoratorFunction, LoaderFunction, StoryContext } from '@storybook/addons';
import { AnyFramework, StoryIdentifier, ProjectAnnotations } from '@storybook/csf';
import type { RenderContext } from '@storybook/store';
import { StoryStore, HooksContext } from '@storybook/store';
export type { SBType, SBScalarType, SBArrayType, SBObjectType, SBEnumType, SBIntersectionType, SBUnionType, SBOtherType, } from '@storybook/csf';
export interface ErrorLike {
    message: string;
    stack: string;
}
export interface StoryMetadata {
    parameters?: Parameters;
    decorators?: DecoratorFunction[];
    loaders?: LoaderFunction[];
}
export declare type ArgTypesEnhancer = (context: StoryContext) => ArgTypes;
export declare type ArgsEnhancer = (context: StoryContext) => Args;
declare type StorySpecifier = StoryId | {
    name: StoryName;
    kind: StoryKind;
} | '*';
export interface StoreSelectionSpecifier {
    storySpecifier: StorySpecifier;
    viewMode: ViewMode;
    singleStory?: boolean;
    args?: Args;
    globals?: Args;
}
export interface StoreSelection {
    storyId: StoryId;
    viewMode: ViewMode;
}
export declare type AddStoryArgs = StoryIdentifier & {
    storyFn: StoryFn<any>;
    parameters?: Parameters;
    decorators?: DecoratorFunction[];
    loaders?: LoaderFunction[];
};
export declare type StoreItem = StoryIdentifier & {
    parameters: Parameters;
    getDecorated: () => StoryFn<any>;
    getOriginal: () => StoryFn<any>;
    applyLoaders: () => Promise<StoryContext>;
    playFunction: (context: StoryContext) => Promise<void> | void;
    storyFn: StoryFn<any>;
    unboundStoryFn: StoryFn<any>;
    hooks: HooksContext<AnyFramework>;
    args: Args;
    initialArgs: Args;
    argTypes: ArgTypes;
};
export declare type PublishedStoreItem = StoreItem & {
    globals: Args;
};
export interface StoreData {
    [key: string]: StoreItem;
}
export interface ClientApiParams {
    storyStore: StoryStore<AnyFramework>;
    decorateStory?: ProjectAnnotations<AnyFramework>['applyDecorators'];
    noStoryModuleAddMethodHotDispose?: boolean;
}
export declare type ClientApiReturnFn<StoryFnReturnType> = (...args: any[]) => StoryApi<StoryFnReturnType>;
export type { StoryApi, DecoratorFunction };
export interface ClientApiAddon<StoryFnReturnType = unknown> extends Addon {
    apply: (a: StoryApi<StoryFnReturnType>, b: any[]) => any;
}
export interface ClientApiAddons<StoryFnReturnType> {
    [key: string]: ClientApiAddon<StoryFnReturnType>;
}
export interface GetStorybookStory {
    name: string;
    render: StoryFn;
}
export interface GetStorybookKind {
    kind: string;
    fileName: string;
    stories: GetStorybookStory[];
}
export declare type RenderContextWithoutStoryContext = Omit<RenderContext, 'storyContext'>;
