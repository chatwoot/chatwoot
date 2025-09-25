<script setup>
import { computed, ref } from 'vue';
import { vOnClickOutside } from '@vueuse/components';
import { useConfig } from 'dashboard/composables/useConfig';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  modelValue: {
    type: String,
    required: true,
  },
  placeholder: {
    type: String,
    default: 'Select language',
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  showSearch: {
    type: Boolean,
    default: false,
  },
  searchPlaceholder: {
    type: String,
    default: 'Search languages...',
  },
  showAllOption: {
    type: Boolean,
    default: true,
  },
  size: {
    type: String,
    default: 'md',
    validator: value => ['sm', 'md', 'lg'].includes(value),
  },
  variant: {
    type: String,
    default: 'outline',
    validator: value => ['outline', 'faded', 'ghost'].includes(value),
  },
});

const emit = defineEmits(['update:modelValue']);

const { enabledLanguages } = useConfig();
const isOpen = ref(false);

// Transform language options to DropdownMenu format
const menuItems = computed(() => {
  const languages = enabledLanguages || [
    { iso_639_1_code: 'en', name: 'English (en)' },
  ];

  const languageOptions = languages.map(lang => ({
    action: 'languageSelect',
    value: lang.iso_639_1_code,
    label: lang.name,
    isSelected: lang.iso_639_1_code === props.modelValue,
  }));

  if (props.showAllOption) {
    const allLanguagesOption = {
      action: 'languageSelect',
      value: '',
      label: props.placeholder,
      isSelected: props.modelValue === '',
    };
    return [allLanguagesOption, ...languageOptions];
  }

  return languageOptions;
});

const selectedLanguage = computed(() => {
  const selected = menuItems.value.find(
    item => item.value === props.modelValue
  );
  return selected ? selected.label : props.placeholder;
});

const handleAction = ({ value }) => {
  emit('update:modelValue', value);
  isOpen.value = false;
};

const toggleDropdown = () => {
  if (!props.disabled) {
    isOpen.value = !isOpen.value;
  }
};

const closeDropdown = () => {
  isOpen.value = false;
};

const buttonSizeClass = computed(() => {
  const sizes = {
    sm: 'h-8 px-3 text-sm',
    md: 'h-10 px-3 text-sm',
    lg: 'h-12 px-4 text-base',
  };
  return sizes[props.size];
});

const buttonVariantClass = computed(() => {
  const variants = {
    outline: 'border border-n-weak bg-n-solid-1 hover:bg-n-solid-2',
    faded: 'bg-n-alpha-2 hover:bg-n-alpha-3',
    ghost: 'hover:bg-n-alpha-1',
  };
  return variants[props.variant];
});
</script>

<template>
  <div v-on-click-outside="closeDropdown" class="relative w-full">
    <button
      type="button"
      :disabled="disabled"
      class="flex items-center justify-between gap-2 rounded-lg text-n-slate-12 transition-colors focus:outline-none focus:ring-2 focus:ring-n-blue-5 disabled:opacity-50 disabled:cursor-not-allowed w-full"
      :class="[buttonSizeClass, buttonVariantClass]"
      @click="toggleDropdown"
    >
      <span class="truncate">
        {{ selectedLanguage }}
      </span>
      <Icon
        icon="i-lucide-chevron-down"
        class="size-4 flex-shrink-0 transition-transform"
        :class="{ 'rotate-180': isOpen }"
      />
    </button>

    <DropdownMenu
      v-if="isOpen"
      :menu-items="menuItems"
      :show-search="showSearch"
      :search-placeholder="searchPlaceholder"
      class="top-full mt-1 left-0 right-0 w-full !max-h-[60vh] overflow-y-auto"
      @action="handleAction"
    />
  </div>
</template>
