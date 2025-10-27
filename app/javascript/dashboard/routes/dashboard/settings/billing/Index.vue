<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { format } from 'date-fns';
import sessionStorage from 'shared/helpers/sessionStorage';
import { useAlert } from 'dashboard/composables';

import BillingMeter from './components/BillingMeter.vue';
import BillingCard from './components/BillingCard.vue';
import BillingHeader from './components/BillingHeader.vue';
import DetailItem from './components/DetailItem.vue';
import BillingTopupModal from './components/BillingTopupModal.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ButtonV4 from 'next/button/Button.vue';
import ConfirmationModal from 'dashboard/components/widgets/modal/ConfirmationModal.vue';

const router = useRouter();
const { t } = useI18n();
const { currentAccount, isOnChatwootCloud } = useAccount();
const {
  captainEnabled,
  captainLimits,
  documentLimits,
  responseLimits,
  fetchLimits,
} = useCaptain();

const uiFlags = useMapGetter('accounts/getUIFlags');
const store = useStore();

const BILLING_REFRESH_ATTEMPTED = 'billing_refresh_attempted';

const confirmationModal = ref(null);
const isTopupModalOpen = ref(false);

// State for handling refresh attempts and loading
const isWaitingForBilling = ref(false);

const customAttributes = computed(() => {
  return currentAccount.value.custom_attributes || {};
});

/**
 * Check if this is a V2 billing customer
 * @returns {boolean}
 */
const isV2Billing = computed(() => {
  return customAttributes.value.stripe_billing_version === 2;
});

/**
 * Computed property for plan name
 * @returns {string|undefined}
 */
const planName = computed(() => {
  return customAttributes.value.plan_name;
});

/**
 * Computed property for subscribed quantity
 * @returns {number|undefined}
 */
const subscribedQuantity = computed(() => {
  return customAttributes.value.subscribed_quantity;
});

const subscriptionRenewsOn = computed(() => {
  if (!customAttributes.value.subscription_ends_on) return '';
  const endDate = new Date(customAttributes.value.subscription_ends_on);
  // return date as 12 Jan, 2034
  return format(endDate, 'dd MMM, yyyy');
});

/**
 * Computed property indicating if user has a billing plan
 * For V2 billing, we consider billing setup complete if stripe_billing_version is set
 * @returns {boolean}
 */
const hasABillingPlan = computed(() => {
  // For V2 billing, account is considered set up if billing version is set
  if (isV2Billing.value) {
    return true;
  }
  // For V1 billing, need an actual plan name
  return !!planName.value;
});

/**
 * Check if subscription is active and cancellable
 * @returns {boolean}
 */
const canCancelSubscription = computed(() => {
  const status = customAttributes.value.subscription_status;
  return isV2Billing.value && status === 'active';
});

const fetchAccountDetails = async () => {
  // For V2 billing, don't call subscription endpoint (it's for V1 Stripe customer creation)
  // V2 billing accounts are already set up with stripe_billing_version = 2
  if (isV2Billing.value) {
    fetchLimits();
    return;
  }

  // For V1 billing, create Stripe customer if needed
  if (!hasABillingPlan.value) {
    await store.dispatch('accounts/subscription');
    fetchLimits();
  }
};

const handleBillingPageLogic = async () => {
  // If self-hosted, redirect to dashboard
  if (!isOnChatwootCloud.value) {
    router.push({ name: 'home' });
    return;
  }

  // Check if we've already attempted a refresh for billing setup
  const billingRefreshAttempted = sessionStorage.get(BILLING_REFRESH_ATTEMPTED);

  // If cloud user, fetch account details first
  await fetchAccountDetails();

  // If still no billing plan after fetch
  if (!hasABillingPlan.value) {
    // If we haven't attempted refresh yet, do it once
    if (!billingRefreshAttempted) {
      isWaitingForBilling.value = true;
      sessionStorage.set(BILLING_REFRESH_ATTEMPTED, true);

      setTimeout(() => {
        window.location.reload();
      }, 5000);
    } else {
      // We've already tried refreshing, so just show the no billing message
      // Clear the flag for future visits
      sessionStorage.remove(BILLING_REFRESH_ATTEMPTED);
    }
  } else {
    // Billing plan found, clear any existing refresh flag
    sessionStorage.remove(BILLING_REFRESH_ATTEMPTED);
  }
};

const creditBalance = ref(null);
const topupUiFlags = computed(() => store.getters['billingV2/uiFlags'] || {});
const isTopupProcessing = computed(() =>
  Boolean(topupUiFlags.value?.isProcessing)
);
const topupOptions = computed(
  () => store.getters['billingV2/topupOptions'] || []
);

const formatNumber = value =>
  new Intl.NumberFormat().format(Number(value || 0));

const fetchCreditBalance = async () => {
  if (isV2Billing.value) {
    try {
      const response = await store.dispatch('accounts/getCreditBalance');
      creditBalance.value = response;
    } catch (error) {
      console.error('Failed to fetch credit balance:', error);
    }
  }
};

const onClickBillingPortal = () => {
  store.dispatch('accounts/checkout');
};

const fetchTopupOptions = async () => {
  if (!isV2Billing.value) return;
  try {
    await store.dispatch('billingV2/fetchTopupOptions');
  } catch (error) {
    useAlert(
      error?.message || t('BILLING_SETTINGS.V2_BILLING.ERRORS.TOPUP_OPTIONS')
    );
  }
};

const onOpenTopup = async () => {
  if (!topupOptions.value.length) {
    await fetchTopupOptions();
  }
  isTopupModalOpen.value = true;
};

const onToggleTopupModal = value => {
  isTopupModalOpen.value = value;
};

const onPurchaseTopup = async credits => {
  if (!credits || isTopupProcessing.value) return;

  try {
    await store.dispatch('billingV2/purchaseTopup', { credits });

    useAlert(
      t('BILLING_SETTINGS.V2_BILLING.TOPUP.SUCCESS', {
        credits: formatNumber(credits),
      })
    );

    await Promise.all([store.dispatch('accounts/get'), fetchCreditBalance()]);
  } catch (error) {
    useAlert(
      error?.message ||
        t('BILLING_SETTINGS.V2_BILLING.TOPUP.ERROR', {
          credits: formatNumber(credits),
        })
    );
  } finally {
    isTopupModalOpen.value = false;
  }
};

const onToggleChatWindow = () => {
  if (window.$chatwoot) {
    window.$chatwoot.toggle();
  }
};

const onCancelSubscription = async () => {
  try {
    const confirmed = await confirmationModal.value.showConfirmation();
    if (!confirmed) return;

    // Redirect to Stripe billing portal for cancellation
    await store.dispatch('accounts/cancelSubscription');
  } catch (error) {
    useAlert(
      error.message ||
        t('BILLING_SETTINGS.V2_BILLING.CANCEL_SUBSCRIPTION.ERROR')
    );
  }
};

onMounted(async () => {
  await handleBillingPageLogic();
  await fetchCreditBalance();
  await fetchTopupOptions();
});
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
        :link-text="$t('BILLING_SETTINGS.VIEW_PRICING')"
        feature-name="billing"
      >
        <template v-if="isV2Billing" #actions>
          <ButtonV4
            sm
            solid
            blue
            icon="i-lucide-sparkles"
            @click="
              $router.push({
                name: 'billing_settings_v2',
                params: { accountId: currentAccount.id },
              })
            "
          >
            {{ $t('BILLING_SETTINGS.V2_BILLING.TITLE') }}
          </ButtonV4>
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <section class="grid gap-4">
        <BillingCard
          :title="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.TITLE')"
          :description="
            isV2Billing
              ? 'You are using usage-based billing with AI credits. The billing portal provides invoice history, payment method management, and subscription cancellation. To change your plan, please contact support.'
              : $t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.DESCRIPTION')
          "
        >
          <template #action>
            <div class="flex gap-2">
              <ButtonV4
                sm
                solid
                blue
                icon="i-lucide-credit-card"
                @click="onClickBillingPortal"
              >
                {{
                  isV2Billing
                    ? $t('BILLING_SETTINGS.V2_BILLING.MANAGE_BILLING')
                    : $t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.BUTTON_TXT')
                }}
              </ButtonV4>
              <ButtonV4
                v-if="canCancelSubscription"
                sm
                faded
                red
                icon="i-lucide-x-circle"
                @click="onCancelSubscription"
              >
                {{
                  $t(
                    'BILLING_SETTINGS.V2_BILLING.CANCEL_SUBSCRIPTION.BUTTON_TXT'
                  )
                }}
              </ButtonV4>
              <ButtonV4
                v-if="isV2Billing"
                sm
                faded
                slate
                icon="i-lucide-life-buoy"
                @click="onToggleChatWindow"
              >
                {{ $t('BILLING_SETTINGS.V2_BILLING.CONTACT_SUPPORT') }}
              </ButtonV4>
            </div>
          </template>
          <div
            v-if="planName || subscribedQuantity || subscriptionRenewsOn"
            class="grid lg:grid-cols-4 sm:grid-cols-3 grid-cols-1 gap-2 divide-x divide-n-weak"
          >
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.TITLE')"
              :value="planName"
            />
            <DetailItem
              v-if="subscribedQuantity"
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.SEAT_COUNT')"
              :value="subscribedQuantity"
            />
            <DetailItem
              v-if="subscriptionRenewsOn"
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.RENEWS_ON')"
              :value="subscriptionRenewsOn"
            />
          </div>
        </BillingCard>
        <BillingCard
          v-if="isV2Billing && creditBalance"
          :title="$t('BILLING_SETTINGS.V2_BILLING.CREDIT_BALANCE.TITLE')"
          :description="
            $t('BILLING_SETTINGS.V2_BILLING.CREDIT_BALANCE.DESCRIPTION')
          "
        >
          <template #action>
            <div class="flex gap-2">
              <ButtonV4
                sm
                solid
                blue
                icon="i-lucide-plus"
                :disabled="isTopupProcessing"
                :is-loading="isTopupProcessing"
                @click="onOpenTopup"
              >
                {{ $t('BILLING_SETTINGS.V2_BILLING.TOPUP.BUTTON') }}
              </ButtonV4>
            </div>
          </template>
          <div
            class="grid lg:grid-cols-3 sm:grid-cols-2 grid-cols-1 gap-2 divide-x divide-n-weak"
          >
            <DetailItem
              :label="
                $t('BILLING_SETTINGS.V2_BILLING.CREDIT_BALANCE.MONTHLY_CREDITS')
              "
              :value="creditBalance.monthly_credits || 0"
            />
            <DetailItem
              :label="
                $t('BILLING_SETTINGS.V2_BILLING.CREDIT_BALANCE.TOPUP_CREDITS')
              "
              :value="creditBalance.topup_credits || 0"
            />
            <DetailItem
              :label="
                $t('BILLING_SETTINGS.V2_BILLING.CREDIT_BALANCE.TOTAL_AVAILABLE')
              "
              :value="creditBalance.total_credits || 0"
            />
          </div>
        </BillingCard>
        <BillingCard
          v-if="captainEnabled"
          :title="$t('BILLING_SETTINGS.CAPTAIN.TITLE')"
          :description="$t('BILLING_SETTINGS.CAPTAIN.DESCRIPTION')"
        >
          <template #action>
            <ButtonV4 sm faded slate disabled>
              {{ $t('BILLING_SETTINGS.CAPTAIN.BUTTON_TXT') }}
            </ButtonV4>
          </template>
          <div v-if="captainLimits && responseLimits" class="px-5">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CAPTAIN.RESPONSES')"
              v-bind="responseLimits"
            />
          </div>
          <div v-if="captainLimits && documentLimits" class="px-5">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CAPTAIN.DOCUMENTS')"
              v-bind="documentLimits"
            />
          </div>
        </BillingCard>
        <BillingCard
          v-else
          :title="$t('BILLING_SETTINGS.CAPTAIN.TITLE')"
          :description="$t('BILLING_SETTINGS.CAPTAIN.UPGRADE')"
        >
          <template #action>
            <ButtonV4 sm solid slate @click="onClickBillingPortal">
              {{ $t('CAPTAIN.PAYWALL.UPGRADE_NOW') }}
            </ButtonV4>
          </template>
        </BillingCard>

        <BillingHeader
          class="px-1 mt-5"
          :title="$t('BILLING_SETTINGS.CHAT_WITH_US.TITLE')"
          :description="$t('BILLING_SETTINGS.CHAT_WITH_US.DESCRIPTION')"
        >
          <ButtonV4
            sm
            solid
            slate
            icon="i-lucide-life-buoy"
            @open="onToggleChatWindow"
          >
            {{ $t('BILLING_SETTINGS.CHAT_WITH_US.BUTTON_TXT') }}
          </ButtonV4>
        </BillingHeader>
      </section>
    </template>
  </SettingsLayout>

  <ConfirmationModal
    ref="confirmationModal"
    :title="$t('BILLING_SETTINGS.V2_BILLING.CANCEL_SUBSCRIPTION.CONFIRM_TITLE')"
    description="You will be redirected to the Stripe billing portal where you can cancel your subscription. Your subscription will remain active until the end of the current billing period."
    confirm-label="Continue to Billing Portal"
    cancel-label="Cancel"
  />

  <BillingTopupModal
    :model-value="isTopupModalOpen"
    :options="topupOptions"
    :is-loading="isTopupProcessing"
    @update:model-value="onToggleTopupModal"
    @confirm="onPurchaseTopup"
  />
</template>
