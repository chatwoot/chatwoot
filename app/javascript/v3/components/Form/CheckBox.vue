<script setup>
import { computed } from 'vue';

const props = defineProps({
  isChecked: {
    type: Boolean,
    default: false,
  },
  value: {
    type: String,
    default: null,
  },
});

const emit = defineEmits(['update']);

const checked = computed({
  get: () => props.isChecked,
  set: value => emit('update', props.value, value),
});
</script>

<template>
  <input
    :id="value"
    v-model="checked"
    type="checkbox"
    :value="value"
    class="flex-shrink-0 mt-0.5 border-s-border-strong border bg-s-subtle checked:border-none checked:bg-s-brand shadow-sm appearance-none rounded-[4px] w-4 h-4 focus:ring-1 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center after:text-center after:text-xs after:font-bold after:relative"
  />
</template>
