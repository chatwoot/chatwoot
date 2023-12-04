<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="row flex justify-center items-center">
      <div
        v-for="availableProductPrice in availableProductPrices"
        :key="availableProductPrice.id"
        class="card plan-column"
      >
        <h4 class="">
          {{ availableProductPrice.name }}
        </h4>
        <div class="solution--price">
          <div class="price mb-0 mt-2">$</div>
          <div class="h2 display-2 mb-0">
            {{ availableProductPrice.unit_amount }}
          </div>
          <div
            v-if="
              availableProductPrice.name === 'Starter' ||
              availableProductPrice.name === 'Plus'
            "
            class="price mb-0 mt-2"
          >
            /month
          </div>
          <div v-else class="price mb-0 mt-2">/year</div>
        </div>
        <div
          class="solution-description"
          v-html="availableProductPrice.description"
        />
        <woot-submit-button
          v-if="planId !== availableProductPrice.id"
          :disabled="isPlanClicked === true"
          :button-text="$t('BILLING_SETTINGS.FORM.NEW_PLAN.TITLE')"
          @click="() => submitSubscription(availableProductPrice.id)"
        >
          <woot-spinner v-if="clickedPlan === availableProductPrice.id" />
        </woot-submit-button>

        <woot-submit-button
          v-if="
            planId === availableProductPrice.id &&
            !planHasExpired(planExpiryDate)
          "
          :button-text="$t('BILLING_SETTINGS.FORM.CURRENT_PLAN.TITLE')"
          style="opacity: 0.5; cursor: not-allowed"
        />

        <woot-submit-button
          v-if="
            planId === availableProductPrice.id &&
            planHasExpired(planExpiryDate)
          "
          :button-text="$t('BILLING_SETTINGS.FORM.PURCHASE_AGAIN.TITLE')"
          :disabled="isPlanClicked === true"
          @click="() => submitSubscription(availableProductPrice.id)"
        />
      </div>
    </div>
  </modal>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import AccountAPI from '../../../../api/account';
import Modal from '../../../../components/Modal.vue';
import WootSubmitButton from '../../../../components/buttons/FormSubmitButton.vue';
export default {
  components: {
    WootSubmitButton,
    Modal,
  },
  mixins: [alertMixin],
  props: {
    planId: {
      type: [String, Number],
      default: 0,
    },
    planName: {
      type: [String, Number],
      default: 'Trial',
    },
    availableProductPrices: {
      type: Array,
      default: () => {},
    },
    planExpiryDate: {
      type: String,
      default: null,
    },
    onClose: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      error: '',
      products: '',
      isPlanClicked: false,
      clickedPlan: null,
      show: true,
    };
  },
  methods: {
    hidePlanModal() {
      this.$emit('hideModal');
    },
    submitSubscription(value) {
      const payload = { product_price: value };
      this.isPlanClicked = true;
      this.clickedPlan = value;
      AccountAPI.changePlan(payload)
        .then(response => {
          window.open(response.data.url, '_blank');
          this.isPlanClicked = false;
          this.clickedPlan = null;
        })
        // eslint-disable-next-line no-unused-vars
        .catch(error => {
          this.isPlanClicked = false;
          this.isPlanClicked = false;
          this.clickedPlan = null;
        });
    },
    planHasExpired(expirationDate) {
      const currentDate = new Date();
      const planExpirationDate = new Date(expirationDate);

      // Compare the current date with the plan's expiration date
      return currentDate > planExpirationDate;
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
.icon-wrap {
  margin-left: var(--space-smaller);
  margin-right: var(--space-slab);
}

.solution--price {
  display: flex;
  align-items: center;
  justify-content: center;
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
