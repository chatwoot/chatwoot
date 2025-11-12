<script lang="ts" setup>
import { Icon } from '@iconify/vue'
import { computed, ref, withDefaults } from 'vue'
import { useRoute } from 'vue-router'
import BaseListItemLink from '../base/BaseListItemLink.vue'
import type { Story } from '../../types'
import { useScrollOnActive } from '../../util/scroll'

const props = withDefaults(defineProps<{
  story: Story
  depth?: number
}>(), {
  depth: 0,
})

const filePadding = computed(() => {
  return `${props.depth * 12}px`
})

const route = useRoute()
const isActive = computed(() => route.params.storyId === props.story.id)
const el = ref<HTMLDivElement>()
useScrollOnActive(isActive, el)
</script>

<template>
  <div
    ref="el"
    data-test-id="story-list-item"
    class="histoire-story-list-item"
  >
    <BaseListItemLink
      v-slot="{ active }"
      :to="{
        name: 'story',
        params: {
          storyId: story.id,
        },
      }"
      class="htw-pl-0.5 htw-pr-2 htw-py-2 md:htw-py-1.5 htw-mx-1 htw-rounded-sm"
    >
      <span class="bind-tree-margin htw-flex htw-items-center htw-gap-2 htw-pl-4 htw-min-w-0">
        <Icon
          :icon="story.icon ?? 'carbon:cube'"
          class="htw-w-5 htw-h-5 sm:htw-w-4 sm:htw-h-4 htw-flex-none"
          :class="{
            'htw-text-primary-500': !active && !story.iconColor,
            'bind-icon-color': !active && story.iconColor,
          }"
        />
        <span class="htw-truncate">{{ story.title }}</span>
      </span>

      <span
        v-if="!story.docsOnly"
        class="htw-opacity-40 htw-text-sm"
      >
        {{ story.variants.length }}
      </span>
    </BaseListItemLink>
  </div>
</template>

<style scoped>
.bind-tree-margin {
  margin-left: v-bind(filePadding);
}

.bind-icon-color {
  color: v-bind('story.iconColor');
}
</style>
