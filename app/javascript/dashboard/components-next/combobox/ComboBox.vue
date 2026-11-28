<script setup>
import { ref, computed, watch, nextTick, useId } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useI18n } from 'vue-i18n';
import { matchesOptionSearch } from 'shared/helpers/languageSearch';

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
  // Fallback label shown when the selected value is not in `options` yet
  // (e.g. API-backed lists that load lazily on open).
  displayLabel: { type: String, default: '' },
  modelValue: { type: [String, Number], default: '' },
  disabled: { type: Boolean, default: false },
  allowDeselect: { type: Boolean, default: true },
  keyboardNavigation: { type: Boolean, default: false },
  labelledBy: { type: String, default: '' },
  triggerId: { type: String, default: '' },
  ariaLabel: { type: String, default: '' },
  searchPlaceholder: { type: String, default: '' },
  emptyState: { type: String, default: '' },
  message: { type: String, default: '' },
  hasError: { type: Boolean, default: false },
  loading: { type: Boolean, default: false },
  useApiResults: { type: Boolean, default: false }, // useApiResults prop to determine if search is handled by API
  // `up` opens the dropdown above the button, for comboboxes near the bottom of a page.
  direction: {
    type: String,
    default: 'down',
    validator: value => ['up', 'down'].includes(value),
  },
});

const emit = defineEmits(['update:modelValue', 'search', 'open']);

const { t } = useI18n();

const selectedValue = ref(props.modelValue);
const open = ref(false);
const search = ref('');
const dropdownRef = ref(null);
const triggerRef = ref(null);
const generatedId = useId();
const triggerId = computed(() => props.triggerId || generatedId);
const comboboxRef = ref(null);

const filteredOptions = computed(() => {
  // For API search, don't filter options locally
  if (props.useApiResults && search.value) {
    return props.options;
  }

  // For local search, filter options based on search term
  const searchTerm = search.value.toLowerCase();
  return props.options.filter(option =>
    matchesOptionSearch(option, searchTerm)
  );
});
const selectPlaceholder = computed(() => {
  return props.placeholder || t('COMBOBOX.PLACEHOLDER');
});
const selectedLabel = computed(() => {
  const selected = props.options.find(
    option => option.value === selectedValue.value
  );
  return selected?.label ?? (props.displayLabel || selectPlaceholder.value);
});

const closeDropdown = ({ restoreFocus = false } = {}) => {
  open.value = false;
  if (restoreFocus && props.keyboardNavigation) {
    triggerRef.value?.$el?.focus();
  }
};

const selectOption = option => {
  if (selectedValue.value !== option.value || props.allowDeselect) {
    selectedValue.value =
      selectedValue.value === option.value ? '' : option.value;
    emit('update:modelValue', selectedValue.value);
  }
  closeDropdown({ restoreFocus: true });
  search.value = '';
};

const dismissOnFocusLeave = event => {
  if (
    props.keyboardNavigation &&
    event.relatedTarget &&
    !comboboxRef.value?.contains(event.relatedTarget)
  ) {
    closeDropdown();
  }
};

const toggleDropdown = () => {
  if (props.disabled) return;
  open.value = !open.value;
  if (open.value) {
    search.value = '';
    emit('open');
    nextTick(() => dropdownRef.value?.focus());
  }
};

const openWithArrow = event => {
  if (!props.keyboardNavigation || open.value) return;
  event.preventDefault();
  toggleDropdown();
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
    @focusout="dismissOnFocusLeave"
  >
    <OnClickOutside @trigger="open = false">
      <Button
        :id="labelledBy || props.triggerId ? triggerId : undefined"
        ref="triggerRef"
        :type="keyboardNavigation ? 'button' : undefined"
        :aria-labelledby="labelledBy ? `${labelledBy} ${triggerId}` : undefined"
        :aria-label="ariaLabel ? `${ariaLabel}: ${selectedLabel}` : undefined"
        :aria-expanded="keyboardNavigation ? open : undefined"
        :aria-haspopup="keyboardNavigation ? 'listbox' : undefined"
        variant="outline"
        :color="hasError && !open ? 'ruby' : open ? 'blue' : 'slate'"
        :label="selectedLabel"
        trailing-icon
        :disabled="disabled"
        no-animation
        class="justify-between w-full !px-3 !py-2.5 text-n-slate-12 font-normal group-hover/combobox:border-n-slate-6 focus:outline-n-brand"
        :class="{
          focused: open,
          '[&:not(.focused)]:dark:outline-n-weak [&:not(.focused)]:hover:enabled:outline-n-slate-6 [&:not(.focused)]:dark:hover:enabled:outline-n-slate-6':
            !hasError,
        }"
        :icon="open ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
        @click="toggleDropdown"
        @keydown.down.up="openWithArrow"
      />

      <ComboBoxDropdown
        ref="dropdownRef"
        v-model:search-value="search"
        :open="open"
        :options="filteredOptions"
        :search-placeholder="searchPlaceholder"
        :empty-state="emptyState"
        :selected-values="selectedValue"
        :direction="direction"
        :loading="loading"
        :keyboard-navigation="keyboardNavigation"
        :labelled-by="labelledBy"
        :aria-label="ariaLabel"
        @search="emit('search', $event)"
        @select="selectOption"
        @dismiss="closeDropdown({ restoreFocus: true })"
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
