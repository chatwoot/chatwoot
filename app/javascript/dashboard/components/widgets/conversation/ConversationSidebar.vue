<script setup>
import { computed } from 'vue';
import ContactPanel from 'dashboard/routes/dashboard/conversation/ContactPanel.vue';
import ProductsSidebar from 'dashboard/components-next/Ecommerce/ProductsSidebar.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useWindowSize } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import wootConstants from 'dashboard/constants/globals';

defineProps({
  currentChat: {
    required: true,
    type: Object,
  },
});

const { uiSettings, updateUISettings } = useUISettings();
const { width: windowWidth } = useWindowSize();

const activeTab = computed(() => {
  const {
    is_contact_sidebar_open: isContactSidebarOpen,
    is_products_sidebar_open: isProductsSidebarOpen,
  } = uiSettings.value;

  if (isContactSidebarOpen) {
    return 'contact';
  }
  if (isProductsSidebarOpen) {
    return 'products';
  }
  return null;
});

const isSmallScreen = computed(
  () => windowWidth.value < wootConstants.SMALL_SCREEN_BREAKPOINT
);

const closeContactPanel = () => {
  if (
    isSmallScreen.value &&
    (uiSettings.value?.is_contact_sidebar_open ||
      uiSettings.value?.is_products_sidebar_open)
  ) {
    updateUISettings({
      is_contact_sidebar_open: false,
      is_copilot_panel_open: false,
      is_products_sidebar_open: false,
    });
  }
};
</script>

<template>
  <div
    v-on-click-outside="() => closeContactPanel()"
    class="bg-n-background h-full overflow-hidden flex flex-col fixed top-0 z-40 w-full max-w-sm transition-transform duration-300 ease-in-out ltr:right-0 rtl:left-0 md:static md:w-[320px] md:min-w-[320px] ltr:border-l rtl:border-r border-n-weak 2xl:min-w-[360px] 2xl:w-[360px] shadow-lg md:shadow-none"
    :class="[
      {
        'md:flex': activeTab,
        'md:hidden': !activeTab,
      },
    ]"
  >
    <div class="flex flex-1 overflow-auto">
      <ContactPanel
        v-show="activeTab === 'contact'"
        :conversation-id="currentChat.id"
        :inbox-id="currentChat.inbox_id"
      />
      <ProductsSidebar
        v-show="activeTab === 'products'"
        :conversation-id="currentChat.id"
      />
    </div>
  </div>
</template>
