import chokidar from 'chokidar';
import type { ServerStoryFile } from '@histoire/shared';
import { Context } from './context.js';
type StoryChangeHandler = (file?: ServerStoryFile) => unknown;
/**
 * Called when a new story is added or modified. Collecting should be done.
 * @param handler
 */
export declare function onStoryChange(handler: StoryChangeHandler): void;
export declare function notifyStoryChange(file?: ServerStoryFile): void;
type StoryListChangeHandler = () => unknown;
/**
 * Called when the story list has changed (ex: removed a story). No collecting should be needed.
 * @param handler
 */
export declare function onStoryListChange(handler: StoryListChangeHandler): void;
export declare function notifyStoryListChange(): void;
export declare function watchStories(newContext: Context): Promise<chokidar.FSWatcher>;
export declare function addStory(relativeFilePath: string, virtualModuleCode?: string): ServerStoryFile;
export declare function removeStory(relativeFilePath: string): void;
export declare function findAllStories(newContext: Context): Promise<void>;
export {};
