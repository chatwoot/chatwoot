import chokidar from 'chokidar'
import path from 'pathe'
import fs from 'fs-extra'
import pc from 'picocolors'
import type {
  Plugin,
  PluginApiBase,
  PluginApiDev,
  PluginApiBuild,
  ChangeViteConfigCallback,
  BuildEndCallback,
  PreviewStoryCallback,
  ModuleLoader,
  ServerStory,
  PluginApiDevEvent,
  HistoireConfig,
} from '@histoire/shared'
import { TEMP_PATH } from './alias.js'
import type { Context } from './context.js'
import { addStory, removeStory } from './stories.js'

export class BasePluginApi implements PluginApiBase {
  colors = pc
  path = path
  fs = fs

  // eslint-disable-next-line no-useless-constructor
  constructor (
    protected ctx: Context,
    protected plugin: Plugin,
    public moduleLoader: ModuleLoader,
  ) { }

  get pluginTempDir () {
    return path.resolve(TEMP_PATH, 'plugins', this.plugin.name.replace(/:/g, '_'))
  }

  log (...msg) {
    console.log(this.colors.gray(`[Plugin:${this.plugin.name}]`), ...msg)
  }

  warn (...msg) {
    console.warn(this.colors.yellow(`[Plugin:${this.plugin.name}]`), ...msg)
  }

  error (...msg) {
    console.error(this.colors.red(`[Plugin:${this.plugin.name}]`), ...msg)
  }

  addStoryFile (file: string) {
    removeStory(file)
    addStory(file)
  }

  getStories (): ServerStory[] {
    return this.ctx.storyFiles.map(f => f.story).filter(Boolean)
  }

  getConfig (): HistoireConfig {
    return this.ctx.config
  }
}

export class DevPluginApi extends BasePluginApi implements PluginApiDev {
  watcher = chokidar
}

export class BuildPluginApi extends BasePluginApi implements PluginApiBuild {
  changeViteConfigCallbacks: ChangeViteConfigCallback[] = []
  buildEndCallbacks: BuildEndCallback[] = []
  previewStoryCallbacks: PreviewStoryCallback[] = []

  changeViteConfig (cb: ChangeViteConfigCallback) {
    this.changeViteConfigCallbacks.push(cb)
  }

  onBuildEnd (cb: BuildEndCallback) {
    this.buildEndCallbacks.push(cb)
  }

  onPreviewStory (cb: PreviewStoryCallback) {
    this.previewStoryCallbacks.push(cb)
  }
}

export class DevEventPluginApi extends BasePluginApi implements PluginApiDevEvent {
  constructor (
    ctx: Context,
    plugin: Plugin,
    moduleLoader: ModuleLoader,
    public event: string,
    public payload: any,
  ) {
    super(ctx, plugin, moduleLoader)
  }
}
