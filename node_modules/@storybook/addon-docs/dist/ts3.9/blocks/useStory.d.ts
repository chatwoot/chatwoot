import type { StoryId, AnyFramework } from '@storybook/csf';
import type { Story } from '@storybook/store';
import { DocsContextProps } from './DocsContext';
export declare function useStory<TFramework extends AnyFramework = AnyFramework>(storyId: StoryId, context: DocsContextProps<TFramework>): Story<TFramework> | void;
export declare function useStories<TFramework extends AnyFramework = AnyFramework>(storyIds: StoryId[], context: DocsContextProps<TFramework>): (Story<TFramework> | void)[];
