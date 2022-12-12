import type { Path, StoryIndex } from '@storybook/store';
import type { NormalizedStoriesSpecifier } from '@storybook/core-common';
export declare class StoryIndexGenerator {
    readonly specifiers: NormalizedStoriesSpecifier[];
    readonly options: {
        workingDir: Path;
        configDir: Path;
        storiesV2Compatibility: boolean;
        storyStoreV7: boolean;
    };
    private storyIndexEntries;
    private lastIndex?;
    constructor(specifiers: NormalizedStoriesSpecifier[], options: {
        workingDir: Path;
        configDir: Path;
        storiesV2Compatibility: boolean;
        storyStoreV7: boolean;
    });
    initialize(): Promise<void>;
    ensureExtracted(): Promise<StoryIndex['stories'][]>;
    extractStories(specifier: NormalizedStoriesSpecifier, absolutePath: Path): Promise<Record<string, import("@storybook/store").StoryIndexEntry>>;
    sortStories(storiesList: StoryIndex['stories'][]): Promise<Record<string, import("@storybook/store").StoryIndexEntry>>;
    getIndex(): Promise<StoryIndex>;
    invalidate(specifier: NormalizedStoriesSpecifier, importPath: Path, removed: boolean): void;
    getStorySortParameter(): Promise<any>;
    storyFileNames(): string[];
}
