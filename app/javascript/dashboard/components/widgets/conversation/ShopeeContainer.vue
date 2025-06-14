<script setup>
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import ShopeeOrders from './Shopee/Orders.vue';
import ShopeeVouchers from './Shopee/Vouchers.vue';
import ShopeeProducts from './Shopee/Products.vue';
</script>

<script>
export default {
  name: 'ShopeeContainer',
  components: {
    TabBar,
    ShopeeOrders,
    ShopeeVouchers,
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
      availableTabs: [
        {
          value: 'VOUCHER',
          label: this.$t('CONVERSATION.SHOPEE.TABS.VOUCHER'),
          count: 0,
        },
        {
          value: 'ORDER',
          label: this.$t('CONVERSATION.SHOPEE.TABS.ORDER'),
          count: 0,
        },
        {
          value: 'PRODUCT',
          label: this.$t('CONVERSATION.SHOPEE.TABS.PRODUCT'),
          count: 0,
        },
      ],
    };
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
  <div class="flex flex-col h-full">
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
