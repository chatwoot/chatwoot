import { DecoratorFunction, StoryContextUpdate, PartialStoryFn, LegacyStoryFn, AnyFramework } from '@storybook/csf';
export declare function decorateStory<TFramework extends AnyFramework>(storyFn: LegacyStoryFn<TFramework>, decorator: DecoratorFunction<TFramework>, bindWithContext: (storyFn: LegacyStoryFn<TFramework>) => PartialStoryFn<TFramework>): LegacyStoryFn<TFramework>;
/**
 * Currently StoryContextUpdates are allowed to have any key in the type.
 * However, you cannot overwrite any of the build-it "static" keys.
 *
 * @param inputContextUpdate StoryContextUpdate
 * @returns StoryContextUpdate
 */
export declare function sanitizeStoryContextUpdate({ componentId, title, kind, id, name, story, parameters, initialArgs, argTypes, ...update }?: StoryContextUpdate): StoryContextUpdate;
export declare function defaultDecorateStory<TFramework extends AnyFramework>(storyFn: LegacyStoryFn<TFramework>, decorators: DecoratorFunction<TFramework>[]): LegacyStoryFn<TFramework>;
