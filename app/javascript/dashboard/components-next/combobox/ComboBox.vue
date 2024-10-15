<script setup>
import { nextTick, ref, computed, watch } from 'vue';
import { onClickOutside } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  options: {
    type: Array,
    required: true,
    validator: value =>
      value.every(option => 'value' in option && 'label' in option),
  },
  placeholder: {
    type: String,
    default: '',
  },
  modelValue: {
    type: [String, Number],
    default: '',
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  searchPlaceholder: {
    type: String,
    default: '',
  },
  emptyState: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();

const selectedValue = ref(props.modelValue);
const open = ref(false);
const search = ref('');
const searchInput = ref(null);
const comboboxRef = ref(null);

const filteredOptions = computed(() => {
  const searchTerm = search.value.toLowerCase();
  return props.options.filter(option =>
    option.label.toLowerCase().includes(searchTerm)
  );
});
const selectPlaceholder = computed(() => {
  return props.placeholder || t('COMBOBOX.PLACEHOLDER');
});
const selectedLabel = computed(() => {
  const selected = props.options.find(
    option => option.value === selectedValue.value
  );
  return selected?.label ?? selectPlaceholder.value;
});

const selectOption = option => {
  selectedValue.value = option.value;
  emit('update:modelValue', option.value);
  open.value = false;
  search.value = '';
};
const toggleDropdown = () => {
  open.value = !open.value;
  if (open.value) {
    search.value = '';
    nextTick(() => searchInput.value.focus());
  }
};

watch(
  () => props.modelValue,
  newValue => {
    selectedValue.value = newValue;
  }
);

onClickOutside(comboboxRef, () => {
  open.value = false;
});
</script>

<template>
  <div
    ref="comboboxRef"
    class="relative w-full"
    :class="{
      'cursor-not-allowed': disabled,
      'group/combobox': !disabled,
    }"
  >
    <Button
      variant="outline"
      :label="selectedLabel"
      icon-position="right"
      size="sm"
      :disabled="disabled"
      class="justify-between w-full text-slate-900 dark:text-slate-100 group-hover/combobox:border-slate-300 dark:group-hover/combobox:border-slate-600"
      :icon="open ? 'chevron-up' : 'chevron-down'"
      @click="toggleDropdown"
    />
    <div
      v-show="open"
      class="absolute z-50 w-full mt-1 transition-opacity duration-200 bg-white border rounded-md shadow-lg border-slate-200 dark:bg-slate-900 dark:border-slate-700/50"
    >
      <div class="relative border-b border-slate-100 dark:border-slate-700/50">
        <FluentIcon
          icon="search"
          :size="14"
          class="absolute text-gray-400 dark:text-slate-500 top-3 left-3"
          aria-hidden="true"
        />
        <input
          ref="searchInput"
          v-model="search"
          type="search"
          :placeholder="searchPlaceholder || t('COMBOBOX.SEARCH_PLACEHOLDER')"
          class="w-full py-2 pl-10 pr-2 text-sm bg-white border-none rounded-t-md dark:bg-slate-900 text-slate-900 dark:text-slate-50"
        />
      </div>
      <ul
        class="py-1 overflow-auto max-h-60"
        role="listbox"
        :aria-activedescendant="selectedValue"
      >
        <li
          v-for="option in filteredOptions"
          :key="option.value"
          class="flex items-center justify-between w-full gap-2 px-3 py-2 text-sm transition-colors duration-150 cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800/50"
          :class="{
            'bg-slate-50 dark:bg-slate-800/50': option.value === selectedValue,
          }"
          role="option"
          :aria-selected="option.value === selectedValue"
          @click="selectOption(option)"
        >
          <span :class="{ 'font-medium': option.value === selectedValue }">
            {{ option.label }}
          </span>
          <FluentIcon
            v-if="option.value === selectedValue"
            icon="checkmark"
            :size="16"
            class="flex-shrink-0"
            aria-hidden="true"
          />
        </li>
        <li
          v-if="filteredOptions.length === 0"
          class="px-3 py-2 text-sm text-slate-600 dark:text-slate-300"
        >
          {{ emptyState || t('COMBOBOX.EMPTY_STATE') }}
        </li>
      </ul>
    </div>
  </div>
</template>
