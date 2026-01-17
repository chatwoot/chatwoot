import chokidar from 'chokidar';
import path from 'pathe';
import fs from 'fs-extra';
import type { Plugin, PluginApiBase, PluginApiDev, PluginApiBuild, ChangeViteConfigCallback, BuildEndCallback, PreviewStoryCallback, ModuleLoader, ServerStory, PluginApiDevEvent, HistoireConfig } from '@histoire/shared';
import type { Context } from './context.js';
export declare class BasePluginApi implements PluginApiBase {
    protected ctx: Context;
    protected plugin: Plugin;
    moduleLoader: ModuleLoader;
    colors: import("picocolors/types.js").Colors & {
        createColors: (enabled?: boolean) => import("picocolors/types.js").Colors;
    };
    path: typeof path;
    fs: typeof fs;
    constructor(ctx: Context, plugin: Plugin, moduleLoader: ModuleLoader);
    get pluginTempDir(): string;
    log(...msg: any[]): void;
    warn(...msg: any[]): void;
    error(...msg: any[]): void;
    addStoryFile(file: string): void;
    getStories(): ServerStory[];
    getConfig(): HistoireConfig;
}
export declare class DevPluginApi extends BasePluginApi implements PluginApiDev {
    watcher: typeof chokidar;
}
export declare class BuildPluginApi extends BasePluginApi implements PluginApiBuild {
    changeViteConfigCallbacks: ChangeViteConfigCallback[];
    buildEndCallbacks: BuildEndCallback[];
    previewStoryCallbacks: PreviewStoryCallback[];
    changeViteConfig(cb: ChangeViteConfigCallback): void;
    onBuildEnd(cb: BuildEndCallback): void;
    onPreviewStory(cb: PreviewStoryCallback): void;
}
export declare class DevEventPluginApi extends BasePluginApi implements PluginApiDevEvent {
    event: string;
    payload: any;
    constructor(ctx: Context, plugin: Plugin, moduleLoader: ModuleLoader, event: string, payload: any);
}
