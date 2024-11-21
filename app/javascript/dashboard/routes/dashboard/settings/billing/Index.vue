<script>
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

import { mapGetters } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';
import BillingItem from './components/BillingItem.vue';

export default {
  components: { BillingItem },
  setup() {
    const { accountId } = useAccount();
    const { formatMessage } = useMessageFormatter();
    return {
      accountId,
      formatMessage,
    };
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      uiFlags: 'accounts/getUIFlags',
    }),
    currentAccount() {
      return this.getAccount(this.accountId) || {};
    },
    customAttributes() {
      return this.currentAccount.custom_attributes || {};
    },
    hasABillingPlan() {
      return !!this.planName;
    },
    planName() {
      return this.customAttributes.plan_name || '';
    },
    subscribedQuantity() {
      return this.customAttributes.subscribed_quantity || 0;
    },
  },
  mounted() {
    this.fetchAccountDetails();
  },
  methods: {
    async fetchAccountDetails() {
      if (!this.hasABillingPlan) {
        this.$store.dispatch('accounts/subscription');
      }
    },
    onClickBillingPortal() {
      this.$store.dispatch('accounts/checkout');
    },
    onToggleChatWindow() {
      if (window.$chatwoot) {
        window.$chatwoot.toggle();
      }
    },
  },
};
</script>

<template>
  <div class="flex-1 py-6 overflow-auto mx-auto max-w-[960px] w-full p-1">
    <woot-loading-state v-if="uiFlags.isFetchingItem" />
    <div v-else-if="!hasABillingPlan">
      <p>{{ $t('BILLING_SETTINGS.NO_BILLING_USER') }}</p>
    </div>
    <div v-else class="w-full flex flex-col gap-5">
      <div class="border-b border-n-weak pb-4">
        <h6 class="text-n-slate-12">
          {{ $t('BILLING_SETTINGS.CURRENT_PLAN.TITLE') }}
        </h6>
        <div
          v-dompurify-html="formatMessage(
            $t('BILLING_SETTINGS.CURRENT_PLAN.PLAN_NOTE', {
              plan: planName,
              quantity: subscribedQuantity,
            })
          )
            "
        />
      </div>
      <BillingItem
        :title="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.TITLE')"
        :description="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.DESCRIPTION')"
        :button-label="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.BUTTON_TXT')"
        @open="onClickBillingPortal"
      />
      <BillingItem
        :title="$t('BILLING_SETTINGS.CHAT_WITH_US.TITLE')"
        :description="$t('BILLING_SETTINGS.CHAT_WITH_US.DESCRIPTION')"
        :button-label="$t('BILLING_SETTINGS.CHAT_WITH_US.BUTTON_TXT')"
        button-icon="chat-multiple"
        @open="onToggleChatWindow"
      />
    </div>
  </div>
</template>
