<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const modelValue = defineModel({ type: String, default: '30' });

const { t } = useI18n();
const [showDropdown, toggleDropdown] = useToggle();

const DAY_RANGES = ['7', '30', '90'];

const decorate = item => ({
  ...item,
  action: 'select',
  isSelected: item.value === modelValue.value,
});

const menuSections = computed(() => {
  const dayItems = DAY_RANGES.map(value =>
    decorate({
      value,
      label: t('CAPTAIN.OVERVIEW.RANGES.LAST_DAYS', { count: value }),
    })
  );
  const monthItems = [
    decorate({
      value: 'this_month',
      label: t('CAPTAIN.OVERVIEW.RANGES.THIS_MONTH'),
    }),
    decorate({
      value: 'last_month',
      label: t('CAPTAIN.OVERVIEW.RANGES.LAST_MONTH'),
    }),
  ];
  return [{ items: dayItems }, { items: monthItems }];
});

const menuItems = computed(() =>
  menuSections.value.flatMap(section => section.items)
);

const selectedLabel = computed(
  () => menuItems.value.find(item => item.isSelected)?.label || ''
);

const handleAction = ({ value }) => {
  toggleDropdown(false);
  modelValue.value = value;
};
</script>

<template>
  <div
    v-on-click-outside="() => toggleDropdown(false)"
    class="relative flex items-center group"
  >
    <Button
      sm
      slate
      faded
      trailing-icon
      icon="i-lucide-chevron-down"
      :label="selectedLabel"
      class="rounded-md group-hover:bg-n-alpha-2"
      @click="toggleDropdown()"
    />
    <DropdownMenu
      v-if="showDropdown"
      :menu-sections="menuSections"
      class="mt-1 ltr:right-0 rtl:left-0 top-full"
      @action="handleAction($event)"
    />
  </div>
</template>
