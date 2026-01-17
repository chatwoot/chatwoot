<script lang="ts" setup>
import { computed } from 'vue'
import type { Story, Variant } from '../../types'
import { isDark } from '../../util/dark'
import { histoireConfig } from '../../util/config'
import { usePreviewSettingsStore } from '../../stores/preview-settings'
import { getContrastColor } from '../../util/preview-settings'
import GenericRenderStory from './GenericRenderStory.vue'
import StoryResponsivePreview from './StoryResponsivePreview.vue'

const props = defineProps<{
  story: Story
  variant: Variant
}>()

Object.assign(props.variant, {
  previewReady: false,
})

function onReady() {
  Object.assign(props.variant, {
    previewReady: true,
  })
}

const settings = usePreviewSettingsStore().currentSettings

const contrastColor = computed(() => getContrastColor(settings))
const autoApplyContrastColor = computed(() => !!histoireConfig.autoApplyContrastColor)
</script>

<template>
  <StoryResponsivePreview
    v-slot="{ isResponsiveEnabled, finalWidth, finalHeight }"
    class="histoire-story-variant-single-preview-native"
    :variant="variant"
  >
    <div
      :style="[
        isResponsiveEnabled ? {
          width: finalWidth ? `${finalWidth}px` : '100%',
          height: finalHeight ? `${finalHeight}px` : '100%',
        } : { width: '100%', height: '100%' },
        {
          '--histoire-contrast-color': contrastColor,
          'color': autoApplyContrastColor ? contrastColor : undefined,
        },
      ]"
      class="htw-relative"
      data-test-id="sandbox-render"
    >
      <GenericRenderStory
        :key="`${story.id}-${variant.id}`"
        :variant="variant"
        :story="story"
        class="htw-h-full"
        :class="{
          [histoireConfig.sandboxDarkClass]: isDark, // @TODO remove
          [histoireConfig.theme.darkClass]: isDark,
        }"
        :dir="settings.textDirection"
        @ready="onReady"
      />
    </div>
  </StoryResponsivePreview>
</template>
