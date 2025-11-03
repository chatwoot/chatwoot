<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store.js';
import { useAlert } from 'dashboard/composables';
import format from 'date-fns/format';

import BillingCard from '../../billing/components/BillingCard.vue';
import PlanSummary from './PlanSummary.vue';
import PlansGrid from './PlansGrid.vue';
import Notice from 'dashboard/components-next/notice/Notice.vue';
import SubscribeDialog from './SubscribeDialog.vue';
import CancelSubscriptionDialog from './CancelSubscriptionDialog.vue';

const props = defineProps({
  plans: {
    type: Array,
    default: () => [],
  },
  currentAccount: {
    type: Object,
    default: () => ({}),
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  isSubscribing: {
    type: Boolean,
    default: false,
  },
  isCanceling: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();

const store = useStore();

const showAllPlans = ref(false);
const cancelModalRef = ref(null);
const subscribeDialogRef = ref(null);
const selectedPlan = ref(null);
const isUpdatingSeats = ref(false);
const updatingDirection = ref(null);

const customAttributes = computed(
  () => props.currentAccount.custom_attributes || {}
);
const currentPlanId = computed(
  () => customAttributes.value.stripe_pricing_plan_id
);
const currentPlanQuantity = computed(
  () => customAttributes.value.subscribed_quantity || 0
);
const subscriptionStatus = computed(
  () => customAttributes.value.subscription_status
);
const subscriptionEndsAt = computed(
  () => customAttributes.value.subscription_ends_at
);
const stripeSubscriptionId = computed(
  () => customAttributes.value.stripe_subscription_id
);
const pendingPlanId = computed(
  () => customAttributes.value.pending_stripe_pricing_plan_id
);
const pendingQuantity = computed(
  () => customAttributes.value.pending_subscription_quantity
);
const nextBillingDate = computed(
  () => customAttributes.value.next_billing_date
);

const hasActiveSubscription = computed(() => !!currentPlanId.value);
const hasStripeSubscription = computed(() => !!stripeSubscriptionId.value);
const isCancellingAtPeriodEnd = computed(
  () => subscriptionStatus.value === 'cancel_at_period_end'
);
const hasPendingChanges = computed(
  () => !!pendingPlanId.value || !!pendingQuantity.value
);

const formatEndDate = () =>
  subscriptionEndsAt.value
    ? format(new Date(subscriptionEndsAt.value), 'MMMM dd, yyyy')
    : '';

const formatNextBillingDate = () =>
  nextBillingDate.value
    ? format(new Date(nextBillingDate.value), 'MMMM dd, yyyy')
    : '';

// Transform backend component structure to flat structure
const transformedPlans = computed(() => {
  return props.plans.map(plan => {
    const components = plan.components || [];

    // Extract values from components array
    const serviceAction = components.find(c => c.type === 'service_action');
    const licenseFeeLike = components.find(c => c.type === 'license_fee');
    const rateCard = components.find(c => c.type === 'rate_card');

    return {
      ...plan,
      name: plan.display_name || plan.name,
      description: plan.description || '',
      base_price: licenseFeeLike?.unit_amount || 0,
      included_credits: serviceAction?.credit_amount || 0,
      overage_rate: rateCard?.overage_rate || 0,
      min_seats: plan.min_seats || 1,
      recommended: plan.recommended || false,
    };
  });
});

const currentPlan = computed(() => {
  if (!currentPlanId.value) return null;
  return transformedPlans.value.find(plan => plan.id === currentPlanId.value);
});

const pendingPlan = computed(() => {
  if (!pendingPlanId.value) return null;
  return transformedPlans.value.find(plan => plan.id === pendingPlanId.value);
});

const openSubscribeModal = plan => {
  selectedPlan.value = plan;
  subscribeDialogRef.value?.dialogRef?.open();
};

const openCancelModal = () => {
  cancelModalRef.value?.dialogRef?.open();
};

const handleSubscribe = async data => {
  // Use change plan API only if stripe_subscription_id exists
  // Otherwise, always use subscribe API
  const action = hasStripeSubscription.value ? 'v2ChangePlan' : 'v2Subscribe';
  const result = await store.dispatch(`accounts/${action}`, data);

  if (result.success) {
    const msgKey = hasStripeSubscription.value
      ? 'BILLING_SETTINGS_V2.PRICING_PLANS.CHANGE_PLAN_SUCCESS'
      : 'BILLING_SETTINGS_V2.PRICING_PLANS.SUBSCRIBE_SUCCESS';
    useAlert(t(msgKey));
    subscribeDialogRef.value?.dialogRef?.close();
  } else if (result.error) {
    useAlert(result.error);
  }
};

const handleCancelSubscription = async reason => {
  const result = await store.dispatch('accounts/v2CancelSubscription', {
    reason,
  });
  if (result.success) {
    useAlert(t('BILLING_SETTINGS_V2.PRICING_PLANS.CANCEL_SUCCESS'));
    cancelModalRef.value?.dialogRef?.close();
  } else if (result.error) {
    useAlert(result.error);
  }
};

const handleUpdateSeats = async ({ quantity, direction }) => {
  isUpdatingSeats.value = true;
  updatingDirection.value = direction;
  try {
    const result = await store.dispatch('accounts/v2UpdateQuantity', {
      pricingPlanId: currentPlanId.value,
      quantity,
    });
    if (result.success) {
      useAlert(t('BILLING_SETTINGS_V2.PRICING_PLANS.UPDATE_QUANTITY_SUCCESS'));
    } else if (result.error) {
      useAlert(result.error);
    }
  } finally {
    isUpdatingSeats.value = false;
    updatingDirection.value = null;
  }
};
</script>

<template>
  <div>
    <BillingCard
      :title="$t('BILLING_SETTINGS_V2.PRICING_PLANS.TITLE')"
      :description="$t('BILLING_SETTINGS_V2.PRICING_PLANS.DESCRIPTION')"
    >
      <Notice
        v-if="isCancellingAtPeriodEnd"
        color="amber"
        icon="i-lucide-alert-triangle"
        :title="$t('BILLING_SETTINGS_V2.PRICING_PLANS.CANCELLING_TITLE')"
        :message="$t('BILLING_SETTINGS_V2.PRICING_PLANS.CANCELLING_MESSAGE')"
        class="mx-5"
      >
        <p v-if="subscriptionEndsAt" class="mt-2 mb-0 text-sm">
          <span class="font-semibold">
            {{ $t('BILLING_SETTINGS_V2.PRICING_PLANS.ENDS_ON') }}:
          </span>
          {{ formatEndDate() }}
        </p>
        <p class="mt-1 mb-0 text-sm">
          {{ $t('BILLING_SETTINGS_V2.PRICING_PLANS.CANCELLING_BLOCKED_INFO') }}
        </p>
      </Notice>

      <Notice
        v-if="hasPendingChanges && !isCancellingAtPeriodEnd"
        color="blue"
        icon="i-lucide-clock"
        :title="t('BILLING_SETTINGS_V2.PRICING_PLANS.PENDING_TITLE')"
        :message="t('BILLING_SETTINGS_V2.PRICING_PLANS.PENDING_MESSAGE')"
        class="mx-5 mt-5"
      >
        <div v-if="pendingPlan" class="mt-2 text-sm">
          <span class="font-semibold">
            {{ t('BILLING_SETTINGS_V2.PRICING_PLANS.NEXT_PLAN') }}:
          </span>
          <span>{{ pendingPlan.name }}</span>
        </div>
        <div v-if="pendingQuantity" class="mt-1 text-sm">
          <span class="font-semibold">
            {{ t('BILLING_SETTINGS_V2.PRICING_PLANS.NEXT_QUANTITY') }}:
          </span>
          <span>
            {{ pendingQuantity }}
            {{ t('BILLING_SETTINGS_V2.PRICING_PLANS.SEATS') }}
          </span>
        </div>
        <p v-if="nextBillingDate" class="mt-2 mb-0 text-sm">
          <span class="font-semibold">
            {{ t('BILLING_SETTINGS_V2.PRICING_PLANS.EFFECTIVE_DATE') }}:
          </span>
          {{ formatNextBillingDate() }}
        </p>
      </Notice>

      <PlanSummary
        v-if="hasActiveSubscription && currentPlan"
        :plan-name="currentPlan.name"
        :price-per-month="currentPlan.base_price"
        :total-price="currentPlan.base_price * currentPlanQuantity"
        :renewal-date="nextBillingDate"
        :current-seats="currentPlanQuantity"
        :min-seats="currentPlan.min_seats || 1"
        :included-credits="currentPlan.included_credits"
        :is-cancelling="isCancellingAtPeriodEnd"
        :is-updating-seats="isUpdatingSeats"
        :updating-direction="updatingDirection"
        @view-all-plans="showAllPlans = !showAllPlans"
        @cancel-plan="openCancelModal"
        @update-seats="handleUpdateSeats"
      />

      <div
        class="transition-all duration-500 ease-in-out grid overflow-hidden mx-5 !mt-0"
        :class="
          !hasActiveSubscription || showAllPlans
            ? 'grid-rows-[1fr] opacity-100'
            : 'grid-rows-[0fr] opacity-0'
        "
      >
        <div class="overflow-hidden">
          <PlansGrid
            :plans="transformedPlans"
            :current-plan-id="currentPlanId"
            :has-active-subscription="hasActiveSubscription"
            :is-cancelling-at-period-end="isCancellingAtPeriodEnd"
            :is-loading="isLoading"
            @select-plan="openSubscribeModal"
          />
        </div>
      </div>
    </BillingCard>

    <SubscribeDialog
      ref="subscribeDialogRef"
      :plan="selectedPlan"
      :is-subscribing="isSubscribing"
      @subscribe="handleSubscribe"
    />

    <CancelSubscriptionDialog
      ref="cancelModalRef"
      :is-canceling="isCanceling"
      @cancel="handleCancelSubscription"
    />
  </div>
</template>
