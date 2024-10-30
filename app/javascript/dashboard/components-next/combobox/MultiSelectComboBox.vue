<script setup>
import { ref, computed, watch, nextTick } from 'vue';
import { OnClickOutside } from '@vueuse/components';
import { useI18n } from 'vue-i18n';

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
const searchInput = ref(null);
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
    nextTick(() => searchInput.value?.focus());
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
        class="flex flex-wrap w-full gap-2 px-3 py-2.5 border rounded-lg cursor-pointer bg-n-alpha-black2 min-h-[42px]"
        :class="{
          'border-n-slate-7': open,
          'border-n-ruby-8': hasError,
          'border-n-slate-6': !hasError,
        }"
        @click="toggleDropdown"
      >
        <div
          v-for="tag in selectedTags"
          :key="tag.value"
          class="flex items-center justify-center max-w-full gap-1 px-2 py-0.5 rounded-lg bg-n-alpha-black1"
          @click.stop
        >
          <span class="flex-grow min-w-0 text-sm truncate text-n-slate-12">
            {{ tag.label }}
          </span>
          <span
            class="flex-shrink-0 cursor-pointer i-lucide-x size-3 text-n-slate-11"
            @click="removeTag(tag.value)"
          />
        </div>
        <span
          v-if="selectedTags.length === 0"
          class="flex items-center text-sm text-n-slate-11"
        >
          {{ selectPlaceholder }}
        </span>
      </div>

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
          :aria-multiselectable="true"
        >
          <li
            v-for="option in filteredOptions"
            :key="option.value"
            class="flex items-center justify-between w-full gap-2 px-3 py-2 text-sm transition-colors duration-150 cursor-pointer hover:bg-n-alpha-2"
            :class="{
              'bg-n-alpha-2': selectedValues.includes(option.value),
            }"
            role="option"
            :aria-selected="selectedValues.includes(option.value)"
            @click="toggleOption(option)"
          >
            <span
              :class="{
                'font-medium': selectedValues.includes(option.value),
              }"
            >
              {{ option.label }}
            </span>
            <span
              v-if="selectedValues.includes(option.value)"
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
