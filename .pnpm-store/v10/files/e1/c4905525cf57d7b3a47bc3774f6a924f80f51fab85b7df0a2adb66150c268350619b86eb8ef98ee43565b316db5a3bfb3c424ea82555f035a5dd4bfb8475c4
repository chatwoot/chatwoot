<script lang="ts">
export default {
  inheritAttrs: false,
}
</script>

<script lang="ts" setup>
import { clientSupportPlugins } from 'virtual:$histoire-support-plugins-client'
import { markRaw, ref, watchEffect } from 'vue'
import type { Story } from '../../types'

const props = defineProps<{
  story: Story
}>()

const mountComponent = ref(null)

watchEffect(async () => {
  const clientPlugin = clientSupportPlugins[props.story.file?.supportPluginId]
  if (clientPlugin) {
    try {
      const pluginModule = await clientPlugin()
      mountComponent.value = markRaw(pluginModule.RenderStory)
    }
    catch (e) {
      console.error(e)
      throw e
    }
  }
})
</script>

<template>
  <component
    :is="mountComponent"
    v-if="mountComponent"
    class="histoire-generic-render-story __histoire-render-story"
    :story="story"
    v-bind="$attrs"
  />
</template>
