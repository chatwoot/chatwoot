import type { ViteDevServer } from 'vite';
import type { ServerStoryFile } from '@histoire/shared';
import type { Context } from '../context.js';
export interface UseCollectStoriesOptions {
    server: ViteDevServer;
    mainServer?: ViteDevServer;
    throws?: boolean;
}
export declare function useCollectStories(options: UseCollectStoriesOptions, ctx: Context): {
    clearCache: () => void;
    executeStoryFile: (storyFile: ServerStoryFile) => Promise<void>;
    destroy: () => Promise<void>;
};
