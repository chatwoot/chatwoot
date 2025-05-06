<script setup>
import { useI18n } from 'vue-i18n';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import ShopeeVouchers from './Shopee/Vouchers.vue';
import ShopeeOrders from './Shopee/Orders.vue';
import ShopeeProducts from './Shopee/Products.vue';
</script>

<script>
export default {
  name: 'ShopeeContainer',
  components: {
    TabBar,
    ShopeeVouchers,
    ShopeeOrders,
    ShopeeProducts,
  },
  props: {
    currentChat: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      activeTabIndex: 0,
      activeTabValue: 'VOUCHER',
      tabs: ['VOUCHER', 'ORDER', 'PRODUCT'],
    };
  },
  computed: {
    availableTabs() {
      return this.tabs.map(tab => ({
        value: tab,
        label: useI18n().t(`CONVERSATION.SHOPEE.TABS.${tab}`),
        count: 0,
      }));
    },
  },
  methods: {
    handleTabChange(selectedTab) {
      this.activeTabValue = selectedTab.value;
      this.activeTabIndex = this.availableTabs.indexOf(selectedTab);
    },
  },
};
</script>

<template>
  <div
    class="ltr:border-l rtl:border-r border-n-weak h-full z-10 w-80 min-w-80 2xl:min-w-96 2xl:w-96 flex flex-col"
  >
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
</template>

<style lang="scss">
#shopee-tabs {
  @apply flex-none border-b border-n-weak bg-white dark:bg-slate-900;

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
