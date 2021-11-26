<template>
  <div class="columns profile--settings">
    <form v-if="!uiFlags.isFetchingItem" @submit.prevent="updateAccount">
      <div class="small-12 row profile--settings--row">
        <div class="columns small-3">
          <h4 class="block-title">
            {{ $t('BILLING_SETTINGS.FORM.CURRENT_PLAN.TITLE') }}
          </h4>
          <p>{{ $t('BILLING_SETTINGS.FORM.CURRENT_PLAN.NOTE') }}</p>
        </div>
        <div class="columns small-9 medium-5">
          <label>{{
            $t('BILLING_SETTINGS.FORM.CURRENT_PLAN.PLAN_NOTE', {
              plan: planName,
            })
          }}</label>
        </div>
      </div>
      <div class="small-12 row profile--settings--row">
        <div class="columns small-3">
          <h4 class="block-title">
            {{ $t('BILLING_SETTINGS.FORM.CHANGE_PLAN.TITLE') }}
          </h4>
          <p>{{ $t('BILLING_SETTINGS.FORM.CURRENT_PLAN.NOTE') }}</p>
        </div>
        <div class="columns small-9 medium-5">
          <label>
            {{ $t('BILLING_SETTINGS.FORM.CHANGE_PLAN.SELECT_PLAN') }}
            <select v-model="selectedProductPrice" @change="submitSubscription">
              <option
                v-for="productPrice in availableProductPrices"
                :key="productPrice.id"
                :value="productPrice.id"
              >
                {{ productPrice.display_name }}
              </option>
            </select>
          </label>
        </div>
      </div>
    </form>

    <woot-loading-state v-if="uiFlags.isFetchingItem" />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import configMixin from 'shared/mixins/configMixin';
import accountMixin from '../../../../mixins/account';
import AccountAPI from '../../../../api/account';

export default {
  mixins: [accountMixin, alertMixin, configMixin],
  data() {
    return {
      planName: '',
      agentCount: 0,
      selectedProductPrice: '',
      availableProductPrices: [],
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
  methods: {
    async initializeAccountBillingSubscription() {
      try {
        await this.$store.dispatch('accounts/getBillingSubscription');
        const {
          plan_name,
          agent_count,
          available_product_prices,
        } = this.getAccount(this.accountId);

        this.planName = plan_name;
        this.agentCount = agent_count;
        this.availableProductPrices = available_product_prices;
      } catch (error) {}
    },
    submitSubscription(event) {
      const payload = { product_price: event.target.value };
      AccountAPI.startBillingSubscription(payload)
        .then(response => {
          window.location.href = response.data.url;
        })
        .catch(() => {});
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
