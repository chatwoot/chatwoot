import { StoryId, Args } from '@storybook/csf';
import { Story } from './types';
export declare class ArgsStore {
    initialArgsByStoryId: Record<StoryId, Args>;
    argsByStoryId: Record<StoryId, Args>;
    get(storyId: StoryId): Args;
    setInitial(story: Story<any>): void;
    updateFromDelta(story: Story<any>, delta: Args): void;
    updateFromPersisted(story: Story<any>, persisted: Args): void;
    update(storyId: StoryId, argsUpdate: Partial<Args>): void;
}
