<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useAlert } from 'dashboard/composables';
import { format } from 'date-fns';
import sessionStorage from 'shared/helpers/sessionStorage';

import BillingMeter from './components/BillingMeter.vue';
import BillingCard from './components/BillingCard.vue';
import BillingHeader from './components/BillingHeader.vue';
import SubscriptionRow from './components/SubscriptionRow.vue';
import SeatStepper from './components/SeatStepper.vue';
import ChangePlanModal from './components/ChangePlanModal.vue';
import CancelSubscriptionModal from './components/CancelSubscriptionModal.vue';
import PurchaseCreditsModal from './components/PurchaseCreditsModal.vue';
import CreditHistoryModal from './components/CreditHistoryModal.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const router = useRouter();
const store = useStore();
const { currentAccount, isOnChatwootCloud } = useAccount();
const {
  captainEnabled,
  responseLimits,
  fetchLimits: fetchCaptainLimits,
} = useCaptain();

const uiFlags = useMapGetter('accounts/getUIFlags');
const pricingPlans = useMapGetter('accounts/getPricingPlans');
const topupOptions = useMapGetter('accounts/getTopupOptions');
const creditGrants = useMapGetter('accounts/getCreditGrants');

const BILLING_REFRESH_ATTEMPTED = 'billing_refresh_attempted';

// Modal refs
const changePlanModalRef = ref(null);
const cancelModalRef = ref(null);
const purchaseCreditsModalRef = ref(null);
const creditHistoryModalRef = ref(null);

// State
const isWaitingForBilling = ref(false);
const isEditingSeats = ref(false);
const editedSeats = ref(0);

const customAttributes = computed(() => {
  return currentAccount.value.custom_attributes || {};
});

const planName = computed(() => customAttributes.value.plan_name);
const currentPlanId = computed(
  () => customAttributes.value.stripe_pricing_plan_id
);
const subscriptionId = computed(
  () => customAttributes.value.stripe_subscription_id
);
const subscribedQuantity = computed(
  () => customAttributes.value.subscribed_quantity
);
const subscriptionStatus = computed(
  () => customAttributes.value.subscription_status
);

// Check if user has an active subscription (required for seat changes and cancellation)
const hasActiveSubscription = computed(() => !!subscriptionId.value);

const subscriptionEndsAt = computed(() => {
  if (!customAttributes.value.subscription_ends_at) return '';
  const endDate = new Date(customAttributes.value.subscription_ends_at);
  return format(endDate, 'dd MMM, yyyy');
});

const subscriptionCancelledAt = computed(() => {
  if (!customAttributes.value.subscription_cancelled_at) return '';
  const cancelledDate = new Date(
    customAttributes.value.subscription_cancelled_at
  );
  return format(cancelledDate, 'dd MMM, yyyy');
});

const hasABillingPlan = computed(() => !!planName.value);

const isCancelled = computed(() => {
  return subscriptionStatus.value === 'cancel_at_period_end';
});

// Captain credits
const creditsUsed = computed(() => {
  if (!responseLimits.value) return 0;
  return responseLimits.value.consumed || 0;
});

const creditsTotal = computed(() => {
  if (!responseLimits.value) return 0;
  return responseLimits.value.totalCount || 0;
});

// Actions
const fetchAccountDetails = async () => {
  if (!hasABillingPlan.value) {
    await store.dispatch('accounts/subscription');
  }
  // Always fetch captain limits to show AI credits
  fetchCaptainLimits();
};

const handleBillingPageLogic = async () => {
  if (!isOnChatwootCloud.value) {
    router.push({ name: 'home' });
    return;
  }

  const billingRefreshAttempted = sessionStorage.get(BILLING_REFRESH_ATTEMPTED);
  await fetchAccountDetails();

  if (!hasABillingPlan.value) {
    if (!billingRefreshAttempted) {
      isWaitingForBilling.value = true;
      sessionStorage.set(BILLING_REFRESH_ATTEMPTED, true);
      setTimeout(() => {
        window.location.reload();
      }, 5000);
    } else {
      sessionStorage.remove(BILLING_REFRESH_ATTEMPTED);
    }
  } else {
    sessionStorage.remove(BILLING_REFRESH_ATTEMPTED);
  }
};

const openBillingPortal = () => {
  store.dispatch('accounts/checkout');
};

const openChatWidget = () => {
  if (window.$chatwoot) {
    window.$chatwoot.toggle();
  }
};

// Modal handlers
const openChangePlanModal = async () => {
  await store.dispatch('accounts/fetchPricingPlans');
  changePlanModalRef.value?.open();
};

const handlePlanSelect = async plan => {
  try {
    // If no active subscription, use subscribe API (for Hacker plan users)
    if (!hasActiveSubscription.value) {
      await store.dispatch('accounts/subscribeToPlan', {
        pricingPlanId: plan.id,
        quantity: 1,
      });
      // subscribeToPlan redirects to Stripe, so no need to close modal
      return;
    }

    // Otherwise use change plan API (for existing subscribers)
    await store.dispatch('accounts/changePricingPlan', {
      pricingPlanId: plan.id,
      quantity: subscribedQuantity.value || 1,
    });
    changePlanModalRef.value?.close();
    useAlert(t('BILLING_SETTINGS.ALERTS.PLAN_CHANGED'));
    await store.dispatch('accounts/subscription');
  } catch {
    // Error already handled
  }
};

// Seats editing
const startEditingSeats = () => {
  editedSeats.value = subscribedQuantity.value || 1;
  isEditingSeats.value = true;
};

const cancelEditingSeats = () => {
  isEditingSeats.value = false;
};

const saveSeats = async newSeats => {
  if (newSeats === subscribedQuantity.value) {
    isEditingSeats.value = false;
    return;
  }

  try {
    await store.dispatch('accounts/changePricingPlan', {
      pricingPlanId: currentPlanId.value,
      quantity: newSeats,
    });
    isEditingSeats.value = false;
    useAlert(t('BILLING_SETTINGS.ALERTS.SEATS_UPDATED'));
    await store.dispatch('accounts/subscription');
  } catch {
    // Error already handled
  }
};

// Cancel subscription
const openCancelModal = () => {
  cancelModalRef.value?.open();
};

const handleCancelConfirm = async ({ reason, feedback }) => {
  try {
    await store.dispatch('accounts/cancelAccountSubscription', {
      reason,
      feedback,
    });
    cancelModalRef.value?.close();
    useAlert(t('BILLING_SETTINGS.ALERTS.SUBSCRIPTION_CANCELLED'));
    await store.dispatch('accounts/subscription');
  } catch {
    // Error already handled
  }
};

// Purchase credits
const openPurchaseCreditsModal = async () => {
  await store.dispatch('accounts/fetchTopupOptions');
  purchaseCreditsModalRef.value?.open();
};

const handlePurchaseCredits = async option => {
  try {
    await store.dispatch('accounts/purchaseCredits', {
      credits: option.credits,
    });
    purchaseCreditsModalRef.value?.close();
    useAlert(t('BILLING_SETTINGS.ALERTS.CREDITS_PURCHASED'));
    fetchCaptainLimits();
  } catch {
    // Error already handled
  }
};

// Credit history
const openCreditHistoryModal = async () => {
  await store.dispatch('accounts/fetchCreditGrants');
  creditHistoryModalRef.value?.open();
};

onMounted(handleBillingPageLogic);
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetchingItem || isWaitingForBilling"
    :loading-message="
      isWaitingForBilling
        ? $t('BILLING_SETTINGS.NO_BILLING_USER')
        : $t('ATTRIBUTES_MGMT.LOADING')
    "
    :no-records-found="!hasABillingPlan && !isWaitingForBilling"
    :no-records-message="$t('BILLING_SETTINGS.NO_BILLING_USER')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('BILLING_SETTINGS.TITLE')"
        :description="$t('BILLING_SETTINGS.DESCRIPTION')"
        feature-name="billing"
      >
        <template #actions>
          <Button
            solid
            blue
            sm
            :label="$t('BILLING_SETTINGS.BILLING_PORTAL')"
            :is-loading="uiFlags.isCheckoutInProcess"
            @click="openBillingPortal"
          />
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <section class="flex flex-col gap-6">
        <a
          href="https://www.chatwoot.com/pricing"
          target="_blank"
          rel="noopener noreferrer"
          class="inline-flex items-center gap-1 text-sm font-medium text-n-blue-text hover:underline"
        >
          {{ $t('BILLING_SETTINGS.VIEW_ALL_PLANS') }}
          <span class="i-lucide-chevron-right size-4" />
        </a>

        <!-- Subscription Card -->
        <BillingCard
          :title="$t('BILLING_SETTINGS.SUBSCRIPTION.TITLE')"
          :description="$t('BILLING_SETTINGS.SUBSCRIPTION.DESCRIPTION')"
        >
          <div class="px-5">
            <SubscriptionRow
              :label="$t('BILLING_SETTINGS.SUBSCRIPTION.CURRENT_PLAN')"
              :value="planName"
              :action-text="$t('BILLING_SETTINGS.SUBSCRIPTION.CHANGE_PLAN')"
              :action-disabled="isCancelled"
              @action="openChangePlanModal"
            />

            <SubscriptionRow
              :label="$t('BILLING_SETTINGS.SUBSCRIPTION.NUMBER_OF_SEATS')"
              :value="subscribedQuantity"
              :action-text="$t('BILLING_SETTINGS.SUBSCRIPTION.CHANGE_SEATS')"
              :show-action="
                !isEditingSeats && !isCancelled && hasActiveSubscription
              "
              @action="startEditingSeats"
            >
              <template v-if="isEditingSeats" #value>
                <SeatStepper
                  v-model="editedSeats"
                  :min="1"
                  :is-loading="uiFlags.isChangingPlan"
                  @save="saveSeats"
                  @cancel="cancelEditingSeats"
                />
              </template>
            </SubscriptionRow>

            <SubscriptionRow
              v-if="isCancelled"
              :label="$t('BILLING_SETTINGS.SUBSCRIPTION.CANCELLED_ON')"
              :value="subscriptionCancelledAt"
            />

            <SubscriptionRow
              v-if="hasActiveSubscription"
              :label="
                isCancelled
                  ? $t('BILLING_SETTINGS.SUBSCRIPTION.ENDS_ON')
                  : $t('BILLING_SETTINGS.SUBSCRIPTION.RENEWS_ON')
              "
              :value="subscriptionEndsAt"
              :action-text="
                isCancelled
                  ? ''
                  : $t('BILLING_SETTINGS.SUBSCRIPTION.CANCEL_SUBSCRIPTION')
              "
              @action="openCancelModal"
            />
          </div>
        </BillingCard>

        <!-- Captain AI Card -->
        <BillingCard
          v-if="captainEnabled"
          :title="$t('BILLING_SETTINGS.CAPTAIN_AI.TITLE')"
          :description="$t('BILLING_SETTINGS.CAPTAIN_AI.DESCRIPTION')"
        >
          <template #action>
            <Button
              solid
              slate
              sm
              :label="$t('BILLING_SETTINGS.CAPTAIN_AI.PURCHASE_CREDITS')"
              @click="openPurchaseCreditsModal"
            />
          </template>
          <div class="px-5">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CAPTAIN_AI.AI_CREDITS')"
              :consumed="creditsUsed"
              :total-count="creditsTotal"
            />
          </div>
          <div class="px-5 pt-2">
            <button
              type="button"
              class="text-sm font-medium text-n-slate-11 hover:text-n-slate-12 hover:underline"
              @click="openCreditHistoryModal"
            >
              {{ $t('BILLING_SETTINGS.CAPTAIN_AI.VIEW_HISTORY') }}
            </button>
          </div>
        </BillingCard>

        <!-- Captain AI Upgrade Card (when not enabled) -->
        <BillingCard
          v-else
          :title="$t('BILLING_SETTINGS.CAPTAIN_AI.TITLE')"
          :description="$t('BILLING_SETTINGS.CAPTAIN.UPGRADE')"
        >
          <template #action>
            <Button
              solid
              slate
              sm
              :label="$t('CAPTAIN.PAYWALL.UPGRADE_NOW')"
              @click="openBillingPortal"
            />
          </template>
        </BillingCard>

        <!-- Help Section -->
        <BillingHeader
          class="px-1 mt-2"
          :title="$t('BILLING_SETTINGS.HELP.TITLE')"
          :description="$t('BILLING_SETTINGS.HELP.DESCRIPTION')"
        >
          <Button
            solid
            slate
            sm
            icon="i-lucide-message-circle"
            :label="$t('BILLING_SETTINGS.HELP.CHAT')"
            @click="openChatWidget"
          />
        </BillingHeader>
      </section>

      <!-- Modals -->
      <ChangePlanModal
        ref="changePlanModalRef"
        :plans="pricingPlans"
        :current-plan-id="currentPlanId"
        :is-loading="uiFlags.isChangingPlan || uiFlags.isSubscribing"
        :is-subscribe-mode="!hasActiveSubscription"
        @select="handlePlanSelect"
      />

      <CancelSubscriptionModal
        ref="cancelModalRef"
        :plan-name="planName"
        :renews-on="subscriptionEndsAt"
        :is-loading="uiFlags.isCancellingSubscription"
        @confirm="handleCancelConfirm"
      />

      <PurchaseCreditsModal
        ref="purchaseCreditsModalRef"
        :options="topupOptions"
        :is-loading="uiFlags.isPurchasingCredits"
        @purchase="handlePurchaseCredits"
      />

      <CreditHistoryModal
        ref="creditHistoryModalRef"
        :credit-grants="creditGrants"
        :is-loading="uiFlags.isFetchingCreditGrants"
      />
    </template>
  </SettingsLayout>
</template>
