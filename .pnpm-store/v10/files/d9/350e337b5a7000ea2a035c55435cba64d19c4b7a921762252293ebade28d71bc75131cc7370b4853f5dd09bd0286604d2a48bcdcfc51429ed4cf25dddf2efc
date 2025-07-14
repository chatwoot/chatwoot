import { unindent } from '@histoire/shared'
import { clientSupportPlugins } from 'virtual:$histoire-support-plugins-client'
import type { Story, Variant } from '../types'

export async function getSourceCode(story: Story, variant: Variant) {
  if (variant.source) {
    return variant.source
  }
  else if (variant.slots?.().source) {
    const source = variant.slots?.().source()[0].children
    if (source) {
      return unindent(source)
    }
  }
  else {
    const clientPlugin = clientSupportPlugins[story.file?.supportPluginId]
    if (clientPlugin) {
      const pluginModule = await clientPlugin()
      return pluginModule.generateSourceCode(variant)
    }
  }

  const sourceLoader = story.file?.source
  if (sourceLoader) {
    return (await sourceLoader()).default
  }
}
