import type { Story, Variant } from '@histoire/shared'
import type { App, Component } from 'vue'

export interface Vue3StorySetupApi {
  app: App
  story?: Story
  variant?: Variant
  addWrapper: (wrapper: Component) => void
}

export type Vue3StorySetupHandler = (api: Vue3StorySetupApi) => Promise<void> | void

export function defineSetupVue3 (handler: Vue3StorySetupHandler): Vue3StorySetupHandler {
  return handler
}
