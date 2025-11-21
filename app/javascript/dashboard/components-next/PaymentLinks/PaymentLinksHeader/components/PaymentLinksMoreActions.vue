<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const emit = defineEmits(['export']);

const { t } = useI18n();

const paymentLinksMenuItems = [
  {
    label: t('PAYMENT_LINKS_LAYOUT.HEADER.ACTIONS.EXPORT'),
    action: 'export',
    value: 'export',
    icon: 'i-lucide-upload',
  },
];
const showActionsDropdown = ref(false);

const handlePaymentLinksAction = ({ action }) => {
  if (action === 'export') {
    emit('export');
  }
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
      :menu-items="paymentLinksMenuItems"
      class="ltr:right-0 rtl:left-0 mt-1 w-52 top-full"
      @action="handlePaymentLinksAction($event)"
    />
  </div>
</template>
