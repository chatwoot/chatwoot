<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useI18n } from 'vue-i18n';

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
  message: {
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
</script>

<template>
  <div
    ref="comboboxRef"
    class="relative w-full min-w-0"
    :class="{
      'cursor-not-allowed': disabled,
      'group/combobox': !disabled,
    }"
  >
    <OnClickOutside @trigger="open = false">
      <Button
        variant="outline"
        color="slate"
        :label="selectedLabel"
        trailing-icon
        :disabled="disabled"
        class="justify-between w-full !px-3 !py-2.5 text-n-slate-12 font-normal group-hover/combobox:border-n-slate-6"
        :icon="open ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
        @click="toggleDropdown"
      />
      <div
        v-show="open"
        class="absolute z-50 w-full mt-1 transition-opacity duration-200 border rounded-md shadow-lg bg-n-solid-1 border-n-strong"
      >
        <div class="relative border-b border-n-strong">
          <span class="absolute i-lucide-search top-2.5 size-4 left-3" />
          <input
            ref="searchInput"
            v-model="search"
            type="search"
            :placeholder="searchPlaceholder || t('COMBOBOX.SEARCH_PLACEHOLDER')"
            class="w-full py-2 pl-10 pr-2 text-sm border-none rounded-t-md bg-n-solid-1 text-slate-900 dark:text-slate-50"
          />
        </div>
        <ul
          class="py-1 mb-0 overflow-auto max-h-60"
          role="listbox"
          :aria-activedescendant="selectedValue"
        >
          <li
            v-for="option in filteredOptions"
            :key="option.value"
            class="flex items-center justify-between !text-n-slate-12 w-full gap-2 px-3 py-2 text-sm transition-colors duration-150 cursor-pointer hover:bg-n-solid-2"
            :class="{
              'bg-n-solid-2': option.value === selectedValue,
            }"
            role="option"
            :aria-selected="option.value === selectedValue"
            @click="selectOption(option)"
          >
            <span :class="{ 'font-medium': option.value === selectedValue }">
              {{ option.label }}
            </span>
            <span
              v-if="option.value === selectedValue"
              class="flex-shrink-0 i-lucide-check size-4 text-n-slate-11"
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
      <p
        v-if="message"
        class="mt-2 mb-0 text-xs truncate transition-all duration-500 ease-in-out text-n-slate-11 dark:text-n-slate-11"
      >
        {{ message }}
      </p>
    </OnClickOutside>
  </div>
</template>
