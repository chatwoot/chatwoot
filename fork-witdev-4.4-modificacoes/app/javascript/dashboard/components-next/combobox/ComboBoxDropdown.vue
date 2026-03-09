<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  open: {
    type: Boolean,
    required: true,
  },
  options: {
    type: Array,
    required: true,
  },
  searchPlaceholder: {
    type: String,
    default: '',
  },
  emptyState: {
    type: String,
    default: '',
  },
  multiple: {
    type: Boolean,
    default: false,
  },
  selectedValues: {
    type: [String, Number, Array],
    default: () => [],
  },
});

const emit = defineEmits(['select', 'search']);

const { t } = useI18n();

const searchValue = defineModel('searchValue', {
  type: String,
  default: '',
});

const searchInput = ref(null);

const isSelected = option => {
  if (Array.isArray(props.selectedValues)) {
    return props.selectedValues.includes(option.value);
  }
  return option.value === props.selectedValues;
};

const onInputSearch = event => {
  searchValue.value = event.target.value;
  emit('search', event.target.value);
};

defineExpose({
  focus: () => searchInput.value?.focus(),
});
</script>

<template>
  <div
    v-show="open"
    class="absolute z-50 w-full mt-1 transition-opacity duration-200 border rounded-md shadow-lg bg-n-solid-1 border-n-strong"
  >
    <div class="relative border-b border-n-strong">
      <span class="absolute i-lucide-search top-2.5 size-4 left-3" />
      <input
        ref="searchInput"
        :value="searchValue"
        type="search"
        :placeholder="searchPlaceholder || t('COMBOBOX.SEARCH_PLACEHOLDER')"
        class="reset-base w-full py-2 pl-10 pr-2 text-sm focus:outline-none border-none rounded-t-md bg-n-solid-1 text-slate-900 dark:text-slate-50"
        @input="onInputSearch"
      />
    </div>
    <ul
      class="py-1 mb-0 overflow-auto max-h-60"
      role="listbox"
      :aria-multiselectable="multiple"
    >
      <li
        v-for="option in options"
        :key="option.value"
        class="flex items-center justify-between w-full gap-2 px-3 py-2 text-sm transition-colors duration-150 cursor-pointer hover:bg-n-alpha-2"
        :class="{
          'bg-n-alpha-2': isSelected(option),
        }"
        role="option"
        :aria-selected="isSelected(option)"
        @click="emit('select', option)"
      >
        <span
          :class="{
            'font-medium': isSelected(option),
          }"
          class="text-n-slate-12"
        >
          {{ option.label }}
        </span>
        <span
          v-if="isSelected(option)"
          class="flex-shrink-0 i-lucide-check size-4 text-n-slate-11"
        />
      </li>
      <li
        v-if="options.length === 0"
        class="px-3 py-2 text-sm text-slate-600 dark:text-slate-300"
      >
        {{ emptyState || t('COMBOBOX.EMPTY_STATE') }}
      </li>
    </ul>
  </div>
</template>
