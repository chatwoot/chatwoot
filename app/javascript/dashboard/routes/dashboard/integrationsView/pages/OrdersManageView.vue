<template>
  <div
    class="flex justify-between flex-col h-full m-0 flex-1 bg-white dark:bg-slate-900"
  >
    <settings-header
      button-route="new"
      :header-title="order.order_number"
      show-back-button
      :back-button-label="$t('ORDER_DETAILS.BACK_BUTTON')"
      :back-url="backUrl"
      :show-new-button="false"
    >
      {{ $t('ORDER_DETAILS.TITLE') }}
    </settings-header>

    <div v-if="uiFlags.isFetchingItem" class="text-center p-4 text-base h-full">
      <spinner size="" />
      <span>{{ $t('CONTACT_PROFILE.LOADING') }}</span>
    </div>
    <div v-else-if="order.id" class="overflow-hidden flex-1 min-w-0">
      <div class="flex flex-wrap ml-auto mr-auto max-w-full h-full">
        <contact-info-panel :show-close-button="false" :contact="contact" />
        <div class="w-3/4 h-full">
          <woot-tabs :index="selectedTabIndex" @change="onClickTabChange">
            <woot-tabs-item
              v-for="tab in tabs"
              :key="tab.key"
              :name="tab.name"
              :show-badge="false"
            />
          </woot-tabs>
          <div
            class="bg-slate-25 dark:bg-slate-800 h-[calc(100%-40px)] p-4 overflow-auto"
          >
            <div class="flex flex-col gap-4" v-if="selectedTabIndex === 0">
              <general-info-card :order="order" />
              <order-items-card :items="order.order_items" />
              <shipping-info-card :order="order" />
              <order-values-info-card :order="order" />
              <order-payment-card :order="order" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import ContactInfoPanel from 'dashboard/routes/dashboard/contacts/components/ContactInfoPanel.vue';
import SettingsHeader from '../../settings/SettingsHeader.vue';
import Spinner from 'shared/components/Spinner.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import GeneralInfoCard from '../components/GeneralInfoCard.vue';
import OrderItemsCard from '../components/OrderItemsCard.vue';
import ShippingInfoCard from '../components/ShippingInfoCard.vue';
import OrderValuesInfoCard from '../components/OrderValuesInfoCard.vue';
import OrderPaymentCard from '../components/OrderPaymentCard.vue';

export default {
  components: {
    ContactInfoPanel,
    SettingsHeader,
    Spinner,
    Thumbnail,
    GeneralInfoCard,
    OrderItemsCard,
    ShippingInfoCard,
    OrderValuesInfoCard,
    OrderPaymentCard,
  },
  props: {
    orderId: {
      type: [String, Number],
      required: true,
    },
  },
  data() {
    return {
      selectedTabIndex: 0,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'integrationsView/getUIFlags',
    }),
    tabs() {
      return [
        {
          key: 0,
          name: this.$t('ORDERS_PAGE.TITLE'),
        },
      ];
    },
    showEmptySearchResult() {
      const hasEmptyResults = !!this.searchQuery && this.records.length === 0;
      return hasEmptyResults;
    },
    order() {
      return this.$store.getters['integrationsView/getOrder'](this.orderId);
    },

    contact() {
      const dateToTimestamp = date => {
        const timestampDate = new Date(date);
        const timestamp = Math.floor(timestampDate.getTime() / 1000);
        return timestamp;
      };
      const newContact = {
        ...this.order.contact,
        created_at: dateToTimestamp(this.order.contact.created_at),
        updated_at: dateToTimestamp(this.order.contact.updated_at),
      };
      return newContact;
    },
    backUrl() {
      return `/app/accounts/${this.$route.params.accountId}/integrations-view`;
    },
  },
  mounted() {
    this.fetchOrderDetails();
  },
  methods: {
    onClickTabChange(index) {
      this.selectedTabIndex = index;
    },
    fetchOrderDetails() {
      const { orderId: id } = this;
      this.$store.dispatch('integrationsView/show', { id });
    },
  },
};
</script>
