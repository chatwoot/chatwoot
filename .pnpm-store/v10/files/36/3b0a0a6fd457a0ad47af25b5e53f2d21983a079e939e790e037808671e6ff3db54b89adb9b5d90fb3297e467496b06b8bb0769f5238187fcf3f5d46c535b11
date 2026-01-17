<script lang="ts" setup>
import { Icon } from '@iconify/vue'
import { computed, withDefaults } from 'vue'
import type { Story, TreeGroup } from '../../types'
import { useFolderStore } from '../../stores/folder'
import StoryListItem from './StoryListItem.vue'
import StoryListFolder from './StoryListFolder.vue'

const props = withDefaults(defineProps<{
  path?: Array<string>
  group: TreeGroup
  stories: Story[]
}>(), {
  path: () => [],
})

const folderStore = useFolderStore()

const folderPath = computed(() => [...props.path, props.group.title])
const isFolderOpen = computed(() => folderStore.isFolderOpened(folderPath.value, true))

function toggleOpen() {
  folderStore.toggleFolder(folderPath.value, false)
}
</script>

<template>
  <div
    data-test-id="story-group"
    class="histoire-story-group htw-my-2 first:htw-mt-0 last:htw-mb-0 htw-group"
  >
    <template v-if="group.title">
      <div class="htw-h-[1px] htw-bg-gray-500/10 htw-mx-6 htw-mb-2 group-first:htw-hidden" />
      <div
        role="button"
        tabindex="0"
        class="htw-px-0.5 htw-py-2 md:htw-py-1.5 htw-mx-1 htw-rounded-sm hover:htw-bg-primary-100 dark:hover:htw-bg-primary-900 htw-cursor-pointer htw-select-none htw-flex htw-items-center htw-gap-2 htw-min-w-0 htw-opacity-50 hover:htw-opacity-100"
        @click="toggleOpen"
        @keyup.enter="toggleOpen"
        @keyup.space="toggleOpen"
      >
        <Icon
          :icon="isFolderOpen ? 'ri:subtract-line' : 'ri:add-line'"
          class="htw-w-4 htw-h-4 htw-ml-4 htw-rounded-sm htw-border htw-border-gray-500/40"
        />
        <span class="htw-truncate">{{ group.title }}</span>
      </div>
    </template>

    <!-- Children -->
    <div
      v-if="isFolderOpen"
    >
      <template
        v-for="element of group.children"
        :key="element.title"
      >
        <StoryListFolder
          v-if="(element as TreeFolder).children"
          :path="folderPath"
          :folder="(element as TreeFolder)"
          :stories="stories"
          :depth="0"
        />
        <StoryListItem
          v-else
          :story="stories[(element as TreeLeaf).index]"
          :depth="0"
        />
      </template>
    </div>
  </div>
</template>
