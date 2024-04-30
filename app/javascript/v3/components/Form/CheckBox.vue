<template>
  <input
    :id="id"
    v-model="selectedValue"
    type="checkbox"
    :value="value"
    class="flex-shrink-0 mt-0.5 border-ash-200 border checked:border-none checked:bg-primary-600 dark:checked:bg-primary-600 shadow appearance-none rounded-[4px] w-4 h-4 focus:ring-1 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center after:text-center after:text-xs after:font-bold after:relative"
  />
</template>

<script setup>
import { defineProps, defineEmits, computed } from 'vue';

const props = defineProps({
  id: {
    type: String,
    default: null,
  },
  model: {
    type: [String, Number, Boolean],
    default: null,
  },
  value: {
    type: [String, Number, Boolean],
    default: null,
  },
});

const emit = defineEmits(['input']);

const selectedValue = computed({
  get: () => props.model,
  set: value => {
    emit('update', props.id, value);
  },
});
</script>
