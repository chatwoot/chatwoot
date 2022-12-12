import { ComponentAnnotations, AnyFramework, LegacyStoryAnnotationsOrFn, StoryId } from '@storybook/csf';
import { NormalizedStoryAnnotations } from '../types';
export declare function normalizeStory<TFramework extends AnyFramework>(key: StoryId, storyAnnotations: LegacyStoryAnnotationsOrFn<TFramework>, meta: ComponentAnnotations<TFramework>): NormalizedStoryAnnotations<TFramework>;
