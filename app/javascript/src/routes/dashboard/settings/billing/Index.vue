<template>
  <div class="column content-box billing">
    <woot-loading-state v-if="fetchStatus" :message="$t('BILLING.LOADING')" />
    <div class="row" v-if="billingDetails">
      <div class="small-12 columns billing__stats">
        <div class="account-row">
          <span class="title">{{ $t('BILLING.ACCOUNT_STATE') }}</span>
          <span class="value">{{ billingDetails.state }} </span>
        </div>
        <div class="account-row">
          <span class="title">{{ $t('BILLING.AGENT_COUNT') }}</span>
          <span class="value">{{ billingDetails.agents_count }} </span>
        </div>
        <div class="account-row">
          <span class="title">{{ $t('BILLING.PER_AGENT_COST') }}</span>
          <span class="value">${{ billingDetails.per_agent_cost }} </span>
        </div>

        <div class="account-row">
          <span class="title">{{ $t('BILLING.TOTAL_COST') }}</span>
          <span class="value">${{ billingDetails.total_cost }} </span>
        </div>
      </div>
      <div class="small-12 columns billing__form">
        <iframe :src="billingDetails.iframe_url" v-if="iframeUrl && !isShowEmptyState"></iframe>
        <div v-if="isShowEmptyState">
          <empty-state :title="emptyStateTitle" :message="emptyStateMessage">
            <div class="medium-12 columns text-center">
              <button class="button success nice" @click="billingButtonClick()">{{buttonText}}</button>
            </div>
          </empty-state>
        </div>
      </div>
    </div>

  </div>
</template>

<script>
/* eslint no-console: 0 */
/* global bus */
import { mapGetters } from 'vuex';

import EmptyState from '../../../../components/widgets/EmptyState';

export default {
  props: ['state'],

  data() {
    return {
      is_adding_source: false,
    };
  },

  components: {
    EmptyState,
  },

  computed: {
    ...mapGetters({
      billingDetails: 'getBillingDetails',
      fetchStatus: 'billingFetchStatus',
      daysLeft: 'getTrialLeft',
      subscriptionData: 'getSubscription',
    }),
    redirectMessage() {
      if (!this.state) {
        return '';
      }
      if (this.state === 'succeeded') {
        return this.$t('BILLING.STATUS.SUCCESS');
      }
      return this.$t('BILLING.STATUS.ERROR');
    },
    iframeUrl() {
      return typeof this.billingDetails.iframe_url === 'string';
    },
    isShowEmptyState() {
      if (this.billingDetails !== null) {
        if (this.is_adding_source) {
          return false;
        }
      }
      return true;
    },
    buttonText() {
      if (this.billingDetails !== null) {
        return this.billingDetails.payment_source_added ? this.$t('BILLING.BUTTON.EDIT') : this.$t('BILLING.BUTTON.ADD');
      }
      return this.$t('BILLING.BUTTON.ADD');
    },
    emptyStateTitle() {
      if (this.daysLeft <= 0 || this.subscriptionData.state === 'cancelled') {
        return this.$t('BILLING.TRIAL.TITLE');
      }
      return '';
    },
    emptyStateMessage() {
      if (this.daysLeft <= 0 || this.subscriptionData.state === 'cancelled') {
        return this.$t('BILLING.TRIAL.MESSAGE');
      }
      return '';
    },
  },

  mounted() {
    if (this.state) {
      bus.$emit('newToastMessage', this.redirectMessage);
    }
    this.$store.dispatch('fetchSubscription');
  },

  methods: {
    billingButtonClick() {
      this.is_adding_source = true;
    },
  },

};
</script>
