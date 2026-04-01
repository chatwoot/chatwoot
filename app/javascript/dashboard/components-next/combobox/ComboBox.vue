<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useI18n } from 'vue-i18n';

import ComboBoxDropdown from 'dashboard/components-next/combobox/ComboBoxDropdown.vue';

const props = defineProps({
  options: {
    type: Array,
    required: true,
    validator: value =>
      value.every(option => 'value' in option && 'label' in option),
  },
  placeholder: { type: String, default: '' },
  modelValue: { type: [String, Number], default: '' },
  disabled: { type: Boolean, default: false },
  searchPlaceholder: { type: String, default: '' },
  emptyState: { type: String, default: '' },
  message: { type: String, default: '' },
  hasError: { type: Boolean, default: false },
  useApiResults: { type: Boolean, default: false }, // useApiResults prop to determine if search is handled by API
});

const emit = defineEmits(['update:modelValue', 'search']);

const { t } = useI18n();

const selectedValue = ref(props.modelValue);
const open = ref(false);
const search = ref('');
const dropdownRef = ref(null);
const comboboxRef = ref(null);

const filteredOptions = computed(() => {
  // For API search, don't filter options locally
  if (props.useApiResults && search.value) {
    return props.options;
  }

  // For local search, filter options based on search term
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
  if (props.disabled) return;
  open.value = !open.value;
  if (open.value) {
    search.value = '';
    nextTick(() => dropdownRef.value?.focus());
  }
};

watch(
  () => props.modelValue,
  newValue => {
    selectedValue.value = newValue;
  }
);
</script>

<template>
  <div
    ref="comboboxRef"
    class="relative w-full min-w-0"
    :class="{
      'cursor-not-allowed': disabled,
      'group/combobox': !disabled,
    }"
    @click.prevent
  >
    <OnClickOutside @trigger="open = false">
      <button
        type="button"
        :disabled="disabled"
        class="inline-flex h-10 w-full items-center justify-between gap-2 rounded-lg border border-solid bg-surface-container-lowest px-3 py-2.5 text-sm font-normal text-on-surface outline-none transition-all duration-200 ease-in-out focus:ring-1 focus:ring-offset-0 disabled:cursor-not-allowed disabled:opacity-50"
        :class="[
          open
            ? 'border-secondary ring-1 ring-secondary'
            : hasError
              ? 'border-error hover:border-error'
              : 'border-outline-variant/30 hover:border-outline-variant/50',
          { focused: open },
        ]"
        @click="toggleDropdown"
      >
        <span
          class="min-w-0 truncate"
          :class="
            selectedValue ? 'text-on-surface' : 'text-on-primary-container/70'
          "
        >
          {{ selectedLabel }}
        </span>
        <span
          :class="open ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
          class="size-4 shrink-0 text-on-primary-container"
        />
      </button>

      <ComboBoxDropdown
        ref="dropdownRef"
        v-model:search-value="search"
        :open="open"
        :options="filteredOptions"
        :search-placeholder="searchPlaceholder"
        :empty-state="emptyState"
        :selected-values="selectedValue"
        @search="emit('search', $event)"
        @select="selectOption"
      />

      <p
        v-if="message"
        class="mb-0 mt-1 min-w-0 truncate text-xs transition-all duration-500 ease-in-out"
        :class="{
          'text-n-ruby-9 dark:text-n-ruby-9': hasError,
          'text-n-slate-11 dark:text-n-slate-11': !hasError,
        }"
      >
        {{ message }}
      </p>
    </OnClickOutside>
  </div>
</template>
