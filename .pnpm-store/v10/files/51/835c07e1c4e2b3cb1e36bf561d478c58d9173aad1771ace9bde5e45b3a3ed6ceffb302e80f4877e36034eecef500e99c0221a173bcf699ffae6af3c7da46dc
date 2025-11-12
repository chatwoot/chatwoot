<script lang="ts" setup>
import type { Story, Tree, TreeFolder, TreeGroup, TreeLeaf } from '../../types'
import StoryListItem from './StoryListItem.vue'
import StoryListFolder from './StoryListFolder.vue'
import StoryGroup from './StoryGroup.vue'

defineProps<{
  tree: Tree
  stories: Story[]
}>()
</script>

<template>
  <div class="histoire-story-list htw-overflow-y-auto">
    <template
      v-for="element of tree"
      :key="element.title"
    >
      <StoryGroup
        v-if="(element as TreeGroup).group"
        :group="(element as TreeGroup)"
        :stories="stories"
      />
      <StoryListFolder
        v-else-if="(element as TreeFolder).children"
        :folder="(element as TreeFolder)"
        :stories="stories"
      />
      <StoryListItem
        v-else
        :story="stories[(element as TreeLeaf).index]"
      />
    </template>
  </div>
</template>
