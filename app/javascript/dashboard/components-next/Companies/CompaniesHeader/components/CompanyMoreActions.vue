<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const emit = defineEmits(['create']);

const { t } = useI18n();
const showActionsDropdown = ref(false);

const menuItems = [
  {
    label: t('COMPANIES.ACTIONS.CREATE'),
    action: 'create',
    value: 'create',
    icon: 'i-lucide-plus',
  },
];

const handleAction = ({ action }) => {
  if (action === 'create') emit('create');
  showActionsDropdown.value = false;
};
</script>

<template>
  <div v-on-clickaway="() => (showActionsDropdown = false)" class="relative">
    <Button
      icon="i-lucide-ellipsis-vertical"
      color="slate"
      variant="ghost"
      size="sm"
      :class="showActionsDropdown ? 'bg-n-alpha-2' : ''"
      @click="showActionsDropdown = !showActionsDropdown"
    />
    <DropdownMenu
      v-if="showActionsDropdown"
      :menu-items="menuItems"
      class="ltr:right-0 rtl:left-0 mt-1 w-52 top-full"
      @action="handleAction($event)"
    />
  </div>
</template>
