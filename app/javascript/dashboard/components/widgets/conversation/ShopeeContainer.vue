<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';

import { INBOX_TYPES } from 'dashboard/helper/inbox';
import SidebarActionsHeader from 'dashboard/components-next/SidebarActionsHeader.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import ShopeeOrders from './Shopee/Orders.vue';
import ShopeeVouchers from './Shopee/Vouchers.vue';
import ShopeeProducts from './Shopee/Products.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';

const store = useStore();
const { t } = useI18n();
const { uiSettings, updateUISettings } = useUISettings();

const currentChat = computed(() => store.getters.getSelectedChat);
const activeTabIndex = ref(0);
const activeTabValue = ref('VOUCHER');

const availableTabs = ref([
  {
    value: 'VOUCHER',
    label: t('CONVERSATION.SHOPEE.TABS.VOUCHER'),
    count: 0,
  },
  {
    value: 'ORDER',
    label: t('CONVERSATION.SHOPEE.TABS.ORDER'),
    count: 0,
  },
  {
    value: 'PRODUCT',
    label: t('CONVERSATION.SHOPEE.TABS.PRODUCT'),
    count: 0,
  },
]);

const handleTabChange = selectedTab => {
  activeTabValue.value = selectedTab.value;
  activeTabIndex.value = availableTabs.value.findIndex(
    tab => tab.value === selectedTab.value
  );
};

const closeShopeePanel = () => {
  updateUISettings({
    is_copilot_panel_open: false,
    is_contact_sidebar_open: false,
    is_shopee_panel_open: false,
  });
};

const channelType = computed(() => {
  return currentChat.value?.channel || currentChat.value?.meta?.channel || '';
});

const shouldShowShopeePanel = computed(() => {
  const isShopeePanelOpen = uiSettings.value?.is_shopee_panel_open;
  return isShopeePanelOpen && channelType.value === INBOX_TYPES.SHOPEE;
});
</script>

<template>
  <div
    v-if="shouldShowShopeePanel"
    class="ltr:border-l rtl:border-r border-n-weak h-full overflow-hidden z-10 w-[320px] min-w-[320px] 2xl:min-w-[360px] 2xl:w-[360px] flex flex-col bg-n-background"
  >
    <div class="flex flex-col h-full">
      <SidebarActionsHeader
        :title="$t('CONVERSATION.SIDEBAR.SHOPEE')"
        @close="closeShopeePanel"
      />
      <div id="shopee-tabs" class="flex-1">
        <TabBar
          class="bg-white"
          :tabs="availableTabs"
          :initial-active-tab="activeTabIndex"
          @tab-changed="handleTabChange"
        />
      </div>
      <div class="flex-auto overflow-y-auto h-full w-full">
        <ShopeeVouchers
          v-if="activeTabValue === 'VOUCHER'"
          :current-chat="currentChat"
        />
        <ShopeeOrders
          v-if="activeTabValue === 'ORDER'"
          :current-chat="currentChat"
        />
        <ShopeeProducts
          v-if="activeTabValue === 'PRODUCT'"
          :current-chat="currentChat"
        />
      </div>
    </div>
  </div>
</template>

<style lang="scss">
#shopee-tabs {
  @apply flex-none border-b border-n-weak bg-white dark:bg-slate-900;

  .tabs {
    @apply bg-white dark:bg-slate-900 p-0;
  }

  .divider {
    @apply hidden;
  }

  button {
    @apply border-none border-0 outline-none rounded-none;
    @apply dark:bg-slate-900;

    &.active {
      @apply border-woot-600 border-b border-solid;
    }
  }
}
</style>
