<template>
  <div class="columns profile--settings stamp-container">
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
      <div
        v-tooltip.top="$t('BILLING_SETTINGS.COPY_CODE')"
        class="stamp"
        @click="copyToClipboard"
      >
        Use Code for 25% off<br />
        <span class="coupon">HAPPYJULY4</span>
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
import { copyTextToClipboard } from 'shared/helpers/clipboard';
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
    async copyToClipboard(e) {
      e.preventDefault();
      await copyTextToClipboard('HAPPYJULY4');
      bus.$emit('newToastMessage', this.$t('COMPONENTS.CODE.COPY_SUCCESSFUL'));
    },
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

.stamp-container {
  position: relative;
}

.stamp {
  position: absolute;
  padding: 1.5rem 2rem;
  background: var(--w-500);
  color: var(--white);
  font-size: 1rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.1rem;
  text-align: center;
  transform: rotate(5deg);
  right: 3rem;
  top: 1.5rem;
  cursor: pointer;

  .coupon {
    font-size: 2rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.1rem;
  }
}

.stamp {
  --mask: linear-gradient(#000 0 0) 50% / calc(100% - 9.25px)
      calc(100% - 9.25px) no-repeat,
    radial-gradient(farthest-side, #000 98%, #0000) 0 0/10px 10px round;
  -webkit-mask: var(--mask);
  mask: var(--mask);
}

.stamp::after {
  content: '';
  opacity: 0.1;
  width: 40px;
  height: 100%;
  position: absolute;
  background-color: white;
  top: 0;
  left: 0;
  transform: rotate(10deg);
  animation: move 2s infinite;
}

@keyframes move {
  0% {
    left: -10%;
  }
  100% {
    left: 110%;
  }
}
</style>
