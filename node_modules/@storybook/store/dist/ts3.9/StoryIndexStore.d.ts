import { Channel } from '@storybook/addons';
import type { StoryId } from '@storybook/csf';
import type { StorySpecifier, StoryIndex, StoryIndexEntry } from './types';
export declare class StoryIndexStore {
    channel: Channel;
    stories: StoryIndex['stories'];
    constructor({ stories }?: StoryIndex);
    storyIdFromSpecifier(specifier: StorySpecifier): string;
    storyIdToEntry(storyId: StoryId): StoryIndexEntry;
}
