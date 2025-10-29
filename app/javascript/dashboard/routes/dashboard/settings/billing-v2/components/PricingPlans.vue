<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store.js';
import { useAlert } from 'dashboard/composables';
import BillingCard from '../../billing/components/BillingCard.vue';
import ButtonV4 from 'next/button/Button.vue';
import SubscribeModal from './SubscribeModal.vue';
import CancelSubscriptionModal from './CancelSubscriptionModal.vue';

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

const showSubscribeModal = ref(false);
const showCancelModal = ref(false);
const selectedPlan = ref(null);
const selectedQuantity = ref(1);

const customAttributes = computed(() => {
  return props.currentAccount.custom_attributes || {};
});

const currentPlanId = computed(() => {
  return customAttributes.value.stripe_pricing_plan_id;
});

const currentPlanQuantity = computed(() => {
  return customAttributes.value.subscribed_quantity || 0;
});

const subscriptionStatus = computed(() => {
  return customAttributes.value.subscription_status;
});

const subscriptionEndsAt = computed(() => {
  return customAttributes.value.subscription_ends_at;
});

const stripeSubscriptionId = computed(() => {
  return customAttributes.value.stripe_subscription_id;
});

const pendingPlanId = computed(() => {
  return customAttributes.value.pending_stripe_pricing_plan_id;
});

const pendingQuantity = computed(() => {
  return customAttributes.value.pending_subscription_quantity;
});

const nextBillingDate = computed(() => {
  return customAttributes.value.next_billing_date;
});

const hasActiveSubscription = computed(() => {
  return !!currentPlanId.value;
});

const hasStripeSubscription = computed(() => {
  return !!stripeSubscriptionId.value;
});

const isCancellingAtPeriodEnd = computed(() => {
  return subscriptionStatus.value === 'cancel_at_period_end';
});

const hasPendingChanges = computed(() => {
  return !!pendingPlanId.value || !!pendingQuantity.value;
});

const formatEndDate = () => {
  if (!subscriptionEndsAt.value) return '';
  const date = new Date(subscriptionEndsAt.value);
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(date);
};

const formatNextBillingDate = () => {
  if (!nextBillingDate.value) return '';
  const date = new Date(nextBillingDate.value); // Parse ISO 8601 string
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(date);
};

const currentPlan = computed(() => {
  if (!currentPlanId.value) return null;
  return transformedPlans.value.find(plan => plan.id === currentPlanId.value);
});

const pendingPlan = computed(() => {
  if (!pendingPlanId.value) return null;
  return transformedPlans.value.find(plan => plan.id === pendingPlanId.value);
});

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

const formatPrice = price => {
  if (!price) return '$0';
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(price);
};

const formatNumber = num => {
  return new Intl.NumberFormat('en-US').format(num);
};

const openSubscribeModal = plan => {
  selectedPlan.value = plan;
  selectedQuantity.value = plan.min_seats || 1;
  showSubscribeModal.value = true;
};

const handleSubscribe = async data => {
  // Use change plan API only if stripe_subscription_id exists
  // Otherwise, always use subscribe API
  if (hasStripeSubscription.value) {
    const result = await store.dispatch('accounts/v2ChangePlan', data);
    if (result.success) {
      useAlert(t('BILLING_SETTINGS_V2.PRICING_PLANS.CHANGE_PLAN_SUCCESS'));
      showSubscribeModal.value = false;
    } else if (result.error) {
      useAlert(result.error);
    }
  } else {
    const result = await store.dispatch('accounts/v2Subscribe', data);
    if (result.success) {
      useAlert(t('BILLING_SETTINGS_V2.PRICING_PLANS.SUBSCRIBE_SUCCESS'));
      showSubscribeModal.value = false;
    } else if (result.error) {
      useAlert(result.error);
    }
  }
};

const openCancelModal = () => {
  showCancelModal.value = true;
};

const handleCancelSubscription = async reason => {
  const result = await store.dispatch('accounts/v2CancelSubscription', {
    reason,
  });
  if (result.success) {
    useAlert(t('BILLING_SETTINGS_V2.PRICING_PLANS.CANCEL_SUCCESS'));
    showCancelModal.value = false;
  } else if (result.error) {
    useAlert(result.error);
  }
};

const isUpdatingQuantity = ref(false);
const newQuantity = ref(1);

// Watch for changes in current plan quantity and initialize
watch(
  currentPlanQuantity,
  newValue => {
    newQuantity.value = newValue || 1;
  },
  { immediate: true }
);

const canDecreaseQuantity = computed(() => {
  return newQuantity.value > (currentPlan.value?.min_seats || 1);
});

const canIncreaseQuantity = computed(() => {
  return newQuantity.value < 100; // Max 100 seats
});

const decreaseQuantity = () => {
  if (canDecreaseQuantity.value) {
    newQuantity.value -= 1;
  }
};

const increaseQuantity = () => {
  if (canIncreaseQuantity.value) {
    newQuantity.value += 1;
  }
};

const hasQuantityChanged = computed(() => {
  return newQuantity.value !== currentPlanQuantity.value;
});

const handleUpdateQuantity = async () => {
  if (!hasQuantityChanged.value) return;

  isUpdatingQuantity.value = true;
  try {
    const result = await store.dispatch('accounts/v2UpdateQuantity', {
      pricingPlanId: currentPlanId.value,
      quantity: newQuantity.value,
    });
    if (result.success) {
      useAlert(t('BILLING_SETTINGS_V2.PRICING_PLANS.UPDATE_QUANTITY_SUCCESS'));
    } else if (result.error) {
      useAlert(result.error);
    }
  } finally {
    isUpdatingQuantity.value = false;
  }
};

const isCurrentPlan = plan => {
  return plan.id === currentPlanId.value;
};
</script>

<template>
  <div>
    <BillingCard
      :title="$t('BILLING_SETTINGS_V2.PRICING_PLANS.TITLE')"
      :description="$t('BILLING_SETTINGS_V2.PRICING_PLANS.DESCRIPTION')"
    >
      <template
        v-if="hasActiveSubscription && !isCancellingAtPeriodEnd"
        #action
      >
        <ButtonV4
          sm
          faded
          red
          :is-loading="isCanceling"
          @click="openCancelModal"
        >
          {{ $t('BILLING_SETTINGS_V2.PRICING_PLANS.CANCEL_SUBSCRIPTION') }}
        </ButtonV4>
      </template>

      <!-- Cancellation Notice -->
      <div
        v-if="isCancellingAtPeriodEnd"
        class="mx-5 mt-5 p-4 bg-y-50 border border-y-200 rounded-lg"
      >
        <div class="flex gap-3">
          <span
            class="i-lucide-alert-triangle text-y-700 flex-shrink-0 mt-0.5"
          />
          <div class="flex-1">
            <h4 class="text-sm font-semibold text-y-800">
              {{ $t('BILLING_SETTINGS_V2.PRICING_PLANS.CANCELLING_TITLE') }}
            </h4>
            <p class="mt-1 text-sm text-y-700">
              {{ $t('BILLING_SETTINGS_V2.PRICING_PLANS.CANCELLING_MESSAGE') }}
            </p>
            <p v-if="subscriptionEndsAt" class="mt-2 text-sm text-y-800">
              <span class="font-semibold">
                {{ $t('BILLING_SETTINGS_V2.PRICING_PLANS.ENDS_ON') }}:
              </span>
              {{ formatEndDate() }}
            </p>
            <p class="mt-2 text-sm font-medium text-y-800">
              {{
                $t('BILLING_SETTINGS_V2.PRICING_PLANS.CANCELLING_BLOCKED_INFO')
              }}
            </p>
          </div>
        </div>
      </div>

      <!-- Pending Changes Notice -->
      <div
        v-if="hasPendingChanges && !isCancellingAtPeriodEnd"
        class="mx-5 mt-5 p-4 bg-b-50 border border-b-200 rounded-lg"
      >
        <div class="flex gap-3">
          <span class="i-lucide-clock text-b-700 flex-shrink-0 mt-0.5" />
          <div class="flex-1">
            <h4 class="text-sm font-semibold text-b-800">
              Pending Changes Scheduled
            </h4>
            <p class="mt-1 text-sm text-b-700">
              Your subscription changes will take effect on your next billing
              date.
            </p>
            <div v-if="pendingPlan" class="mt-2 text-sm">
              <span class="font-semibold text-b-800">Next Plan: </span>
              <span class="text-b-700">{{ pendingPlan.name }}</span>
            </div>
            <div v-if="pendingQuantity" class="mt-1 text-sm">
              <span class="font-semibold text-b-800">Next Quantity: </span>
              <span class="text-b-700">{{ pendingQuantity }} seats</span>
            </div>
            <p v-if="nextBillingDate" class="mt-2 text-sm text-b-800">
              <span class="font-semibold">Effective Date: </span>
              {{ formatNextBillingDate() }}
            </p>
          </div>
        </div>
      </div>

      <!-- Current Subscription Info -->
      <div
        v-if="hasActiveSubscription && currentPlan"
        class="mx-5 mt-5 mb-6 p-5 rounded-lg border-2 border-b-500 bg-gradient-to-br from-b-50 to-b-25 shadow-sm"
      >
        <div class="flex items-start justify-between">
          <div class="flex-1">
            <div class="flex items-center gap-2 mb-2">
              <span class="i-lucide-circle-check text-g-600 text-xl" />
              <h4
                class="text-xs font-semibold text-n-600 uppercase tracking-wide"
              >
                {{ $t('BILLING_SETTINGS_V2.PRICING_PLANS.CURRENT_PLAN') }}
              </h4>
            </div>
            <div class="flex items-baseline gap-3 mt-2">
              <p class="text-2xl font-bold text-b-800">
                {{ currentPlan.name }}
              </p>
              <div
                class="flex items-center gap-1.5 px-3 py-1.5 bg-b-600 rounded-md shadow-sm"
              >
                <span class="i-lucide-users text-white" />
                <span class="text-lg font-bold text-white">
                  {{ currentPlanQuantity }}
                </span>
                <span class="text-sm font-medium text-b-100">
                  {{ $t('BILLING_SETTINGS_V2.PRICING_PLANS.SEATS') }}
                </span>
              </div>
            </div>

            <!-- Manage Seats Section -->
            <div
              v-if="!isCancellingAtPeriodEnd"
              class="flex items-center gap-3 mt-3"
            >
              <p class="text-xs font-medium text-n-500 uppercase tracking-wide">
                {{ $t('BILLING_SETTINGS_V2.PRICING_PLANS.MANAGE_SEATS') }}
              </p>
              <div class="flex items-center gap-2">
                <button
                  type="button"
                  class="w-8 h-8 flex items-center justify-center rounded-md bg-n-700 hover:bg-n-600 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
                  :disabled="!canDecreaseQuantity || isUpdatingQuantity"
                  @click="decreaseQuantity"
                >
                  <span class="i-lucide-minus text-white text-sm" />
                </button>
                <span
                  class="min-w-8 text-center text-base font-bold text-n-800"
                >
                  {{ newQuantity }}
                </span>
                <button
                  type="button"
                  class="w-8 h-8 flex items-center justify-center rounded-md bg-n-700 hover:bg-n-600 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
                  :disabled="!canIncreaseQuantity || isUpdatingQuantity"
                  @click="increaseQuantity"
                >
                  <span class="i-lucide-plus text-white text-sm" />
                </button>
                <ButtonV4
                  v-if="hasQuantityChanged"
                  sm
                  solid
                  blue
                  :is-loading="isUpdatingQuantity"
                  @click="handleUpdateQuantity"
                >
                  {{ $t('BILLING_SETTINGS_V2.PRICING_PLANS.UPDATE') }}
                </ButtonV4>
              </div>
            </div>
            <div class="flex items-center gap-4 mt-3 text-sm text-n-700">
              <div class="flex items-center gap-1.5">
                <span class="i-lucide-dollar-sign text-n-500" />
                <span class="font-semibold">
                  {{ formatPrice(currentPlan.base_price) }}/{{
                    $t('BILLING_SETTINGS_V2.PRICING_PLANS.MONTH')
                  }}
                </span>
              </div>
              <div class="flex items-center gap-1.5">
                <span class="i-lucide-zap text-y-500" />
                <span class="font-semibold">
                  {{ formatNumber(currentPlan.included_credits) }}
                </span>
                <span class="text-n-600">
                  {{ $t('BILLING_SETTINGS_V2.PRICING_PLANS.CREDITS_INCLUDED') }}
                </span>
              </div>
              <div
                v-if="nextBillingDate && !hasPendingChanges"
                class="flex items-center gap-1.5"
              >
                <span class="i-lucide-calendar text-b-500" />
                <span class="text-n-600">Next billing: </span>
                <span class="font-semibold">{{ formatNextBillingDate() }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Plans Grid -->
      <div class="px-5 pb-5">
        <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          <div
            v-for="plan in transformedPlans"
            :key="plan.id || plan.display_name"
            class="relative p-4 border rounded-lg transition-all"
            :class="
              isCurrentPlan(plan)
                ? 'border-b-500 bg-b-50'
                : 'border-n-weak hover:border-n-500 hover:shadow-sm'
            "
          >
            <!-- Recommended Badge -->
            <div
              v-if="plan.recommended"
              class="absolute -top-2 -right-2 px-2 py-0.5 bg-g-600 text-white text-xs font-semibold rounded"
            >
              {{ $t('BILLING_SETTINGS_V2.PRICING_PLANS.RECOMMENDED') }}
            </div>

            <!-- Current Plan Badge -->
            <div
              v-if="isCurrentPlan(plan)"
              class="mb-2 px-2 py-1 bg-b-600 text-white text-xs font-semibold rounded inline-block"
            >
              {{ $t('BILLING_SETTINGS_V2.PRICING_PLANS.CURRENT') }}
            </div>

            <h5 class="text-lg font-bold text-n-800">{{ plan.name }}</h5>
            <p class="mt-1 text-sm text-n-600">{{ plan.description }}</p>

            <div class="mt-3">
              <div class="flex items-baseline gap-1">
                <span class="text-2xl font-bold text-n-800">
                  {{ formatPrice(plan.base_price) }}
                </span>
                <span class="text-sm text-n-600">
                  /{{ $t('BILLING_SETTINGS_V2.PRICING_PLANS.MONTH') }}
                </span>
              </div>
            </div>

            <div class="mt-3 space-y-2 text-sm">
              <div class="flex items-center gap-2">
                <span class="i-lucide-check text-g-600" />
                <span class="text-n-700">
                  {{ formatNumber(plan.included_credits) }}
                  {{ $t('BILLING_SETTINGS_V2.PRICING_PLANS.CREDITS_PER_SEAT') }}
                </span>
              </div>
              <div v-if="plan.min_seats > 1" class="flex items-center gap-2">
                <span class="i-lucide-info text-b-600" />
                <span class="text-n-600 text-xs">
                  {{ $t('BILLING_SETTINGS_V2.PRICING_PLANS.MIN_SEATS') }}:
                  {{ plan.min_seats }}
                </span>
              </div>
            </div>

            <ButtonV4
              class="w-full mt-4"
              sm
              :solid="plan.recommended"
              :faded="!plan.recommended"
              :blue="plan.recommended"
              :slate="!plan.recommended"
              :disabled="isCurrentPlan(plan) || isCancellingAtPeriodEnd"
              @click="openSubscribeModal(plan)"
            >
              {{
                isCurrentPlan(plan)
                  ? $t('BILLING_SETTINGS_V2.PRICING_PLANS.CURRENT_PLAN')
                  : isCancellingAtPeriodEnd
                    ? $t('BILLING_SETTINGS_V2.PRICING_PLANS.BLOCKED')
                    : hasActiveSubscription
                      ? $t('BILLING_SETTINGS_V2.PRICING_PLANS.SWITCH_PLAN')
                      : $t('BILLING_SETTINGS_V2.PRICING_PLANS.SUBSCRIBE')
              }}
            </ButtonV4>
          </div>
        </div>

        <!-- Empty State -->
        <div v-if="plans.length === 0 && !isLoading" class="py-8 text-center">
          <p class="text-sm text-n-600">
            {{ $t('BILLING_SETTINGS_V2.PRICING_PLANS.NO_PLANS') }}
          </p>
        </div>
      </div>
    </BillingCard>

    <!-- Subscribe Modal -->
    <SubscribeModal
      v-if="showSubscribeModal"
      :plan="selectedPlan"
      :current-quantity="currentPlanQuantity"
      :is-subscribing="isSubscribing"
      @close="showSubscribeModal = false"
      @subscribe="handleSubscribe"
    />

    <!-- Cancel Subscription Modal -->
    <CancelSubscriptionModal
      v-if="showCancelModal"
      :is-canceling="isCanceling"
      @close="showCancelModal = false"
      @cancel="handleCancelSubscription"
    />
  </div>
</template>
