<template>
  <div class="columns profile--settings">
    <div v-if="!uiFlags.isFetchingItem">
      <div class="small-12 row profile--settings--row">
        <div class="columns small-3">
          <h4 class="block-title">
            {{ $t('BILLING_SETTINGS.FORM.CURRENT_PLAN.TITLE') }}
          </h4>
        </div>
        <div class="columns small-9 medium-5">
          <label v-if="planName == 'Lifetime'">{{
            $t('BILLING_SETTINGS.FORM.CURRENT_PLAN.LTD_PLAN_NOTE', {
              plan: planName,
              platform: platformName,
              agent: agentCount,
            })
          }}</label>
          <label v-else>{{
            $t('BILLING_SETTINGS.FORM.CURRENT_PLAN.SUBSCRIPTION_PLAN_NOTE', {
              plan: planName,
            })
          }}</label>
        </div>
      </div>
      <div class="small-12 row profile--settings--row">
        <div class="columns small-3">
          <h4 class="block-title">
            {{ $t('BILLING_SETTINGS.FORM.EXPIRY.TITLE') }}
          </h4>
        </div>
        <div class="columns small-9 medium-5">
          <label>{{
            $t('BILLING_SETTINGS.FORM.EXPIRY.PLAN_NOTE', {
              expiry_date: planExpiryDate,
            })
          }}</label>
        </div>
      </div>
      <div class="small-12 row profile--settings--row">
        <div class="columns small-3">
          <h4 class="block-title">
            {{ $t('BILLING_SETTINGS.FORM.COUPON_CODE.TITLE') }}
          </h4>
        </div>
        <div class="columns small-9 medium-5">
          <div class="input-container">
            <input
              id="couponInput"
              v-model="inputValue"
              type="text"
              name="coupon_code"
              placeholder="Enter a single coupon code"
            />
            <woot-submit-button
              :button-text="$t('BILLING_SETTINGS.FORM.COUPON_CODE.APPLY')"
              :loading="uiFlags.isCreating"
              button-class="medium"
              @click="applyCouponCode"
            />
          </div>
        </div>
      </div>
      <div class="small-12 row profile--settings--row">
        <div class="columns small-3">
          <h4 class="block-title">
            {{ $t('BILLING_SETTINGS.FORM.CHANGE_PLAN.TITLE') }}
          </h4>
        </div>
        <div class="columns small-9 medium-5">
          <label>
            <woot-submit-button
              :button-text="$t('BILLING_SETTINGS.FORM.CHANGE_PLAN.SELECT_PLAN')"
              variant="smooth"
              button-class="medium"
              @click="openPlanModal"
            />
          </label>
        </div>
      </div>
    </div>
    <!-- List Plans -->
    <woot-modal :show.sync="showPlanModal" :on-close="hidePlanModal">
      <show-plan
        v-if="showPlanModal"
        :available-product-prices="availableProductPrices"
        :plan-id="selectedProductPrice"
        :plan-name="planName"
        :plan-expiry-date="planExpiryDate"
        :on-close="hidePlanModal"
      />
    </woot-modal>
    <woot-loading-state v-if="uiFlags.isFetchingItem" />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import configMixin from 'shared/mixins/configMixin';
import accountMixin from '../../../../mixins/account';
import AccountAPI from '../../../../api/account';
import { applyPageFilters } from '../../../../store/modules/conversations/helpers';
// List all Plans
import ShowPlan from './ShowPlan.vue';

export default {
  components: {
    ShowPlan,
  },
  mixins: [accountMixin, alertMixin, configMixin],
  data() {
    return {
      planName: '',
      platformName: '',
      agentCount: 0,
      selectedProductPrice: '',
      availableProductPrices: [],
      showStatus: true,
      planExpiryDate: '',
      isValidCouponCode: false,
      inputValue: '',
      showPlanModal: false,
    };
  },
  validations: {},
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
      getAccount: 'accounts/getAccount',
      uiFlags: 'accounts/getUIFlags',
    }),
    isUpdating() {
      return this.uiFlags.isUpdating;
    },
  },
  mounted() {
    this.initializeAccountBillingSubscription();
  },
  updated() {
    this.$nextTick(this.checkStatusOfSubscription());
  },
  methods: {
    checkStatusOfSubscription() {
      const status = this.$route.query.subscription_status;
      if (this.showStatus) {
        this.showStatus = false;
        if (status === 'success') {
          this.showAlert(this.$t('BILLING_SETTINGS.SUCCESS.MESSAGE'));
        } else if (status === 'cancel') {
          this.showAlert(this.$t('BILLING_SETTINGS.CANCEL.MESSAGE'));
        } else if (status === 'error') {
          this.showAlert(this.$t('BILLING_SETTINGS.ERROR.MESSAGE'));
        }
      }
    },
    checkStatus(product) {
      // eslint-disable-next-line eqeqeq
      if (product.unit == 0 && product.name == 'Trial') {
        return true;
      }
      return false;
    },
    // Open Plan Modal
    openPlanModal() {
      this.showPlanModal = true;
    },
    // Close Plan Modal
    hidePlanModal() {
      this.showPlanModal = false;
    },
    async initializeAccountBillingSubscription() {
      this.$store.dispatch('accounts/getBillingSubscription').then(() => {
        try {
          const {
            available_product_prices,
            plan_name,
            platform_name,
            plan_id,
            allowed_no_agents,
            plan_expiry_date,
          } = this.getAccount(this.accountId);
          this.planName = plan_name;
          this.platformName = platform_name;
          this.selectedProductPrice = plan_id;
          this.agentCount = allowed_no_agents;
          this.availableProductPrices = available_product_prices;
          const dateObject = new Date(plan_expiry_date);
          const day = String(dateObject.getDate()).padStart(2, '0');
          const monthIndex = dateObject.getMonth();
          const year = dateObject.getFullYear();
          const monthNames = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
          const formattedDate = `${day} ${monthNames[monthIndex]} ${year}`;
          this.planExpiryDate = formattedDate;
        } catch (error) {
          // not showing error
        }
      });
    },
    submitSubscription(event) {
      const payload = { product_price: event.target.value };
      AccountAPI.startBillingSubscription(payload)
        .then(response => {
          window.location.href = response.data.url;
        })
        .catch(error => {
          // eslint-disable-next-line no-console
          console.log(error, 'error');
        });
    },
    checkInput() {
      const couponInput = document.getElementById('couponInput');
      const inputValue = couponInput.value;
      this.isValidCouponCode =
        /^(AS|DM)[0-9a-zA-Z]{8}$|^(PG-)([0-9a-zA-Z]{4}-){3}[0-9a-zA-Z]{2}$/.test(
          inputValue
        );
      return this.isValidCouponCode;
    },
    async applyCouponCode() {
      const couponCode = this.inputValue;
      if (!this.checkInput(couponCode)) {
        this.showAlert(this.$t('BILLING_SETTINGS.COUPON_ERROR.MESSAGE'));
        return;
      }
      const payload = { coupon_code: couponCode };
      AccountAPI.checkCouponCodeValidity(payload)
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
@import '~dashboard/assets/scss/variables.scss';
@import '~dashboard/assets/scss/mixins.scss';

.profile--settings {
  padding: 24px;
  overflow: auto;
}

.profile--settings--row {
  @include border-normal-bottom;
  padding: $space-normal;

  .small-3 {
    padding: $space-normal $space-medium $space-normal 0;
  }

  .small-9 {
    padding: $space-normal;
  }
}
.input-container {
  display: flex;
}
.input-container input {
  margin-right: 10px;
}
</style>
