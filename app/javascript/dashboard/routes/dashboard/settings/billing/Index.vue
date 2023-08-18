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
          <label>{{
            $t('BILLING_SETTINGS.FORM.CURRENT_PLAN.PLAN_NOTE', {
              plan:planName
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
              expiry_date:plan_expiry_date
            })
          }}</label>
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
            <woot-button title="Change the Plan" @click="openPlanModal">
              {{ $t('BILLING_SETTINGS.FORM.CHANGE_PLAN.SELECT_PLAN') }}
            </woot-button>
          </label>
        </div>
      </div>
    </div>

    <woot-loading-state v-if="uiFlags.isFetchingItem" />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import configMixin from 'shared/mixins/configMixin';
import accountMixin from '../../../../mixins/account';
import AccountAPI from '../../../../api/account';
import Cookies from 'js-cookie';
import WootButton from '../../../../components/ui/WootButton';
import { BUS_EVENTS } from '../../../../../shared/constants/busEvents';
export default {
  components: { WootButton },
  mixins: [accountMixin, alertMixin, configMixin],
  data() {
    return {
      planName: '',
      agentCount: 0,
      selectedProductPrice: '',
      availableProductPrices: [],
      showStatus: true,
      plan_expiry_date:''
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
          Cookies.remove('subscription');
        } else if (status === 'cancel') {
          console.log('cancelled');
          this.showAlert(this.$t('BILLING_SETTINGS.CANCEL.MESSAGE'));
        } else if (status === 'error') {
          console.log('error');
          this.showAlert(this.$t('BILLING_SETTINGS.ERROR.MESSAGE'));
        }
      }
    },
    checkStatus(product) {
      // eslint-disable-next-line eqeqeq
      if (product.unit == 0 && product.name == 'Free') {
        return true;
      }
      return false;
    },
    openPlanModal() {
      bus.$emit(BUS_EVENTS.SHOW_PLAN_MODAL);
    },
    async initializeAccountBillingSubscription() {
      try {
        await this.$store.dispatch('accounts/getBillingSubscription');
        const {
          available_product_prices,
          plan_name,
          plan_id,
          agent_count,
          plan_expiry_date
        } = this.getAccount(this.accountId);
        this.planName = plan_name
        this.selectedProductPrice = plan_id;
        this.agentCount = agent_count;
        this.availableProductPrices = available_product_prices;
        const dateObject = new Date(plan_expiry_date)
        const year = dateObject.getFullYear();
        const month = dateObject.getMonth() + 1;
        const day = dateObject.getDate();
        this.plan_expiry_date = `${day}-${month}-${year}`
      } catch (error) {
        console.log(error);
      }
    },
    submitSubscription(event) {
      const payload = { product_price: event.target.value };
      AccountAPI.startBillingSubscription(payload)
        .then(response => {
          window.location.href = response.data.url;
        })
        .catch(error => {
          console.log(error, 'error');
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
</style>