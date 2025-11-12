import type path from 'pathe'
import type fs from 'fs-extra'
import type pc from 'picocolors'
import type chokidar from 'chokidar'
import type { InlineConfig as ViteInlineConfig } from 'vite'
import type { Awaitable } from '../type-utils.js'
import type {
  ServerStory,
  ServerStoryFile,
  ServerVariant,
} from './story.js'
import type {
  ConfigMode,
  HistoireConfig,
} from './config.js'
import type {
  PluginCommand,
} from './command.js'

export interface SupportPlugin {
  id: string
  moduleName: string
  setupFn: string | string[]
  importStoriesPrepend?: string
  importStoryComponent: (file: ServerStoryFile, index: number) => string
}

export interface FinalSupportPlugin extends SupportPlugin {
  // For now, no additional properties
}

export interface ModuleLoader {
  clearCache: () => void
  loadModule: (file: string) => Promise<any>
  destroy: () => void
}

export interface PluginApiBase {
  colors: typeof pc
  path: typeof path
  fs: typeof fs
  moduleLoader: ModuleLoader

  readonly pluginTempDir: string

  log: (...msg) => void
  warn: (...msg) => void
  error: (...msg) => void

  getStories: () => ServerStory[]
  addStoryFile: (file: string) => void

  getConfig: () => HistoireConfig
}

export interface PluginApiDev extends PluginApiBase {
  watcher: typeof chokidar
}

export type ChangeViteConfigCallback = (config: ViteInlineConfig) => Awaitable<void>
export type BuildEndCallback = () => Awaitable<void>
export type PreviewStoryCallback = (payload: { file: string, story: ServerStory, variant: ServerVariant, url: string }) => Awaitable<void>

export interface PluginApiBuild extends PluginApiBase {
  changeViteConfigCallbacks: ChangeViteConfigCallback[]
  buildEndCallbacks: BuildEndCallback[]
  previewStoryCallbacks: PreviewStoryCallback[]

  changeViteConfig: (cb: ChangeViteConfigCallback) => void
  onBuildEnd: (cb: BuildEndCallback) => void
  onPreviewStory: (cb: PreviewStoryCallback) => void
}

export interface PluginApiDevEvent extends PluginApiBase {
  event: string
  payload: any
}

export interface Plugin {
  /**
   * Name of the plugin
   */
  name: string
  /**
   * Modify histoire default config. The hook can either mutate the passed config or
   * return a partial config object that will be deeply merged into the existing
   * config. User config will have higher priority than default config.
   *
   * Note: User plugins are resolved before running this hook so injecting other
   * plugins inside  the `config` hook will have no effect.
   */
  defaultConfig?: (defaultConfig: HistoireConfig, mode: ConfigMode) => Partial<HistoireConfig> | null | void | Promise<Partial<HistoireConfig> | null | void>
  /**
   * Modify histoire config. The hook can either mutate the passed config or
   * return a partial config object that will be deeply merged into the existing
   * config.
   *
   * Note: User plugins are resolved before running this hook so injecting other
   * plugins inside  the `config` hook will have no effect.
   */
  config?: (config: HistoireConfig, mode: ConfigMode) => Partial<HistoireConfig> | null | void | Promise<Partial<HistoireConfig> | null | void>
  /**
   * Use this hook to read and store the final resolved histoire config.
   */
  configResolved?: (config: HistoireConfig) => Awaitable<void>
  /**
   * Use this hook to do processing during development. The `onCleanup` hook
   * should handle cleanup tasks when development server is closed.
   */
  onDev?: (api: PluginApiDev, onCleanup: (cb: () => Awaitable<void>) => void) => Awaitable<void>
  /**
   * Use this hook to do processing during production build.
   */
  onBuild?: (api: PluginApiBuild) => Awaitable<void>
  /**
   * Use this hook to do processing when preview is started.
   */
  onPreview?: () => Awaitable<void>
  /**
   * This plugin exposes a support plugin (example: Vue, Svelte, etc.)
   */
  supportPlugin?: SupportPlugin
  /**
   * This plugin exposes commands that can be executed from the search bar in development mode.
   */
  commands?: PluginCommand[]
  /**
   * Handle a custom event from the client in development mode.
   */
  onDevEvent?: (api: PluginApiDevEvent) => Awaitable<any>
}
