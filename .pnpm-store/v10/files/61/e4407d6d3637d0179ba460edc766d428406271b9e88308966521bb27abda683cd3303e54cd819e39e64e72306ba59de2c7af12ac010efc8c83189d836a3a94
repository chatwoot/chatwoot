import type { Context } from './context.js';
import type { ServerStory } from '@histoire/shared';
interface SerializedStory extends Omit<ServerStory, 'docsText'> {
    relativePath: string;
    supportPluginId: string;
    treePath?: string[];
    virtual?: boolean;
    markdownFile?: SerializedMarkdownFile;
}
interface SerializedMarkdownFile {
    id: string;
    relativePath: string;
    isRelatedToStory: boolean;
    frontmatter?: any;
}
interface SerializedStoryData {
    stories: SerializedStory[];
    markdownFiles: SerializedMarkdownFile[];
}
export declare function getSerializedStoryData(ctx: Context): SerializedStoryData;
export {};
