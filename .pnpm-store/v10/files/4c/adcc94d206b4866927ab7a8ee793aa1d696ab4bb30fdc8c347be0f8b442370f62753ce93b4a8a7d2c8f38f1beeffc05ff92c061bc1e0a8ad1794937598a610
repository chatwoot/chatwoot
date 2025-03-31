import { ResolvedConfig } from 'vite';
import type { ServerStoryFile, FinalSupportPlugin, ServerMarkdownFile, HistoireConfig, ConfigMode, PluginCommand } from '@histoire/shared';
export interface Context {
    root: string;
    config: HistoireConfig;
    resolvedViteConfig: ResolvedConfig;
    mode: ConfigMode;
    storyFiles: ServerStoryFile[];
    supportPlugins: FinalSupportPlugin[];
    markdownFiles: ServerMarkdownFile[];
    registeredCommands?: PluginCommand[];
}
export interface CreateContextOptions {
    mode: Context['mode'];
    configFile?: string;
}
export declare function createContext(options: CreateContextOptions): Promise<Context>;
