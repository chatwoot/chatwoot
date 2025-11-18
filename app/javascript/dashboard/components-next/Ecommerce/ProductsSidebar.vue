<script setup>
import { computed } from 'vue';
import SidebarActionsHeader from 'dashboard/components-next/SidebarActionsHeader.vue';
import ProductsList from './ProductsList.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { updateUISettings } = useUISettings();

const closeProductsSidebar = () => {
  updateUISettings({
    is_products_sidebar_open: false,
  });
};
</script>

<template>
  <div class="flex flex-col h-full w-full bg-n-solid-1">
    <SidebarActionsHeader
      :title="$t('CONVERSATION.SIDEBAR.PRODUCTS')"
      @close="closeProductsSidebar"
    />
    <ProductsList :conversation-id="conversationId" />
  </div>
</template>
