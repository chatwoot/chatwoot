import type { RouteLocationNormalizedLoaded } from 'vue-router';
import type { Prompt } from './prompt.js';
import type { Story, Variant } from './story.js';
export interface CommonCommandOptions {
    icon?: string;
    searchText?: string;
    prompts?: Prompt[];
}
export interface Command extends CommonCommandOptions {
    id: string;
    label: string;
}
export interface ClientCommandOptions extends CommonCommandOptions {
    showIf?: (ctx: ClientCommandContext) => boolean;
    getParams?: (ctx: ClientCommandContext & {
        answers?: Record<string, any>;
    }) => Record<string, any>;
    clientAction?: (params: Record<string, any>, ctx: ClientCommandContext) => unknown;
}
/**
 * A command that can be executed from the search bar.
 */
export type ClientCommand = Command & ClientCommandOptions;
export interface ClientCommandContext {
    route: RouteLocationNormalizedLoaded;
    currentStory: Story;
    currentVariant: Variant;
}
export interface PluginCommand<TParams = Record<string, any>> extends Command {
    serverAction?: (params: TParams) => unknown;
    clientSetupFile?: string | {
        file: string;
        importName: string;
    };
}
