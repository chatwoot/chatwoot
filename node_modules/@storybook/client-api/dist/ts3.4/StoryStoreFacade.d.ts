import { AnyFramework, StoryFn } from '@storybook/csf';
import { StoryStore } from '@storybook/store';
import { NormalizedProjectAnnotations, Path, StoryIndex, ModuleExports, StoryIndexEntry } from '@storybook/store';
export interface GetStorybookStory<TFramework extends AnyFramework> {
    name: string;
    render: StoryFn<TFramework>;
}
export interface GetStorybookKind<TFramework extends AnyFramework> {
    kind: string;
    fileName: string;
    stories: GetStorybookStory<TFramework>[];
}
export declare class StoryStoreFacade<TFramework extends AnyFramework> {
    projectAnnotations: NormalizedProjectAnnotations<TFramework>;
    stories: StoryIndex['stories'];
    csfExports: Record<Path, ModuleExports>;
    constructor();
    importFn(path: Path): Promise<Record<string, any>>;
    getStoryIndex(store: StoryStore<TFramework>): {
        v: number;
        stories: Record<string, StoryIndexEntry>;
    };
    clearFilenameExports(fileName: Path): void;
    addStoriesFromExports(fileName: Path, fileExports: ModuleExports): void;
}
