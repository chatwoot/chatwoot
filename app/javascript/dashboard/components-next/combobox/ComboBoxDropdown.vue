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
    class="absolute z-50 w-full mt-1 transition-opacity duration-200 border rounded-md shadow-lg bg-s-surface border-s-border-strong"
  >
    <div class="relative border-b border-s-border-strong">
      <span class="absolute i-lucide-search top-2.5 size-4 left-3" />
      <input
        ref="searchInput"
        :value="searchValue"
        type="search"
        :placeholder="searchPlaceholder || t('COMBOBOX.SEARCH_PLACEHOLDER')"
        class="reset-base w-full py-2 pl-10 pr-2 text-sm focus:outline-none border-none rounded-t-md bg-s-surface text-s-primary"
        @input="onInputSearch"
      />
    </div>
    <ul
      class="py-1 mb-0 overflow-auto max-h-60"
      role="listbox"
      :aria-multiselectable="multiple"
    >
      <li
        v-for="(option, index) in options"
        :key="`${option.value}-${index}`"
        class="flex items-center justify-between w-full gap-2 px-3 py-2 text-sm transition-colors duration-150 cursor-pointer hover:bg-s-subtle"
        :class="{
          'bg-s-subtle': isSelected(option),
        }"
        role="option"
        :aria-selected="isSelected(option)"
        @click="emit('select', option)"
      >
        <span
          :class="{
            'font-medium': isSelected(option),
          }"
          class="text-s-primary"
        >
          {{ option.label }}
        </span>
        <span
          v-if="isSelected(option)"
          class="flex-shrink-0 i-lucide-check size-4 text-s-muted"
        />
      </li>
      <li v-if="options.length === 0" class="px-3 py-2 text-sm text-s-muted">
        {{ emptyState || t('COMBOBOX.EMPTY_STATE') }}
      </li>
    </ul>
  </div>
</template>
