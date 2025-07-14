<script lang="ts">
export default {
  name: 'HstCheckbox',
}
</script>

<script lang="ts" setup>
import { computed } from 'vue'
import HstWrapper from '../HstWrapper.vue'
import HstSimpleCheckbox from './HstSimpleCheckbox.vue'

type Booleanish = boolean | 'true' | 'false'

const props = defineProps<{
  modelValue?: Booleanish
  title?: string
}>()

const emit = defineEmits({
  'update:modelValue': (newValue: Booleanish) => true,
})

function toggle() {
  if (typeof props.modelValue === 'string') {
    emit('update:modelValue', props.modelValue === 'false' ? 'true' : 'false')
    return
  }

  emit('update:modelValue', !props.modelValue)
}

const isTrue = computed(() => {
  if (typeof props.modelValue === 'string') {
    return props.modelValue !== 'false'
  }

  return props.modelValue
})
</script>

<template>
  <HstWrapper
    role="checkbox"
    tabindex="0"
    class="histoire-checkbox htw-cursor-pointer htw-items-center"
    :title="title"
    @click="toggle()"
    @keydown.enter.prevent="toggle()"
    @keydown.space.prevent="toggle()"
  >
    <HstSimpleCheckbox :model-value="isTrue" />
    <template #actions>
      <slot name="actions" />
    </template>
  </HstWrapper>
</template>
