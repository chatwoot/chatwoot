<template>
  <input
    :id="value"
    v-model="checked"
    type="checkbox"
    :value="value"
    class="flex-shrink-0 mt-0.5 border-ash-200 border bg-ash-50 checked:border-none checked:bg-primary-600 dark:checked:bg-primary-600 shadow-sm appearance-none rounded-[4px] w-4 h-4 focus:ring-1 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center after:text-center after:text-xs after:font-bold after:relative"
  />
</template>

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

const emit = defineEmits(['input']);

const checked = computed({
  get: () => props.isChecked,
  set: value => emit('update', props.value, value),
});
</script>
