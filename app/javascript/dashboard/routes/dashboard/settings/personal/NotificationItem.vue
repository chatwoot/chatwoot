<template>
  <div
    class="flex items-center gap-2 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
    :class="`col-span-${span}`"
  >
    <input
      v-model="localFlags"
      class="m-0 border-[1.5px] checked:bg-primary-600 shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
      type="checkbox"
      :value="localValue"
      @input="handleInput"
    />
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import { defineProps } from 'vue';

const props = defineProps({
  value: {
    type: String,
    required: true,
  },
  span: {
    type: Number,
    default: 2,
  },
  selectedEmailFlags: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['input']);

const localValue = ref(props.value);
const localFlags = computed(() => props.selectedEmailFlags);

const handleInput = e => {
  emit('input', e);
};
</script>
