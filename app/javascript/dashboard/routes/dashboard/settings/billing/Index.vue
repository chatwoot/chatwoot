<template>
  <div class="overflow-auto flex-1 p-6 dark:bg-slate-900">
    <woot-loading-state v-if="uiFlags.isFetchingItem" />
    <div v-else-if="!hasABillingPlan">
      <p>{{ $t('BILLING_SETTINGS.NO_BILLING_USER') }}</p>
    </div>
    <div v-else class="w-full">
      <div
        v-if="
          (['Starter', 'Plus', 'Pro'].includes(planName) &&
            ltdPlanName === null) ||
          (['Plus', 'Pro'].includes(planName) && ltdPlanName !== null)
        "
        class="current-plan--details"
      >
        <h6>{{ $t('BILLING_SETTINGS.CURRENT_PLAN.TITLE') }}</h6>
        <div
          v-dompurify-html="
            formatMessage(
              $t('BILLING_SETTINGS.CURRENT_PLAN.PLAN_NOTE', {
                plan: planName,
                quantity: planName === 'Starter' ? 2 : 'Unlimited',
              })
            )
          "
        />
      </div>
      <div v-else class="current-plan--details">
        <h6>{{ $t('LTD_SETTINGS.CURRENT_PLAN.TITLE') }}</h6>
        <div
          v-dompurify-html="
            formatMessage(
              $t('LTD_SETTINGS.CURRENT_PLAN.PLAN_NOTE', {
                plan: ltdPlanName,
                quantity: ltdQuantity !== 100000 ? ltdQuantity : 'Unlimited',
              })
            )
          "
        />
      </div>
      <div class="current-plan--details">
        <h6>{{ $t('LTD_SETTINGS.TITLE') }}</h6>
        <div class="input-container">
          <input
            id="couponInput"
            v-model="inputValue"
            type="text"
            name="coupon_code"
            placeholder="Enter a single coupon code"
          />
          <woot-submit-button
            :button-text="$t('LTD_SETTINGS.APPLY')"
            :loading="uiFlags.isCreating"
            button-class="medium"
            @click="applyCouponCode"
          />
        </div>
      </div>
      <billing-item
        :title="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.TITLE')"
        :description="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.DESCRIPTION')"
        :button-label="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.BUTTON_TXT')"
        @click="onClickBillingPortal"
      />
      <!-- <billing-item
        :title="$t('BILLING_SETTINGS.CHAT_WITH_US.TITLE')"
        :description="$t('BILLING_SETTINGS.CHAT_WITH_US.DESCRIPTION')"
        :button-label="$t('BILLING_SETTINGS.CHAT_WITH_US.BUTTON_TXT')"
        button-icon="chat-multiple"
        @click="onToggleChatWindow"
      /> -->
    </div>
  </div>
</template>

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';

import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import accountMixin from '../../../../mixins/account';
import AccountAPI from '../../../../api/account';
import BillingItem from './components/BillingItem.vue';

export default {
  components: { BillingItem },
  mixins: [accountMixin, alertMixin, messageFormatterMixin],
  data() {
    return {
      isValidCouponCode: false,
      inputValue: '',
      ltdPlanName: null,
      ltdQuantity: null,
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
    ltdAttributes() {
      return this.currentAccount.ltd_attributes || {};
    },
    hasABillingPlan() {
      return !!this.planName;
    },
    planName() {
      return this.customAttributes.plan_name || '';
    },
  },
  mounted() {
    this.fetchAccountDetails();
    this.fetchLtdDetails();
  },
  methods: {
    async fetchAccountDetails() {
      if (!this.hasABillingPlan) {
        this.$store.dispatch('accounts/stripe_subscription');
      }
    },
    async fetchLtdDetails() {
      AccountAPI.getLtdDetails()
        .then(response => {
          this.ltdPlanName = response.data.data.plan_name;
          this.ltdQuantity = response.data.data.quantity;
        })
        .catch(error => {
          this.showAlert(error.response.data.message);
        });
    },
    onClickBillingPortal() {
      this.$store.dispatch('accounts/stripe_checkout');
    },
    onToggleChatWindow() {
      if (window.$chatwoot) {
        window.$chatwoot.toggle();
      }
    },
    checkInput() {
      const couponInput = document.getElementById('couponInput');
      const inputValue = couponInput.value;
      this.isValidCouponCode =
        /^(AS|DM)[0-9a-zA-Z]{8}$|^(PG-|RH-|DF-|OH-)([0-9a-zA-Z]{4}-){3}[0-9a-zA-Z]{2}$/.test(
          inputValue
        );
      return this.isValidCouponCode;
    },
    async applyCouponCode() {
      const couponCode = this.inputValue;
      if (!this.checkInput(couponCode)) {
        this.showAlert(this.$t('LTD_SETTINGS.COUPON_ERROR.MESSAGE'));
        return;
      }
      const payload = { coupon_code: couponCode };
      AccountAPI.getLTD(payload)
        .then(response => {
          this.showAlert(response.data.message);
          window.location.reload();
        })
        .catch(error => {
          this.showAlert(error.response.data.message);
        });
    },
  },
};
</script>

<style lang="scss">
.manage-subscription {
  @apply bg-white dark:bg-slate-800 flex justify-between mb-2 py-6 px-4 items-center rounded-md border border-solid border-slate-75 dark:border-slate-700;
}

.current-plan--details {
  @apply border-b border-solid border-slate-75 dark:border-slate-800 mb-4 pb-4;

  h6 {
    @apply text-slate-800 dark:text-slate-100;
  }

  p {
    @apply text-slate-600 dark:text-slate-200;
  }
}

.manage-subscription {
  .manage-subscription--description {
    @apply mb-0 text-slate-600 dark:text-slate-200;
  }

  h6 {
    @apply text-slate-800 dark:text-slate-100;
  }
}
</style>
