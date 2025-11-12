import type { RouteLocationRaw } from 'vue-router'

export type {
  StoryFile,
  StoryLayout,
  Story,
  Variant,
} from '@histoire/shared'

export interface TreeLeaf {
  title: string
  index: number
}

export interface TreeFolder {
  title: string
  children: (TreeFolder | TreeLeaf)[]
}

export interface TreeGroup {
  group: true
  id: string
  title: string
  children: (TreeFolder | TreeLeaf)[]
}

export type Tree = (TreeGroup | TreeFolder | TreeLeaf)[]

export type SearchResultType = 'title' | 'docs'

export interface SearchResultBase {
  kind: 'story' | 'variant' | 'command'
  rank: number
  id: string
  title: string
  path?: string[]
  icon?: string
  iconColor?: string
  type?: SearchResultType
}

export type SearchResult = SearchResultBase & ({
  route: RouteLocationRaw
} | {
  onActivate: () => unknown
})

export interface PreviewSettings {
  responsiveWidth: number
  responsiveHeight: number
  rotate: boolean
  backgroundColor: string
  checkerboard: boolean
  textDirection: 'ltr' | 'rtl'
}

declare module 'vue' {
  interface ComponentCustomProperties {
    __HISTOIRE_DEV__: boolean
  }
}

declare global {
  const __HISTOIRE_DEV__: boolean

  interface Window {
    __HST_PLUGIN_API__: {
      sendEvent: (event: string, payload: any) => Promise<any>
      openStory: (storyId: string) => void
    }
  }
}
