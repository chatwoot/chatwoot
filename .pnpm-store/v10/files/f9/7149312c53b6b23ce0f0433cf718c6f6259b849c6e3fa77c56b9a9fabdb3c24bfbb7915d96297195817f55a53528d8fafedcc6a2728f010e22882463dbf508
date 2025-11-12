<script lang="ts">
export default {
  name: 'HstText',
}
</script>

<script lang="ts" setup>
import { ref } from 'vue'
import HstWrapper from '../HstWrapper.vue'

defineProps<{
  title?: string
  modelValue?: string
}>()

const emit = defineEmits({
  'update:modelValue': (newValue: string) => true,
})

const input = ref<HTMLInputElement>()
</script>

<template>
  <HstWrapper
    :title="title"
    class="histoire-text htw-cursor-text htw-items-center"
    :class="$attrs.class"
    :style="$attrs.style"
    @click="input.focus()"
  >
    <input
      ref="input"
      v-bind="{ ...$attrs, class: null, style: null }"
      type="text"
      :value="modelValue"
      class="htw-text-inherit htw-bg-transparent htw-w-full htw-outline-none htw-px-2 htw-py-1 -htw-my-1 htw-border htw-border-solid htw-border-black/25 dark:htw-border-white/25 focus:htw-border-primary-500 dark:focus:htw-border-primary-500 htw-rounded-sm"
      @input="emit('update:modelValue', ($event.target as HTMLInputElement).value)"
    >

    <template #actions>
      <slot name="actions" />
    </template>
  </HstWrapper>
</template>
