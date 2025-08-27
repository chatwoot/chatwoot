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
        class="flex flex-wrap w-full gap-2 px-3 py-2.5 border rounded-lg cursor-pointer bg-n-alpha-black2 min-h-[42px] transition-all duration-500 ease-in-out"
        :class="{
          'border-n-ruby-8': hasError,
          'border-n-weak dark:border-n-weak hover:border-n-slate-6 dark:hover:border-n-slate-6':
            !hasError && !open,
          'border-n-brand': open,
          'cursor-not-allowed pointer-events-none opacity-50': disabled,
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
