import { AnyFramework, StoryId, ProjectAnnotations, Args, Globals } from '@storybook/csf';
import { ModuleImportFn, Selection, Story, StorySpecifier, StoryIndex, PromiseLike, WebProjectAnnotations } from '@storybook/store';
import { Preview } from './Preview';
import { UrlStore } from './UrlStore';
import { WebView } from './WebView';
import { Render } from './StoryRender';
declare type MaybePromise<T> = Promise<T> | T;
export declare class PreviewWeb<TFramework extends AnyFramework> extends Preview<TFramework> {
    urlStore: UrlStore;
    view: WebView;
    previewEntryError?: Error;
    currentSelection: Selection;
    currentRender: Render<TFramework>;
    constructor();
    setupListeners(): void;
    initializeWithProjectAnnotations(projectAnnotations: WebProjectAnnotations<TFramework>): Promise<void>;
    setInitialGlobals(): Promise<void>;
    initializeWithStoryIndex(storyIndex: StoryIndex): PromiseLike<void>;
    selectSpecifiedStory(): Promise<void>;
    onGetProjectAnnotationsChanged({ getProjectAnnotations, }: {
        getProjectAnnotations: () => MaybePromise<ProjectAnnotations<TFramework>>;
    }): Promise<void>;
    onStoriesChanged({ importFn, storyIndex, }: {
        importFn?: ModuleImportFn;
        storyIndex?: StoryIndex;
    }): Promise<void>;
    onKeydown(event: KeyboardEvent): void;
    onSetCurrentStory(selection: Selection): void;
    onUpdateQueryParams(queryParams: any): void;
    onUpdateGlobals({ globals }: {
        globals: Globals;
    }): Promise<void>;
    onUpdateArgs({ storyId, updatedArgs }: {
        storyId: StoryId;
        updatedArgs: Args;
    }): Promise<void>;
    onPreloadStories(ids: string[]): Promise<void>;
    renderSelection({ persistedArgs }?: {
        persistedArgs?: Args;
    }): Promise<void>;
    renderStoryToElement(story: Story<TFramework>, element: HTMLElement): () => Promise<void>;
    teardownRender(render: Render<TFramework>, { viewModeChanged }?: {
        viewModeChanged?: boolean;
    }): Promise<void>;
    extract(options?: {
        includeDocsOnly: boolean;
    }): Promise<Record<string, import("@storybook/csf").StoryContextForEnhancers<TFramework, Args>>>;
    mainStoryCallbacks(storyId: StoryId): {
        showMain: () => void;
        showError: (err: {
            title: string;
            description: string;
        }) => void;
        showException: (err: Error) => void;
    };
    inlineStoryCallbacks(storyId: StoryId): {
        showMain: () => void;
        showError: (err: {
            title: string;
            description: string;
        }) => void;
        showException: (err: Error) => void;
    };
    renderPreviewEntryError(reason: string, err: Error): void;
    renderMissingStory(): void;
    renderStoryLoadingException(storySpecifier: StorySpecifier, err: Error): void;
    renderException(storyId: StoryId, err: Error): void;
    renderError(storyId: StoryId, { title, description }: {
        title: string;
        description: string;
    }): void;
}
export {};
