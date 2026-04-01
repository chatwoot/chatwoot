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
  placeholder: {
    type: String,
    default: '',
  },
  modelValue: {
    type: Array,
    default: () => [],
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
  message: {
    type: String,
    default: '',
  },
  hasError: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();

const selectedValues = ref(props.modelValue);
const open = ref(false);
const search = ref('');
const dropdownRef = ref(null);
const comboboxRef = ref(null);

const filteredOptions = computed(() => {
  const searchTerm = search.value.toLowerCase();
  return props.options.filter(option =>
    option.label?.toLowerCase().includes(searchTerm)
  );
});

const selectPlaceholder = computed(() => {
  return props.placeholder || t('COMBOBOX.PLACEHOLDER');
});

const selectedTags = computed(() => {
  return selectedValues.value.map(value => {
    const option = props.options.find(opt => opt.value === value);
    return option || { value, label: value };
  });
});

const toggleOption = option => {
  const index = selectedValues.value.indexOf(option.value);
  if (index === -1) {
    selectedValues.value.push(option.value);
  } else {
    selectedValues.value.splice(index, 1);
  }
  emit('update:modelValue', selectedValues.value);
};

const removeTag = value => {
  const index = selectedValues.value.indexOf(value);
  if (index !== -1) {
    selectedValues.value.splice(index, 1);
    emit('update:modelValue', selectedValues.value);
  }
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
    selectedValues.value = newValue;
  }
);

defineExpose({
  toggleDropdown,
  open,
  disabled: props.disabled,
});
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
      <div
        class="flex min-h-[42px] w-full cursor-pointer flex-wrap gap-2 rounded-lg border border-solid bg-surface-container-lowest px-3 py-2.5 transition-all duration-200 ease-in-out"
        :class="{
          'border-error hover:border-error': hasError && !open,
          'border-outline-variant/30 hover:border-outline-variant/50':
            !hasError && !open,
          'border-secondary ring-1 ring-secondary': open,
          'cursor-not-allowed pointer-events-none opacity-50': disabled,
        }"
        @click="toggleDropdown"
      >
        <div
          v-for="tag in selectedTags"
          :key="tag.value"
          class="flex max-w-full items-center justify-center gap-1 rounded-lg bg-surface-container-high px-2 py-0.5 ring-1 ring-inset ring-outline-variant/20"
          @click.stop
        >
          <span class="min-w-0 flex-grow truncate text-sm text-on-surface">
            {{ tag.label }}
          </span>
          <span
            class="i-lucide-x size-3 flex-shrink-0 cursor-pointer text-on-surface-variant hover:text-on-surface"
            @click="removeTag(tag.value)"
          />
        </div>
        <span
          v-if="selectedTags.length === 0"
          class="flex items-center text-sm text-on-primary-container/70"
        >
          {{ selectPlaceholder }}
        </span>
      </div>

      <ComboBoxDropdown
        ref="dropdownRef"
        :open="open"
        :options="filteredOptions"
        :search-value="search"
        :search-placeholder="searchPlaceholder"
        :empty-state="emptyState"
        multiple
        :selected-values="selectedValues"
        @update:search-value="search = $event"
        @select="toggleOption"
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
