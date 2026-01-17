<script lang="ts" setup>
import { Icon } from '@iconify/vue'
import { computed } from 'vue'

const props = defineProps<{
  icon: string
}>()

const isUrl = computed(() => props.icon.startsWith('http') || props.icon.startsWith('data:image')
  || props.icon.startsWith('.') || props.icon.startsWith('/'))
</script>

<template>
  <img
    v-if="isUrl"
    :src="icon"
    :alt="icon"
    class="histoire-base-icon"
  >
  <Icon
    v-else
    :icon="icon"
    class="histoire-base-icon"
  />
</template>

<style scoped>
img.colorize-black {
  filter: grayscale(100) brightness(0);
}
</style>
