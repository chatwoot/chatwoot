import { AnyFramework } from '@storybook/csf';
import { NormalizedComponentAnnotations, Story, NormalizedStoryAnnotations, NormalizedProjectAnnotations } from '../types';
export declare function prepareStory<TFramework extends AnyFramework>(storyAnnotations: NormalizedStoryAnnotations<TFramework>, componentAnnotations: NormalizedComponentAnnotations<TFramework>, projectAnnotations: NormalizedProjectAnnotations<TFramework>): Story<TFramework>;
