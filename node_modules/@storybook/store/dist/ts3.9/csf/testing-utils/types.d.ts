import type { AnyFramework, AnnotatedStoryFn, StoryAnnotations, ComponentAnnotations, Args, StoryContext } from '@storybook/csf';
export declare type CSFExports<TFramework extends AnyFramework = AnyFramework> = {
    default: ComponentAnnotations<TFramework, Args>;
    __esModule?: boolean;
    __namedExportsOrder?: string[];
};
export declare type ComposedStoryPlayContext = Partial<StoryContext> & Pick<StoryContext, 'canvasElement'>;
export declare type ComposedStoryPlayFn = (context: ComposedStoryPlayContext) => Promise<void> | void;
export declare type StoryFn<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = AnnotatedStoryFn<TFramework, TArgs> & {
    play: ComposedStoryPlayFn;
};
export declare type ComposedStory<TFramework extends AnyFramework = AnyFramework, TArgs = Args> = StoryFn<TFramework, TArgs> | StoryAnnotations<TFramework, TArgs>;
/**
 * T represents the whole ES module of a stories file. K of T means named exports (basically the Story type)
 * 1. pick the keys K of T that have properties that are Story<AnyProps>
 * 2. infer the actual prop type for each Story
 * 3. reconstruct Story with Partial. Story<Props> -> Story<Partial<Props>>
 */
export declare type StoriesWithPartialProps<TFramework extends AnyFramework, TModule> = {
    [K in keyof TModule]: TModule[K] extends ComposedStory<infer _, infer TProps> ? AnnotatedStoryFn<TFramework, Partial<TProps>> : unknown;
};
