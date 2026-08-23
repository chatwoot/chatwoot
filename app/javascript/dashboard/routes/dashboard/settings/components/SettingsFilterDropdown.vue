<script setup>
import { computed, ref } from 'vue';
import { vOnClickOutside } from '@vueuse/components';

import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  modelValue: {
    type: [String, Number],
    default: 'all',
  },
  options: {
    type: Array,
    default: () => [],
  },
  icon: {
    type: String,
    default: '',
  },
  actionKey: {
    type: String,
    default: 'filter',
  },
});

const emit = defineEmits(['update:modelValue']);

const isOpen = ref(false);

const menuItems = computed(() =>
  props.options.map(option => ({
    ...option,
    action: props.actionKey,
    isSelected: option.value === props.modelValue,
  }))
);

const selectedLabel = computed(() => {
  const selected = menuItems.value.find(item => item.isSelected);
  return selected?.label || menuItems.value[0]?.label || '';
});

const close = () => {
  isOpen.value = false;
};

const toggle = () => {
  isOpen.value = !isOpen.value;
};

const handleAction = ({ value }) => {
  close();
  emit('update:modelValue', value);
};
</script>

<template>
  <div v-on-click-outside="close" class="relative">
    <Button
      :icon="icon || undefined"
      color="slate"
      size="sm"
      :class="{ 'bg-n-slate-9/10': isOpen }"
      @click="toggle"
    >
      <span class="min-w-0 truncate">{{ selectedLabel }}</span>
      <Icon icon="i-lucide-chevron-down" class="shrink-0 size-4" />
    </Button>
    <DropdownMenu
      v-if="isOpen"
      :menu-items="menuItems"
      class="mt-2 min-w-52 top-full ltr:left-0 rtl:right-0"
      @action="handleAction"
    />
  </div>
</template>
