import { Router } from 'express';
import type { NormalizedStoriesSpecifier } from '@storybook/core-common';
import { StoryIndexGenerator } from './StoryIndexGenerator';
import { ServerChannel } from './get-server-channel';
export declare const DEBOUNCE = 100;
export declare function extractStoriesJson(outputFile: string, initializedStoryIndexGenerator: Promise<StoryIndexGenerator>): Promise<void>;
export declare function useStoriesJson({ router, initializedStoryIndexGenerator, workingDir, serverChannel, normalizedStories, }: {
    router: Router;
    initializedStoryIndexGenerator: Promise<StoryIndexGenerator>;
    serverChannel: ServerChannel;
    workingDir?: string;
    normalizedStories: NormalizedStoriesSpecifier[];
}): void;
