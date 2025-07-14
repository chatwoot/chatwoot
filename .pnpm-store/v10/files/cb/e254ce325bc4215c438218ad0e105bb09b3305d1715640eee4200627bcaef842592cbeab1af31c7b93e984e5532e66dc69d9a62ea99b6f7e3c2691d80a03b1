import MarkdownIt from 'markdown-it';
import type { Plugin as VitePlugin } from 'vite';
import type { Context } from './context.js';
export declare function onMarkdownListChange(handler: () => unknown): void;
export declare function createMarkdownRenderer(ctx: Context): Promise<MarkdownIt>;
export declare function createMarkdownPlugins(ctx: Context): Promise<VitePlugin<any>[]>;
export declare function createMarkdownFilesWatcher(ctx: Context): Promise<{
    stop: () => Promise<void>;
}>;
export type MarkdownFilesWatcher = ReturnType<typeof createMarkdownFilesWatcher>;
