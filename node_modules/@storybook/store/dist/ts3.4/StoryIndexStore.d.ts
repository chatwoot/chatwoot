import { Channel } from '@storybook/addons';
import { StoryId } from '@storybook/csf';
import { StorySpecifier, StoryIndex, StoryIndexEntry } from './types';
export declare class StoryIndexStore {
    channel: Channel;
    stories: StoryIndex['stories'];
    constructor({ stories }?: StoryIndex);
    storyIdFromSpecifier(specifier: StorySpecifier): string;
    storyIdToEntry(storyId: StoryId): StoryIndexEntry;
}
