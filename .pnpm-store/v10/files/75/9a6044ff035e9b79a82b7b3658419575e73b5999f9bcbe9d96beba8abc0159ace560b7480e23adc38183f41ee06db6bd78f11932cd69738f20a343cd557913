import chokidar from 'chokidar';
import path from 'pathe';
import fs from 'fs-extra';
import pc from 'picocolors';
import { TEMP_PATH } from './alias.js';
import { addStory, removeStory } from './stories.js';
export class BasePluginApi {
    ctx;
    plugin;
    moduleLoader;
    colors = pc;
    path = path;
    fs = fs;
    // eslint-disable-next-line no-useless-constructor
    constructor(ctx, plugin, moduleLoader) {
        this.ctx = ctx;
        this.plugin = plugin;
        this.moduleLoader = moduleLoader;
    }
    get pluginTempDir() {
        return path.resolve(TEMP_PATH, 'plugins', this.plugin.name.replace(/:/g, '_'));
    }
    log(...msg) {
        console.log(this.colors.gray(`[Plugin:${this.plugin.name}]`), ...msg);
    }
    warn(...msg) {
        console.warn(this.colors.yellow(`[Plugin:${this.plugin.name}]`), ...msg);
    }
    error(...msg) {
        console.error(this.colors.red(`[Plugin:${this.plugin.name}]`), ...msg);
    }
    addStoryFile(file) {
        removeStory(file);
        addStory(file);
    }
    getStories() {
        return this.ctx.storyFiles.map(f => f.story).filter(Boolean);
    }
    getConfig() {
        return this.ctx.config;
    }
}
export class DevPluginApi extends BasePluginApi {
    watcher = chokidar;
}
export class BuildPluginApi extends BasePluginApi {
    changeViteConfigCallbacks = [];
    buildEndCallbacks = [];
    previewStoryCallbacks = [];
    changeViteConfig(cb) {
        this.changeViteConfigCallbacks.push(cb);
    }
    onBuildEnd(cb) {
        this.buildEndCallbacks.push(cb);
    }
    onPreviewStory(cb) {
        this.previewStoryCallbacks.push(cb);
    }
}
export class DevEventPluginApi extends BasePluginApi {
    event;
    payload;
    constructor(ctx, plugin, moduleLoader, event, payload) {
        super(ctx, plugin, moduleLoader);
        this.event = event;
        this.payload = payload;
    }
}
