import type { Parameters, StoryId, StoryContextForLoaders, AnyFramework, ProjectAnnotations, StoryContextForEnhancers } from '@storybook/csf';
import { SynchronousPromise } from 'synchronous-promise';
import { StoryIndexStore } from './StoryIndexStore';
import { ArgsStore } from './ArgsStore';
import { GlobalsStore } from './GlobalsStore';
import { processCSFFile, prepareStory } from './csf';
import type { CSFFile, ModuleImportFn, Story, NormalizedProjectAnnotations, Path, ExtractOptions, BoundStory, PromiseLike, StoryIndex, StoryIndexEntry, V2CompatIndexEntry } from './types';
import { HooksContext } from './hooks';
export declare class StoryStore<TFramework extends AnyFramework> {
    storyIndex: StoryIndexStore;
    importFn: ModuleImportFn;
    projectAnnotations: NormalizedProjectAnnotations<TFramework>;
    globals: GlobalsStore;
    args: ArgsStore;
    hooks: Record<StoryId, HooksContext<TFramework>>;
    cachedCSFFiles?: Record<Path, CSFFile<TFramework>>;
    processCSFFileWithCache: typeof processCSFFile;
    prepareStoryWithCache: typeof prepareStory;
    initializationPromise: SynchronousPromise<void>;
    resolveInitializationPromise: () => void;
    constructor();
    setProjectAnnotations(projectAnnotations: ProjectAnnotations<TFramework>): void;
    initialize({ storyIndex, importFn, cache, }: {
        storyIndex?: StoryIndex;
        importFn: ModuleImportFn;
        cache?: boolean;
    }): PromiseLike<void>;
    onStoriesChanged({ importFn, storyIndex, }: {
        importFn?: ModuleImportFn;
        storyIndex?: StoryIndex;
    }): Promise<void>;
    loadCSFFileByStoryId(storyId: StoryId): PromiseLike<CSFFile<TFramework>>;
    loadAllCSFFiles(): PromiseLike<StoryStore<TFramework>['cachedCSFFiles']>;
    cacheAllCSFFiles(): PromiseLike<void>;
    loadStory({ storyId }: {
        storyId: StoryId;
    }): Promise<Story<TFramework>>;
    storyFromCSFFile({ storyId, csfFile, }: {
        storyId: StoryId;
        csfFile: CSFFile<TFramework>;
    }): Story<TFramework>;
    componentStoriesFromCSFFile({ csfFile }: {
        csfFile: CSFFile<TFramework>;
    }): Story<TFramework>[];
    getStoryContext(story: Story<TFramework>): Omit<StoryContextForLoaders<TFramework>, 'viewMode'>;
    cleanupStory(story: Story<TFramework>): void;
    extract(options?: ExtractOptions): Record<StoryId, StoryContextForEnhancers<TFramework>>;
    getSetStoriesPayload(): {
        v: number;
        globals: import("@storybook/csf").Globals;
        globalParameters: {};
        kindParameters: Parameters;
        stories: Record<string, StoryContextForEnhancers<TFramework, import("@storybook/csf").Args>>;
    };
    getStoriesJsonData: () => {
        v: number;
        stories: Record<string, StoryIndexEntry | V2CompatIndexEntry>;
    };
    raw(): BoundStory<TFramework>[];
    fromId(storyId: StoryId): BoundStory<TFramework>;
}
