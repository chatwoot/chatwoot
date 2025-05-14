<script setup>
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import Icon from 'next/icon/Icon.vue';
import LoadingState from 'components/widgets/LoadingState.vue';
import EmptyMessage from 'components/widgets/EmptyMessage.vue';
import OrderCard from './OrderCard.vue';

const orders = useMapGetter('shopee/getOrders');
const { t } = useI18n();
</script>

<script>
export default {
  name: 'Orders',
  components: {
    Icon,
    LoadingState,
    EmptyMessage,
    OrderCard,
  },
  props: {
    currentChat: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      uiFlags: useMapGetter('shopee/getUIFlags'),
      startOfTabs: true,
      activeTabIndex: 0,
      availableTabs: [
        {
          value: 'ALL',
          label: this.$t('CONVERSATION.SHOPEE.ORDER.TABS.ALL'),
          count: 0,
        },
        {
          value: 'UNPAID',
          label: this.$t('CONVERSATION.SHOPEE.ORDER.TABS.UNPAID'),
          count: 0,
        },
        {
          value: 'PICKING',
          label: this.$t('CONVERSATION.SHOPEE.ORDER.TABS.PICKING'),
          count: 0,
        },
        {
          value: 'SHIPPING',
          label: this.$t('CONVERSATION.SHOPEE.ORDER.TABS.SHIPPING'),
          count: 0,
        },
        {
          value: 'DELIVERED',
          label: this.$t('CONVERSATION.SHOPEE.ORDER.TABS.DELIVERED'),
          count: 0,
        },
        {
          value: 'CANCELLED',
          label: this.$t('CONVERSATION.SHOPEE.ORDER.TABS.CANCELLED'),
          count: 0,
        },
        {
          value: 'RETURNED_REFUNDED',
          label: this.$t('CONVERSATION.SHOPEE.ORDER.TABS.RETURNED_REFUNDED'),
          count: 0,
        },
      ],
    };
  },
  mounted() {
    this.$store.dispatch('shopee/getOrders', {
      conversationID: this.currentChat.id,
    });
  },
  methods: {
    handleTabChange(selectedTab) {
      this.activeTabValue = selectedTab.value;
      this.activeTabIndex = this.availableTabs.indexOf(selectedTab);
      this.$store.dispatch('shopee/getOrders', {
        conversationID: this.currentChat.id,
        orderStatus: this.activeTabValue,
      });
    },
    handleGoStartTabs() {
      this.startOfTabs = true;
      this.orderTabsScroll(0);
    },
    handleGoEndTabs() {
      this.startOfTabs = false;
      this.orderTabsScroll(1000);
    },
    orderTabsScroll(left) {
      this.$refs.tabsContainer.querySelector('.tabs').scrollTo({
        behavior: 'smooth',
        left: left,
      });
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-full w-full">
    <div id="shopee-order-tabs" ref="tabsContainer">
      <a
        v-if="!startOfTabs"
        class="h-6 w-6 p-1 bg-white dark:bg-slate-900 text-center cursor-pointer border-r border-slate-100 dark:border-slate-700"
        @click="handleGoStartTabs"
      >
        <Icon icon="i-ri-contract-left-line" />
      </a>
      <TabBar
        class="bg-white"
        :tabs="availableTabs"
        :initial-active-tab="activeTabIndex"
        @tab-changed="handleTabChange"
      />
      <a
        v-if="startOfTabs"
        class="h-6 w-6 p-1 bg-white dark:bg-slate-900 text-center cursor-pointer border-l border-slate-100 dark:border-slate-700"
        @click="handleGoEndTabs"
      >
        <Icon icon="i-ri-contract-right-line" />
      </a>
    </div>
    <LoadingState v-if="uiFlags.isFetchingOrders" />
    <EmptyMessage
      v-else-if="orders.length === 0"
      :message="t('CONVERSATION.SHOPEE.ORDER.EMPTY_MESSAGE')"
    />
    <ul
      v-else
      class="bg-slate-50 dark:bg-slate-800 p-2 flex flex-col overflow-y-auto"
    >
      <li
        v-for="order in orders"
        :key="order.number"
        class="order w-full flex flex-col p-2 mb-2 bg-white rounded-md shadow-sm dark:bg-slate-900"
      >
        <OrderCard :order="order" />
      </li>
    </ul>
  </div>
</template>

<style lang="scss">
#shopee-order-tabs {
  @apply flex flex-none border-b border-n-weak bg-white dark:bg-slate-900;

  .tabs {
    @apply flex-auto h-6 px-0;
    @apply overflow-x-auto bg-n-alpha-1 rounded-none;
    scrollbar-width: none;
    -ms-overflow-style: none;

    button {
      @apply border-none border-0 outline-none rounded-none;
      @apply text-xs bg-white dark:bg-slate-900;
      @apply h-6 px-3 py-1;
      @apply overflow-visible;

      &:hover,
      &.active {
        @apply border-b border-solid;
        @apply dark:text-slate-100 dark:border-slate-100;
        @apply bg-white dark:bg-slate-800 text-orange-700 border-orange-700;
      }
    }
  }

  a {
    @apply flex-none;
  }

  .divider {
    @apply hidden;
  }
}
</style>
