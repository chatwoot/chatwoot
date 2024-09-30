<script setup>
import { ref, computed, watch } from 'vue';
import { onClickOutside } from '@vueuse/core';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';
import ButtonV4 from 'dashboard/playground/components/Button.vue';

const props = defineProps({
  options: {
    type: Array,
    required: true,
    validator: value =>
      value.every(option => 'value' in option && 'label' in option),
  },
  placeholder: {
    type: String,
    default: 'Select an option...',
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
    default: 'Search...',
  },
  emptyState: {
    type: String,
    default: 'No results found.',
  },
});

const emit = defineEmits(['update:modelValue']);

const selectedValue = ref(props.modelValue);

const open = ref(false);
const search = ref('');
const comboboxRef = ref(null);

const filteredOptions = computed(() => {
  const searchTerm = search.value.toLowerCase();
  return props.options.filter(option =>
    option.label.toLowerCase().includes(searchTerm)
  );
});

const selectedLabel = computed(() => {
  const selected = props.options.find(
    option => option.value === selectedValue.value
  );
  return selected?.label ?? props.placeholder;
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
    setTimeout(() => document.querySelector('input')?.focus(), 0);
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
    :class="{ 'cursor-not-allowed': disabled }"
  >
    <ButtonV4
      variant="outline"
      :label="selectedLabel"
      icon-position="right"
      size="sm"
      :disabled="disabled"
      class="justify-between w-full text-slate-900 dark:text-slate-100"
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
          v-model="search"
          type="search"
          :placeholder="searchPlaceholder"
          class="w-full py-2 pl-10 pr-2 text-sm border-none rounded-t-md"
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
          {{ emptyState }}
        </li>
      </ul>
    </div>
  </div>
</template>
