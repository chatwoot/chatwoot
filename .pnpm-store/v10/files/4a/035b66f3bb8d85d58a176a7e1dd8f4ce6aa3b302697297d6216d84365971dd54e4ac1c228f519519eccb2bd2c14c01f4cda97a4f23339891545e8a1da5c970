export interface StoryFile {
  id: string
  supportPluginId: string
  component: any
  story: Story
  path: string[]
  filePath: string
  docsFilePath?: string
  source: () => Promise<{ default: string }>
}

export type StoryLayout = {
  type: 'single'
  iframe?: boolean
} | {
  type: 'grid'
  width?: number | string
}

export interface CommonProps {
  id?: string
  title?: string
  icon?: string
  iconColor?: string
}

export interface InheritedProps {
  setupApp?: (payload: any) => unknown
  source?: string
  responsiveDisabled?: boolean
  autoPropsDisabled?: boolean
}

export interface VariantProps extends CommonProps, InheritedProps {
  // No additional properties
}

export interface StoryProps extends CommonProps, InheritedProps {
  group?: string
  layout?: StoryLayout
  docsOnly?: boolean
}

export interface CommonMeta {}

export interface StoryMeta extends CommonMeta {}

export interface Story {
  id: string
  title: string
  group?: string
  variants: Variant[]
  layout?: StoryLayout
  icon?: string
  iconColor?: string
  docsOnly?: boolean
  file?: StoryFile
  lastSelectedVariant?: Variant
  slots?: () => any
  meta?: StoryMeta
}

export interface VariantMeta extends CommonMeta {}

export interface Variant {
  id: string
  title: string
  icon?: string
  iconColor?: string
  setupApp?: (payload: any) => unknown
  slots?: () => { default: any, controls: any, source: any }
  state: any
  source?: string
  responsiveDisabled?: boolean
  autoPropsDisabled?: boolean
  configReady?: boolean
  previewReady?: boolean
  meta?: VariantMeta
}

export interface PropDefinition {
  name: string
  types?: string[]
  required?: boolean
  default?: any
}

export interface AutoPropComponentDefinition {
  name: string
  index: number
  props: PropDefinition[]
}

/* SERVER */

export interface ServerStoryFile {
  id: string
  /**
   * Absolute path
   */
  path: string
  /**
   * Relative path
   */
  relativePath: string
  /**
   * File name without extension
   */
  fileName: string
  /**
   * Support plugin (Vue, Svelte, etc.)
   */
  supportPluginId: string
  /**
   * Generated path for tree UI
   */
  treePath?: string[]
  /**
   * Use the module id in imports to allow HMR
   */
  moduleId: string
  /**
   * Resolved story data from story file execution
   */
  story?: ServerStory
  /**
   * Data sent to user tree config functions
   */
  treeFile?: ServerTreeFile
  /**
   * Is virtual module
   */
  virtual?: boolean
  /**
   * Virtual module code
   */
  moduleCode?: string
  /**
   * Related markdown docs
   */
  markdownFile?: ServerMarkdownFile
}

export interface ServerMarkdownFile {
  id: string
  relativePath: string
  absolutePath: string
  isRelatedToStory: boolean
  frontmatter?: any
  html?: string
  content?: string
  storyFile?: ServerStoryFile
}

export interface ServerStory {
  id: string
  title: string
  group?: string
  variants: ServerVariant[]
  layout?: StoryLayout
  icon?: string
  iconColor?: string
  docsOnly?: boolean
  docsText?: string
  meta?: StoryMeta
}

export interface ServerVariant {
  id: string
  title: string
  icon?: string
  iconColor?: string
  meta?: VariantMeta
}

export interface ServerTreeFile {
  title: string
  path: string
}

export interface ServerTreeLeaf {
  title: string
  index: number
}

export interface ServerTreeFolder {
  title: string
  children: (ServerTreeFolder | ServerTreeLeaf)[]
}

export interface ServerTreeGroup {
  group: true
  id: string
  title: string
  children: (ServerTreeFolder | ServerTreeLeaf)[]
}

export type ServerTree = (ServerTreeGroup | ServerTreeFolder | ServerTreeLeaf)[]

export interface ServerRunPayload {
  file: ServerStoryFile
  storyData: ServerStory[]
  el: HTMLElement
}
