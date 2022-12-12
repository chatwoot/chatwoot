import { AnyFramework, AnnotatedStoryFn, StoryAnnotations, ComponentAnnotations, ProjectAnnotations, Args, Parameters } from '@storybook/csf';
import type { CSFExports, ComposedStoryPlayFn } from './types';
export * from './types';
export declare function setProjectAnnotations<TFramework extends AnyFramework = AnyFramework>(projectAnnotations: ProjectAnnotations<TFramework> | ProjectAnnotations<TFramework>[]): void;
interface ComposeStory<TFramework extends AnyFramework = AnyFramework, TArgs extends Args = Args> {
    (storyAnnotations: AnnotatedStoryFn<TFramework, TArgs> | StoryAnnotations<TFramework, TArgs>, componentAnnotations: ComponentAnnotations<TFramework, TArgs>, projectAnnotations: ProjectAnnotations<TFramework>, exportsName?: string): {
        (extraArgs: Partial<TArgs>): TFramework['storyResult'];
        storyName: string;
        args: Args;
        play: ComposedStoryPlayFn;
        parameters: Parameters;
    };
}
export declare function composeStory<TFramework extends AnyFramework = AnyFramework, TArgs extends Args = Args>(storyAnnotations: AnnotatedStoryFn<TFramework, TArgs> | StoryAnnotations<TFramework, TArgs>, componentAnnotations: ComponentAnnotations<TFramework, TArgs>, projectAnnotations?: ProjectAnnotations<TFramework>, defaultConfig?: ProjectAnnotations<TFramework>, exportsName?: string): {
    (extraArgs: Partial<TArgs>): TFramework["storyResult"];
    storyName: string;
    args: Args;
    play: ComposedStoryPlayFn;
    parameters: Parameters;
};
export declare function composeStories<TModule extends CSFExports>(storiesImport: TModule, globalConfig: ProjectAnnotations<AnyFramework>, composeStoryFn: ComposeStory): {};
