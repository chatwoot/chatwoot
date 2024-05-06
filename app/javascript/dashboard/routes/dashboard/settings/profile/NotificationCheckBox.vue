<template>
  <div
    class="flex items-start gap-2 px-0 text-sm tracking-[0.5] text-left rtl:text-right"
    :class="`col-span-${span}`"
  >
    <input
      v-model="localFlags"
      class="mt-1 flex-shrink-0 border-ash-200 border checked:border-none checked:bg-primary-600 dark:checked:bg-primary-600 shadow appearance-none rounded-[4px] w-4 h-4 focus:ring-1 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center after:text-center after:text-xs after:font-bold after:relative"
      type="checkbox"
      :value="localValue"
      @input="handleInput"
    />
  </div>
</template>

<script setup>
import { ref, watch } from 'vue';

const props = defineProps({
  value: {
    type: String,
    required: true,
  },
  span: {
    type: Number,
    default: 2,
  },
  selectedFlags: {
    type: Array,
    required: true,
  },
  type: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['input']);

const localValue = ref(props.value);
const localFlags = ref(props.selectedFlags);

watch(
  () => props.selectedFlags,
  newValue => {
    localFlags.value = newValue;
  }
);

const handleInput = e => {
  emit('input', props.type, e);
};
</script>
