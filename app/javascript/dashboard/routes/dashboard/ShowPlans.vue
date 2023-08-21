<template>
  <div v-if="isSubscriptionValid && responseForPlans" transition="modal" class="skip-context-menu modal-mask ">
    <div class="modal-container bg-white dark:bg-slate-800 skip-context-menu ">
      <div class="plan-modal-header">
        <h4 class="text-center">
          {{ error }}
        </h4>
      </div>
      <button class="button modal--close clear button--only-icon secondary" @click="hidePlanModal">x</button>
      <div class="row flex justify-center items-center ">
        <div v-for="availableProductPrice in availableProductPrices" class="card plan-column">
          <h4 class="">
            {{ availableProductPrice.name }}
          </h4>
          <div class="solution--price">
            <div class="price mb-0 mt-2">
              $
            </div>
            <div class="h2 display-2 mb-0">
              {{ availableProductPrice.unit_amount }}
            </div>
            <div v-if="availableProductPrice.name === 'Starter' || availableProductPrice.name === 'Plus'"
              class="price mb-0 mt-2">/month</div>
            <div v-else class="price mb-0 mt-2">/year</div>
          </div>
          <div class="solution-description" v-html="availableProductPrice.description" />
          <woot-button v-if="planId !== availableProductPrice.id" title="Select this Plan"
            :disabled="isPlanClicked === true" @click="() => submitSubscription(availableProductPrice.id)">
            Select this plan
            <woot-spinner v-if="clickedPlan === availableProductPrice.id"></woot-spinner>
          </woot-button>
          <woot-button v-if="planId == availableProductPrice.id" title="Current Plan"
            style="opacity: 0.5; cursor: not-allowed">
            Current Plan
          </woot-button>
        </div>
      </div>
      <!-- <div>
        <h4 v-if="responseForPlans">
          <woot-button            
           @click="() => submitSubscription(7)"
           >limited</woot-button>
          <woot-button
          @click="() => submitSubscription(8)"
            >unlimited</woot-button>
        </h4>
      </div> -->
    </div>
  </div>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import AccountAPI from '../../api/account';
import WootButton from '../../components/ui/WootButton';
import Cookies from 'js-cookie';
export default {
  components: { WootButton },
  mixins: [alertMixin],
  props: {
    isSubscriptionValid: {
      type: Boolean,
      default: false,
    },
    planId: {
      type: [String, Number],
      default: 0,
    },
    planName: {
      type: [String, Number],
      default: 'Trail',
    },
    availableProductPrices: {
      type: Array,
      default: () => { },
    },
    responseForPlans: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      error: '',
      products: '',
      isPlanClicked: false,
      clickedPlan: null
    };
  },

  mounted() {
    this.error = Cookies.get('subscription');
  },
  methods: {
    hidePlanModal() {
      this.$emit('hideModal');
    },
    submitSubscription(value) {
      const payload = { product_price: value };
      this.isPlanClicked = true;
      this.clickedPlan = value
      AccountAPI.changePlan(payload)
        .then(response => {
          window.location.href = response.data.url;
          this.isPlanClicked = false;
          this.clickedPlan = null

        })
        .catch(error => {
          this.isPlanClicked = false;
          this.isPlanClicked = false;
          this.clickedPlan = null
        });
    },
  },
};
</script>
<style lang="scss" scoped>
.alert-wrap {
  font-size: var(--font-size-small);
  margin: var(--space-medium) var(--space-large) var(--space-zero);

  .callout {
    align-items: center;
    border-radius: var(--border-radius-normal);
    display: flex;
  }
}

.account-selector--modal .modal-container {
  // width: 880px !important;
  max-width: 100%;
}

.icon-wrap {
  margin-left: var(--space-smaller);
  margin-right: var(--space-slab);
}

.solution--price {
  display: flex;
  align-items: center;
  justify-content: center;
}

.plan-modal-container {
  max-width: 75vw;
  margin: auto;
  background-color: var(--white);
  min-width: 600px;
  position: relative;
  max-height: 100%;
  overflow-y: auto;
}

.solution-description {
  color: #869ab8 !important;
  font-size: 17px;
  margin-bottom: 1.3em;
}

.plan-column {
  max-width: 280px;
  width: 28%;
  margin-top: 50px;
  margin-left: 20px;
  margin-right: 20px;
  box-shadow: 0 1.5rem 4rem rgba(22, 28, 45, 0.1) !important;

  &:first-child {
    margin-right: 0;
  }
  &:nth-child(2) {
    margin-right: 0;
  }
}

.plan-modal-container {
  padding: 24px;
}

.badge-pill {
  background-color: rgba(31, 147, 255, 0.1);
  color: #1f93ff;
  text-transform: uppercase;
  font-weight: 600;
  font-size: 16px;
  width: fit-content;
  margin: auto;
  border-radius: 10px;
  padding: 6px 15px;
}

.justify-content-center {
  justify-content: center;
}

.description {
  height: 30px;
}
</style>