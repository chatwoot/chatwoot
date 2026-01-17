<script lang="ts" setup>
import { defineAsyncComponent } from 'vue'
import { useCommandStore } from '../../stores/command.js'

const CommandPrompts = defineAsyncComponent(() => import('./CommandPrompts.vue'))

defineProps({
  shown: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits({
  close: () => true,
})

function close() {
  emit('close')
}

const commandStore = useCommandStore()
</script>

<template>
  <div
    v-if="shown"
    class="histoire-command-prompts-modal htw-fixed htw-inset-0 htw-bg-white/80 dark:htw-bg-gray-900/80 htw-z-20"
  >
    <div
      class="htw-absolute htw-inset-0"
      @click="close()"
    />
    <div class="htw-bg-white dark:htw-bg-gray-900 md:htw-mt-16 md:htw-mx-auto htw-w-screen htw-max-w-[512px] htw-max-h-[80vh] htw-overflow-y-auto htw-scroll-smooth htw-shadow-xl htw-border htw-border-gray-200 dark:htw-border-gray-750 htw-rounded-lg htw-relative htw-divide-y htw-divide-gray-200 dark:htw-divide-gray-850">
      <CommandPrompts
        :command="commandStore.selectedCommand"
        @close="close()"
      />
    </div>
  </div>
</template>
