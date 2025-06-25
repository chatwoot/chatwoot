<script setup>
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { ref } from 'vue';

defineProps({
  searchTerm: {
    type: [String, Number],
    default: '',
  },
  searchPlaceholder: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:searchTerm', 'focus', 'blur']);
const isFocused = ref(false);

const onChange = e => {
  emit('update:searchTerm', e.target.value);
};

const onFocus = e => {
  isFocused.value = true;
  emit('focus', e.target.value);
};

const onBlur = e => {
  isFocused.value = false;
  emit('blur', e.target.value);
};
</script>

<template>
  <div
    class="w-full flex items-center rounded-lg border-solid border h-12 bg-white dark:bg-slate-900 px-5 py-2 text-slate-600 dark:text-slate-200"
    :class="{
      'shadow border-woot-100 dark:border-woot-700': isFocused,
      'border-slate-50 dark:border-slate-800 shadow-sm': !isFocused,
    }"
  >
    <FluentIcon icon="search" />
    <input
      :value="searchTerm"
      type="text"
      class="w-full focus:outline-none text-base h-full bg-white dark:bg-slate-900 px-2 py-2 text-slate-700 dark:text-slate-100 placeholder-slate-500"
      :placeholder="searchPlaceholder"
      role="search"
      @input="onChange"
      @focus="onFocus"
      @blur="onBlur"
    />
  </div>
</template>
