<script lang="ts" setup>
import type { Story, Variant } from '../../types'
import { isMobile } from '../../util/responsive'
import ToolbarTitle from '../toolbar/ToolbarTitle.vue'
import ToolbarResponsiveSize from '../toolbar/ToolbarResponsiveSize.vue'
import ToolbarBackground from '../toolbar/ToolbarBackground.vue'
import ToolbarTextDirection from '../toolbar/ToolbarTextDirection.vue'
import ToolbarNewTab from '../toolbar/ToolbarNewTab.vue'
import DevOnlyToolbarOpenInEditor from '../toolbar/DevOnlyToolbarOpenInEditor.vue'
import StoryVariantSinglePreviewNative from './StoryVariantSinglePreviewNative.vue'
import StoryVariantSinglePreviewRemote from './StoryVariantSinglePreviewRemote.vue'

defineProps<{
  variant: Variant
  story: Story
}>()
</script>

<template>
  <div
    class="histoire-story-variant-single-view htw-h-full htw-flex htw-flex-col"
    data-test-id="story-variant-single-view"
  >
    <!-- Toolbar -->
    <div
      v-if="!isMobile"
      class="htw-flex-none htw-flex htw-items-center htw-h-8 -htw-mt-1"
    >
      <ToolbarTitle
        :variant="variant"
      />
      <ToolbarResponsiveSize
        v-if="!variant.responsiveDisabled"
      />
      <ToolbarBackground />
      <ToolbarTextDirection />
      <ToolbarNewTab
        :variant="variant"
        :story="story"
      />

      <DevOnlyToolbarOpenInEditor
        v-if="__HISTOIRE_DEV__"
        :file="story.file?.filePath"
        tooltip="Edit story in editor"
      />
    </div>

    <!-- Preview -->
    <StoryVariantSinglePreviewNative
      v-if="story.layout?.iframe === false"
      :story="story"
      :variant="variant"
    />
    <StoryVariantSinglePreviewRemote
      v-else
      :story="story"
      :variant="variant"
    />
  </div>
</template>
