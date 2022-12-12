import type { AnyFramework } from '@storybook/csf';
import type { NormalizedComponentAnnotations, Story, NormalizedStoryAnnotations, NormalizedProjectAnnotations } from '../types';
export declare function prepareStory<TFramework extends AnyFramework>(storyAnnotations: NormalizedStoryAnnotations<TFramework>, componentAnnotations: NormalizedComponentAnnotations<TFramework>, projectAnnotations: NormalizedProjectAnnotations<TFramework>): Story<TFramework>;
