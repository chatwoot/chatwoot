<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
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
      <Button
        variant="outline"
        :color="hasError && !open ? 'ruby' : open ? 'blue' : 'slate'"
        :label="selectedLabel"
        trailing-icon
        :disabled="disabled"
        class="justify-between w-full !px-3 !py-2.5 text-n-slate-12 font-normal group-hover/combobox:border-n-slate-6 [&:not(.focused)]:hover:enabled:outline-n-slate-6 [&:not(.focused)]:dark:hover:enabled:outline-n-slate-6 [&:not(.focused)]:dark:outline-n-weak focus:outline-n-brand"
        :class="{ focused: open }"
        :icon="open ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
        @click="toggleDropdown"
      />

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
        class="mt-2 mb-0 text-xs truncate transition-all duration-500 ease-in-out"
        :class="{
          'text-n-ruby-9': hasError,
          'text-n-slate-11': !hasError,
        }"
      >
        {{ message }}
      </p>
    </OnClickOutside>
  </div>
</template>
