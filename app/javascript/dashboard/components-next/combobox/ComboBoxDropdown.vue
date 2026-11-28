<script setup>
import { nextTick, ref, useId } from 'vue';
import { useI18n } from 'vue-i18n';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

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
  direction: {
    type: String,
    default: 'down',
    validator: value => ['up', 'down'].includes(value),
  },
  selectedValues: {
    type: [String, Number, Array],
    default: () => [],
  },
  keyboardNavigation: { type: Boolean, default: false },
  labelledBy: { type: String, default: '' },
  ariaLabel: { type: String, default: '' },
  loading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select', 'search', 'dismiss']);

const { t } = useI18n();

const searchValue = defineModel('searchValue', {
  type: String,
  default: '',
});

const searchInput = ref(null);
const listbox = ref(null);
const listboxId = useId();
const activeIndex = ref(-1);
const optionId = index => `${listboxId}-${index}`;

const handleSearchKey = event => {
  if (!props.keyboardNavigation || event.isComposing) return;

  if (event.key === 'Escape') {
    event.preventDefault();
    event.stopPropagation();
    emit('dismiss');
  } else if (event.key === 'Enter') {
    event.preventDefault();
    const option = props.options[Math.max(activeIndex.value, 0)];
    if (option) emit('select', option);
  } else if (['ArrowDown', 'ArrowUp'].includes(event.key)) {
    event.preventDefault();
    const lastIndex = props.options.length - 1;
    if (lastIndex < 0) return;

    if (event.key === 'ArrowDown') {
      activeIndex.value = Math.min(activeIndex.value + 1, lastIndex);
    } else {
      activeIndex.value =
        activeIndex.value < 0 ? lastIndex : Math.max(activeIndex.value - 1, 0);
    }

    nextTick(() => {
      listbox.value?.children[activeIndex.value]?.scrollIntoView?.({
        block: 'nearest',
      });
    });
  }
};

const isSelected = option => {
  if (Array.isArray(props.selectedValues)) {
    return props.selectedValues.includes(option.value);
  }
  return option.value === props.selectedValues;
};

const onInputSearch = event => {
  activeIndex.value = -1;
  searchValue.value = event.target.value;
  emit('search', event.target.value);
};

defineExpose({
  focus: () => {
    activeIndex.value = props.options.findIndex(isSelected);
    searchInput.value?.focus();
  },
});
</script>

<template>
  <div
    v-show="open"
    class="absolute z-50 w-full transition-opacity duration-200 border rounded-md shadow-lg bg-n-solid-1 border-n-strong"
    :class="direction === 'up' ? 'bottom-full mb-1' : 'mt-1'"
  >
    <div class="relative border-b border-n-strong">
      <Spinner
        v-if="loading"
        :size="16"
        class="absolute top-2.5 start-3 text-n-slate-11"
      />
      <Icon
        v-else
        icon="i-lucide-search"
        class="absolute top-2.5 size-4 start-3"
      />
      <input
        ref="searchInput"
        :value="searchValue"
        type="search"
        :role="keyboardNavigation ? 'combobox' : undefined"
        :aria-autocomplete="keyboardNavigation ? 'list' : undefined"
        :aria-controls="keyboardNavigation ? listboxId : undefined"
        :aria-expanded="keyboardNavigation ? open : undefined"
        :aria-labelledby="labelledBy || undefined"
        :aria-label="ariaLabel || undefined"
        :aria-activedescendant="
          keyboardNavigation && activeIndex >= 0 && options[activeIndex]
            ? optionId(activeIndex)
            : undefined
        "
        :placeholder="searchPlaceholder || t('COMBOBOX.SEARCH_PLACEHOLDER')"
        class="reset-base w-full py-2 !ps-10 !pe-2 text-sm focus:outline-none border-none rounded-t-md bg-n-solid-1 text-n-slate-12"
        @input="onInputSearch"
        @keydown="handleSearchKey"
      />
    </div>
    <ul
      :id="keyboardNavigation ? listboxId : undefined"
      ref="listbox"
      class="py-1 mb-0 overflow-auto max-h-60"
      role="listbox"
      :aria-multiselectable="multiple"
      :aria-labelledby="labelledBy || undefined"
    >
      <li
        v-for="(option, index) in options"
        :id="keyboardNavigation ? optionId(index) : undefined"
        :key="`${option.value}-${index}`"
        class="flex items-center justify-between w-full gap-2 px-3 py-2 text-sm transition-colors duration-150 cursor-pointer hover:bg-n-alpha-2"
        :class="{
          'bg-n-alpha-2':
            isSelected(option) || (keyboardNavigation && index === activeIndex),
        }"
        role="option"
        :aria-selected="isSelected(option)"
        @click.stop="emit('select', option)"
      >
        <span class="flex items-center min-w-0 gap-2">
          <Icon
            v-if="option.icon"
            :icon="option.icon"
            class="shrink-0 size-4 text-n-slate-11"
          />
          <span
            :class="{
              'font-medium': isSelected(option),
            }"
            class="text-n-slate-12"
          >
            {{ option.label }}
          </span>
        </span>
        <span
          v-if="isSelected(option)"
          class="flex-shrink-0 i-lucide-check size-4 text-n-slate-11"
        />
      </li>
      <li v-if="options.length === 0" class="px-3 py-2 text-sm text-n-slate-11">
        {{
          loading
            ? t('COMBOBOX.LOADING')
            : emptyState || t('COMBOBOX.EMPTY_STATE')
        }}
      </li>
    </ul>
  </div>
</template>
