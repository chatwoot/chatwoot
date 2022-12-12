/// <reference types="webpack-env" />
import type { Args, ArgTypes, AnyFramework, DecoratorFunction, Parameters, ArgTypesEnhancer, ArgsEnhancer, LoaderFunction, StoryFn, Globals, GlobalTypes, LegacyStoryFn } from '@storybook/csf';
import { StoryStore } from '@storybook/store';
import type { Path, ModuleImportFn } from '@storybook/store';
import type { StoryApi } from '@storybook/addons';
import { StoryStoreFacade } from './StoryStoreFacade';
export interface GetStorybookStory<TFramework extends AnyFramework> {
    name: string;
    render: LegacyStoryFn<TFramework>;
}
export interface GetStorybookKind<TFramework extends AnyFramework> {
    kind: string;
    fileName: string;
    stories: GetStorybookStory<TFramework>[];
}
export declare const addDecorator: (decorator: DecoratorFunction<AnyFramework>, deprecationWarning?: boolean) => void;
export declare const addParameters: (parameters: Parameters, deprecationWarning?: boolean) => void;
export declare const addLoader: (loader: LoaderFunction<AnyFramework>, deprecationWarning?: boolean) => void;
export declare const addArgs: (args: Args) => void;
export declare const addArgTypes: (argTypes: ArgTypes) => void;
export declare const addArgsEnhancer: (enhancer: ArgsEnhancer<AnyFramework>) => void;
export declare const addArgTypesEnhancer: (enhancer: ArgTypesEnhancer<AnyFramework>) => void;
export declare const getGlobalRender: () => import("@storybook/csf").ArgsStoryFn<AnyFramework, Args>;
export declare const setGlobalRender: (render: StoryFn<AnyFramework>) => void;
export declare class ClientApi<TFramework extends AnyFramework> {
    facade: StoryStoreFacade<TFramework>;
    storyStore?: StoryStore<TFramework>;
    private addons;
    onImportFnChanged?: ({ importFn }: {
        importFn: ModuleImportFn;
    }) => void;
    private lastFileName;
    constructor({ storyStore }?: {
        storyStore?: StoryStore<TFramework>;
    });
    importFn(path: Path): Promise<Record<string, any>>;
    getStoryIndex(): {
        v: number;
        stories: Record<string, import("@storybook/store").StoryIndexEntry>;
    };
    setAddon: (addon: any) => void;
    addDecorator: (decorator: DecoratorFunction<TFramework>) => void;
    clearDecorators: () => void;
    addParameters: ({ globals, globalTypes, ...parameters }: Parameters & {
        globals?: Globals;
        globalTypes?: GlobalTypes;
    }) => void;
    addLoader: (loader: LoaderFunction<TFramework>) => void;
    addArgs: (args: Args) => void;
    addArgTypes: (argTypes: ArgTypes) => void;
    addArgsEnhancer: (enhancer: ArgsEnhancer<TFramework>) => void;
    addArgTypesEnhancer: (enhancer: ArgTypesEnhancer<TFramework>) => void;
    storiesOf: (kind: string, m?: NodeModule) => StoryApi<TFramework['storyResult']>;
    getStorybook: () => GetStorybookKind<TFramework>[];
    raw: () => import("@storybook/store").BoundStory<TFramework>[];
    get _storyStore(): StoryStore<TFramework>;
}
