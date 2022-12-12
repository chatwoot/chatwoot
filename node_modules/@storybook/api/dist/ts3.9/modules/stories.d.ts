import { toId } from '@storybook/csf';
import type { StoriesHash, Story, Group, StoryId, Root, StoriesRaw, StoryIndex } from '../lib/stories';
import { Args, ModuleFn } from '../index';
import { ComposedRef } from './refs';
declare type Direction = -1 | 1;
declare type ParameterName = string;
declare type ViewMode = 'story' | 'info' | 'settings' | string | undefined;
declare type StoryUpdate = Pick<Story, 'parameters' | 'initialArgs' | 'argTypes' | 'args'>;
export interface SubState {
    storiesHash: StoriesHash;
    storyId: StoryId;
    viewMode: ViewMode;
    storiesConfigured: boolean;
    storiesFailed?: Error;
}
export interface SubAPI {
    storyId: typeof toId;
    resolveStory: (storyId: StoryId, refsId?: string) => Story | Group | Root;
    selectFirstStory: () => void;
    selectStory: (kindOrId: string, story?: string, obj?: {
        ref?: string;
        viewMode?: ViewMode;
    }) => void;
    getCurrentStoryData: () => Story | Group;
    setStories: (stories: StoriesRaw, failed?: Error) => Promise<void>;
    jumpToComponent: (direction: Direction) => void;
    jumpToStory: (direction: Direction) => void;
    getData: (storyId: StoryId, refId?: string) => Story | Group;
    isPrepared: (storyId: StoryId, refId?: string) => boolean;
    getParameters: (storyId: StoryId | {
        storyId: StoryId;
        refId: string;
    }, parameterName?: ParameterName) => Story['parameters'] | any;
    getCurrentParameter<S>(parameterName?: ParameterName): S;
    updateStoryArgs(story: Story, newArgs: Args): void;
    resetStoryArgs: (story: Story, argNames?: string[]) => void;
    findLeafStoryId(StoriesHash: StoriesHash, storyId: StoryId): StoryId;
    findSiblingStoryId(storyId: StoryId, hash: StoriesHash, direction: Direction, toSiblingGroup: boolean): StoryId;
    fetchStoryList: () => Promise<void>;
    setStoryList: (storyList: StoryIndex) => Promise<void>;
    updateStory: (storyId: StoryId, update: StoryUpdate, ref?: ComposedRef) => Promise<void>;
}
export declare const init: ModuleFn;
export {};
