<template>
  <div class="columns profile--settings">
    <woot-loading-state v-if="uiFlags.isFetchingItem" />
    <div v-else-if="!hasABillingPlan">
      <p>{{ $t('BILLING_SETTINGS.NO_BILLING_USER') }}</p>
    </div>
    <div v-else class="small-12 columns ">
      <div class="current-plan--details">
        <h6>{{ $t('BILLING_SETTINGS.CURRENT_PLAN.TITLE') }}</h6>
        <div
          v-dompurify-html="
            formatMessage(
              $t('BILLING_SETTINGS.CURRENT_PLAN.PLAN_NOTE', {
                plan: planName,
                quantity: subscribedQuantity,
              })
            )
          "
        />
      </div>
      <billing-item
        :title="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.TITLE')"
        :description="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.DESCRIPTION')"
        :button-label="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.BUTTON_TXT')"
        @click="onClickBillingPortal"
      />
      <billing-item
        :title="$t('BILLING_SETTINGS.CHAT_WITH_US.TITLE')"
        :description="$t('BILLING_SETTINGS.CHAT_WITH_US.DESCRIPTION')"
        :button-label="$t('BILLING_SETTINGS.CHAT_WITH_US.BUTTON_TXT')"
        button-icon="chat-multiple"
        @click="onToggleChatWindow"
      />
    </div>
  </div>
</template>

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';

import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import accountMixin from '../../../../mixins/account';
import BillingItem from './components/BillingItem.vue';

export default {
  components: { BillingItem },
  mixins: [accountMixin, alertMixin, messageFormatterMixin],
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
      await this.$store.dispatch('accounts/get');

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

<style lang="scss">
.manage-subscription {
  align-items: center;
  background: var(--white);
  border-radius: var(--border-radius-normal);
  border: 1px solid var(--color-border);
  display: flex;
  justify-content: space-between;
  margin-bottom: var(--space-small);
  padding: var(--space-medium) var(--space-normal);
}

.current-plan--details {
  border-bottom: 1px solid var(--color-border);
  margin-bottom: var(--space-normal);
  padding-bottom: var(--space-normal);
}

.manage-subscription {
  .manage-subscription--description {
    margin-bottom: 0;
  }
}
</style>
