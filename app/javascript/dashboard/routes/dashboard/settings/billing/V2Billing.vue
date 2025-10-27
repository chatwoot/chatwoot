<script>
// Global cache keyed by account ID to survive remounts
const accountDataCache = {};

export default {
  name: 'V2Billing',
};
</script>

<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';

import BillingCard from './components/BillingCard.vue';
import DetailItem from './components/DetailItem.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';
import ConfirmationModal from 'dashboard/components/widgets/modal/ConfirmationModal.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import BillingTopupModal from './components/BillingTopupModal.vue';

const router = useRouter();
const { t } = useI18n();
const { currentAccount, isOnChatwootCloud } = useAccount();
const store = useStore();

const confirmationModal = ref(null);
const pricingPlans = ref([]);
const creditBalance = ref(null);
const subscribingPlanId = ref(null);
const isTopupModalOpen = ref(false);
const planQuantities = ref({});
const isLocallyFetching = ref(true); // Local loading state

const uiFlags = computed(() => store.getters['accounts/getUIFlags'] || {});
const isFetchingPlans = computed(() => Boolean(isLocallyFetching.value));
const isUpdating = computed(() => Boolean(uiFlags.value?.isUpdating));
const isCheckoutInProcess = computed(() =>
  Boolean(uiFlags.value?.isCheckoutInProcess)
);
const topupUiFlags = computed(() => store.getters['billingV2/uiFlags'] || {});
const isTopupProcessing = computed(() =>
  Boolean(topupUiFlags.value.isProcessing)
);
const topupOptions = computed(
  () => store.getters['billingV2/topupOptions'] || []
);

const customAttributes = computed(
  () => currentAccount.value.custom_attributes || {}
);
const isV2Billing = computed(
  () => customAttributes.value.stripe_billing_version === 2
);
const currentPlanId = computed(
  () => customAttributes.value.stripe_pricing_plan_id
);
const subscriptionStatus = computed(
  () => customAttributes.value.subscription_status
);
const hasActivePlan = computed(() => {
  // Must have both plan ID and active subscription status
  return Boolean(currentPlanId.value) && subscriptionStatus.value === 'active';
});
const canCancelSubscription = computed(
  () => isV2Billing.value && subscriptionStatus.value === 'active'
);

const planDisplayOrder = ['Hacker', 'Startup', 'Business', 'Enterprise'];
const orderedPlans = computed(() => {
  const plans = Array.isArray(pricingPlans.value)
    ? [...pricingPlans.value]
    : [];
  return plans
    .filter(plan => plan && plan.display_name)
    .sort((a, b) => {
      const indexA = planDisplayOrder.indexOf(a.display_name);
      const indexB = planDisplayOrder.indexOf(b.display_name);

      if (indexA === -1 && indexB === -1) {
        return a.display_name.localeCompare(b.display_name);
      }
      if (indexA === -1) return 1;
      if (indexB === -1) return -1;
      return indexA - indexB;
    });
});

const findComponent = (components, type) => {
  if (!Array.isArray(components)) return null;
  return components.find(component => component.type === type);
};

const extractCreditAmount = components => {
  const serviceAction = findComponent(components, 'service_action');
  return Number(serviceAction?.credit_amount) || 0;
};

const extractCreditUnit = components => {
  const serviceAction = findComponent(components, 'service_action');
  return (
    serviceAction?.credit_unit ||
    t('BILLING_SETTINGS.V2_BILLING.PLAN_CARD.DEFAULT_UNIT')
  );
};

const extractBaseFee = components => {
  const licenseFee = findComponent(components, 'license_fee');
  return Number(licenseFee?.unit_amount) || 0;
};

const planCurrency = plan => plan?.currency || 'usd';

const formatCurrency = (amount, currency = 'usd') => {
  const safeAmount = Number.isFinite(amount) ? amount : 0;
  return new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: (currency || 'usd').toUpperCase(),
    minimumFractionDigits: safeAmount % 1 === 0 ? 0 : 2,
    maximumFractionDigits: 2,
  }).format(safeAmount);
};

const formatNumber = amount => {
  const safeAmount = Number.isFinite(amount) ? amount : 0;
  return new Intl.NumberFormat().format(safeAmount);
};

const getPlanSummary = plan => {
  const baseFee = extractBaseFee(plan.components);
  const credits = formatNumber(extractCreditAmount(plan.components));
  const creditUnit = extractCreditUnit(plan.components);

  if (baseFee > 0) {
    return t('BILLING_SETTINGS.V2_BILLING.PLAN_CARD.SUMMARY_WITH_BASE', {
      credits,
      creditUnit,
      baseFee: formatCurrency(baseFee, planCurrency(plan)),
    });
  }

  return t('BILLING_SETTINGS.V2_BILLING.PLAN_CARD.SUMMARY_FREE', {
    credits,
    creditUnit,
  });
};

const getPlanHighlights = plan => {
  const highlights = [];
  const credits = extractCreditAmount(plan.components);
  const creditUnit = extractCreditUnit(plan.components);
  const baseFee = extractBaseFee(plan.components);

  if (credits > 0) {
    highlights.push(
      t('BILLING_SETTINGS.V2_BILLING.PLAN_CARD.HIGHLIGHT_INCLUDED', {
        credits: formatNumber(credits),
        unit: creditUnit,
      })
    );
  }

  if (baseFee > 0) {
    highlights.push(
      t('BILLING_SETTINGS.V2_BILLING.PLAN_CARD.HIGHLIGHT_BASE_FEE', {
        amount: formatCurrency(baseFee, planCurrency(plan)),
      })
    );
  } else {
    highlights.push(
      t('BILLING_SETTINGS.V2_BILLING.PLAN_CARD.HIGHLIGHT_NO_BASE_FEE')
    );
  }

  return highlights;
};

const planPriceLabel = plan => {
  const baseFee = extractBaseFee(plan.components);
  if (baseFee > 0) {
    return formatCurrency(baseFee, planCurrency(plan));
  }
  return t('BILLING_SETTINGS.V2_BILLING.PLAN_CARD.PRICE_FREE');
};

const baseFeeDetailValue = plan => {
  const baseFee = extractBaseFee(plan.components);
  if (baseFee > 0) {
    return t('BILLING_SETTINGS.V2_BILLING.PLAN_CARD.BASE_FEE_VALUE', {
      amount: formatCurrency(baseFee, planCurrency(plan)),
    });
  }
  return t('BILLING_SETTINGS.V2_BILLING.PLAN_CARD.BASE_FEE_VALUE_FREE');
};

const isCurrentPlan = plan => currentPlanId.value === plan.id;

const actionLabelForPlan = plan => {
  if (isCurrentPlan(plan)) {
    return t('BILLING_SETTINGS.V2_BILLING.PLAN_CARD.CTA_CURRENT');
  }
  if (hasActivePlan.value) {
    return t('BILLING_SETTINGS.V2_BILLING.PLAN_CARD.CTA_SWITCH');
  }
  return t('BILLING_SETTINGS.V2_BILLING.PLAN_CARD.CTA_SELECT');
};

const isPlanLoading = plan => subscribingPlanId.value === plan.id;

const isPlanActionDisabled = plan => {
  if (isCurrentPlan(plan)) return true;
  if (subscribingPlanId.value && subscribingPlanId.value !== plan.id)
    return true;
  return isUpdating.value;
};

const getAccountCache = () => {
  const accountId = currentAccount.value.id;
  if (!accountDataCache[accountId]) {
    accountDataCache[accountId] = {
      dataFetched: false,
      pricingPlans: [],
      creditBalance: null,
    };
  }
  return accountDataCache[accountId];
};

const fetchPricingPlans = async () => {
  try {
    const response = await store.dispatch('accounts/getV2PricingPlans');
    const plans = response.pricing_plans || [];
    const cache = getAccountCache();
    cache.pricingPlans = plans;
    pricingPlans.value = plans;
  } catch (error) {
    useAlert(
      error?.message || t('BILLING_SETTINGS.V2_BILLING.ERRORS.FETCH_PLANS')
    );
    // eslint-disable-next-line no-console
    console.error('Failed to fetch pricing plans:', error);
  }
};

const fetchCreditBalance = async () => {
  if (!isV2Billing.value) return;

  try {
    const response = await store.dispatch('accounts/getCreditBalance');
    const cache = getAccountCache();
    cache.creditBalance = response;
    creditBalance.value = response;
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Failed to fetch credit balance:', error);
  }
};

const onOpenPortal = async () => {
  try {
    await store.dispatch('accounts/checkout');
  } catch (error) {
    useAlert(error?.message || t('BILLING_SETTINGS.V2_BILLING.ERRORS.PORTAL'));
  }
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

const onCloseTopup = () => {
  isTopupModalOpen.value = false;
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
  } catch (error) {
    useAlert(
      error?.message ||
        t('BILLING_SETTINGS.V2_BILLING.TOPUP.ERROR', {
          credits: formatNumber(credits),
        })
    );
  } finally {
    isTopupModalOpen.value = false;
    await Promise.all([store.dispatch('accounts/get'), fetchCreditBalance()]);
  }
};

const onToggleTopupModal = value => {
  isTopupModalOpen.value = value;
};

const getPlanQuantity = plan => {
  return planQuantities.value[plan.id] || 1;
};

const setPlanQuantity = (plan, quantity) => {
  const qty = parseInt(quantity, 10);
  if (qty > 0 && qty <= 100) {
    planQuantities.value[plan.id] = qty;
  }
};

const onSelectPlan = async plan => {
  if (!plan || isPlanActionDisabled(plan)) return;

  subscribingPlanId.value = plan.id;
  const quantity = getPlanQuantity(plan);

  try {
    // Use v2_subscribe for both new subscriptions and plan changes
    const response = await store.dispatch('accounts/subscribeToV2Plan', {
      pricing_plan_id: plan.id,
      quantity: quantity,
    });

    // Redirect to Stripe Checkout
    if (response.redirect_url) {
      window.location.href = response.redirect_url;
    } else if (response.success) {
      useAlert(
        t('BILLING_SETTINGS.V2_BILLING.PLAN_UPDATE.SUCCESS', {
          plan: plan.display_name,
        })
      );
      await Promise.all([store.dispatch('accounts/get'), fetchCreditBalance()]);
    }
  } catch (error) {
    useAlert(
      error?.message ||
        t('BILLING_SETTINGS.V2_BILLING.PLAN_UPDATE.ERROR', {
          plan: plan.display_name,
        })
    );
    subscribingPlanId.value = null;
  }
};

const onCancelSubscription = async () => {
  try {
    const confirmed = await confirmationModal.value.showConfirmation();
    if (!confirmed) return;

    // Cancel at period end - subscription remains active until billing period ends
    const response = await store.dispatch('accounts/cancelSubscription', {});

    if (response.period_end) {
      const periodEndDate = new Date(response.period_end).toLocaleDateString();
      useAlert(
        t('BILLING_SETTINGS.V2_BILLING.CANCEL_SUBSCRIPTION.SUCCESS_WITH_DATE', {
          date: periodEndDate,
        })
      );
    } else {
      useAlert(t('BILLING_SETTINGS.V2_BILLING.CANCEL_SUBSCRIPTION.SUCCESS'));
    }

    await store.dispatch('accounts/get');
    await fetchCreditBalance();
  } catch (error) {
    useAlert(
      error?.message ||
        t('BILLING_SETTINGS.V2_BILLING.CANCEL_SUBSCRIPTION.ERROR')
    );
  }
};

const onBackToBilling = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: currentAccount.value.id },
  });
};

onMounted(async () => {
  // Set loading to false immediately for testing
  isLocallyFetching.value = false;

  // TODO: Temporarily disabled for local testing
  // if (!isOnChatwootCloud.value) {
  //   router.push({ name: 'home' });
  //   return;
  // }

  try {
    // Always refresh account data to ensure we have latest billing info with timeout
    const accountTimeout = new Promise((_, reject) =>
      setTimeout(() => reject(new Error('Account fetch timeout')), 5000)
    );
    await Promise.race([store.dispatch('accounts/get'), accountTimeout]);

    // Handle return from Stripe Checkout
    const purchaseStatus = router.currentRoute.value.query.purchase;
    if (purchaseStatus === 'success') {
      useAlert(t('BILLING_SETTINGS.V2_BILLING.CHECKOUT_SUCCESS'));
      // Remove query parameter
      router.replace({
        name: router.currentRoute.value.name,
        params: router.currentRoute.value.params,
      });
    } else if (purchaseStatus === 'cancelled') {
      useAlert(t('BILLING_SETTINGS.V2_BILLING.CHECKOUT_CANCELLED'));
      // Remove query parameter
      router.replace({
        name: router.currentRoute.value.name,
        params: router.currentRoute.value.params,
      });
    }

    const cache = getAccountCache();
    const shouldFetchPlans = !cache.dataFetched || !cache.pricingPlans?.length;

    if (shouldFetchPlans) {
      cache.dataFetched = true;
      try {
        // Add timeout to prevent indefinite hanging
        const timeoutPromise = new Promise((_, reject) =>
          setTimeout(() => reject(new Error('Request timeout')), 10000)
        );

        await Promise.race([
          Promise.all([
            fetchPricingPlans(),
            fetchCreditBalance(),
            fetchTopupOptions(),
          ]),
          timeoutPromise
        ]);
      } catch (error) {
        cache.dataFetched = false;
        // eslint-disable-next-line no-console
        console.error('Failed to fetch billing data:', error);
      }
    } else {
      pricingPlans.value = cache.pricingPlans;
      creditBalance.value = cache.creditBalance;
      await fetchTopupOptions();
    }
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error in onMounted:', error);
  } finally {
    // Always set loading to false after mount completes
    isLocallyFetching.value = false;
  }
});
</script>

<template>
  <SettingsLayout>
    <template #header>
      <BaseSettingsHeader
        :title="$t('BILLING_SETTINGS.V2_BILLING.TITLE')"
        :description="$t('BILLING_SETTINGS.V2_BILLING.DESCRIPTION')"
        :link-text="$t('BILLING_SETTINGS.VIEW_PRICING')"
        feature-name="billing"
      />
    </template>
    <template #body>
      <section class="space-y-6">
        <div
          class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between"
        >
          <ButtonV4
            sm
            faded
            slate
            icon="i-lucide-arrow-left"
            @click="onBackToBilling"
          >
            {{ $t('BILLING_SETTINGS.V2_BILLING.BACK_TO_BILLING') }}
          </ButtonV4>
          <ButtonV4
            sm
            solid
            blue
            icon="i-lucide-credit-card"
            :is-loading="isCheckoutInProcess"
            :disabled="isCheckoutInProcess"
            @click="onOpenPortal"
          >
            {{ $t('BILLING_SETTINGS.V2_BILLING.MANAGE_PAYMENT_METHOD') }}
          </ButtonV4>
        </div>

        <BillingCard
          v-if="isV2Billing"
          :title="$t('BILLING_SETTINGS.V2_BILLING.CREDIT_BALANCE.TITLE')"
          :description="
            $t('BILLING_SETTINGS.V2_BILLING.CREDIT_BALANCE.DESCRIPTION')
          "
        >
          <div v-if="isFetchingPlans" class="flex justify-center py-8">
            <Spinner :size="24" class="text-n-brand" />
          </div>
          <div v-else class="space-y-4">
            <div
              v-if="hasActivePlan"
              class="grid grid-cols-1 gap-2 divide-y divide-n-weak border-b border-n-weak pb-4 sm:grid-cols-2 sm:divide-y-0 sm:divide-x"
            >
              <DetailItem
                :label="
                  $t('BILLING_SETTINGS.V2_BILLING.CREDIT_BALANCE.PLAN_NAME')
                "
                :value="customAttributes.plan_name || 'No active plan'"
              />
              <DetailItem
                :label="
                  $t(
                    'BILLING_SETTINGS.V2_BILLING.CREDIT_BALANCE.SUBSCRIBED_SEATS'
                  )
                "
                :value="formatNumber(customAttributes.subscribed_quantity || 1)"
              />
            </div>
            <div
              class="grid grid-cols-1 gap-2 divide-y divide-n-weak sm:grid-cols-3 sm:divide-y-0 sm:divide-x"
            >
              <DetailItem
                :label="
                  $t(
                    'BILLING_SETTINGS.V2_BILLING.CREDIT_BALANCE.MONTHLY_CREDITS'
                  )
                "
                :value="formatNumber(creditBalance?.monthly_credits || 0)"
              />
              <DetailItem
                :label="
                  $t('BILLING_SETTINGS.V2_BILLING.CREDIT_BALANCE.TOPUP_CREDITS')
                "
                :value="formatNumber(creditBalance?.topup_credits || 0)"
              />
              <DetailItem
                :label="
                  $t(
                    'BILLING_SETTINGS.V2_BILLING.CREDIT_BALANCE.TOTAL_AVAILABLE'
                  )
                "
                :value="formatNumber(creditBalance?.total_credits || 0)"
              />
            </div>
            <div
              v-if="creditBalance?.usage_this_month !== undefined || creditBalance?.usage_total !== undefined"
              class="border-t border-n-weak pt-4"
            >
              <div
                class="grid grid-cols-1 gap-2 divide-y divide-n-weak sm:grid-cols-2 sm:divide-y-0 sm:divide-x"
              >
                <DetailItem
                  :label="
                    $t(
                      'BILLING_SETTINGS.V2_BILLING.CREDIT_BALANCE.USAGE_THIS_MONTH'
                    )
                  "
                  :value="formatNumber(creditBalance?.usage_this_month || 0)"
                />
                <DetailItem
                  :label="
                    $t('BILLING_SETTINGS.V2_BILLING.CREDIT_BALANCE.USAGE_TOTAL')
                  "
                  :value="formatNumber(creditBalance?.usage_total || 0)"
                />
              </div>
            </div>
          </div>
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
              <ButtonV4
                v-if="canCancelSubscription"
                sm
                faded
                red
                icon="i-lucide-x-circle"
                :disabled="isUpdating"
                :is-loading="isUpdating && !subscribingPlanId"
                @click="onCancelSubscription"
              >
                {{
                  $t(
                    'BILLING_SETTINGS.V2_BILLING.CANCEL_SUBSCRIPTION.BUTTON_TXT'
                  )
                }}
              </ButtonV4>
            </div>
          </template>
        </BillingCard>

        <section class="space-y-4">
          <div
            class="flex flex-col gap-1 sm:flex-row sm:items-end sm:justify-between"
          >
            <div>
              <h2 class="text-lg font-semibold text-n-900 dark:text-n-100">
                {{ $t('BILLING_SETTINGS.V2_BILLING.PLAN_SECTION.TITLE') }}
              </h2>
              <p class="text-sm text-n-slate-11">
                {{ $t('BILLING_SETTINGS.V2_BILLING.PLAN_SECTION.DESCRIPTION') }}
              </p>
            </div>
          </div>
          <p class="text-xs text-n-slate-10">
            {{ $t('BILLING_SETTINGS.V2_BILLING.PLAN_SECTION.HELP_TEXT') }}
          </p>

          <div v-if="isFetchingPlans" class="flex justify-center py-16">
            <Spinner :size="32" class="text-n-brand" />
          </div>
          <div
            v-else-if="!orderedPlans.length"
            class="rounded-2xl border border-dashed border-n-weak bg-n-solid-1 px-6 py-10 text-center text-sm text-n-slate-11"
          >
            {{ $t('BILLING_SETTINGS.V2_BILLING.NO_PLANS_AVAILABLE') }}
          </div>
          <div v-else class="grid gap-4 lg:grid-cols-2">
            <div
              v-for="plan in orderedPlans"
              :key="plan.id"
              class="transition-all duration-200"
              :class="[
                isCurrentPlan(plan)
                  ? 'rounded-2xl ring-2 ring-n-brand shadow-lg'
                  : 'rounded-2xl hover:shadow-md',
              ]"
            >
              <BillingCard
                :title="plan.display_name"
                :description="getPlanSummary(plan)"
              >
                <template #action>
                  <div class="flex flex-col gap-3 sm:flex-row sm:items-center">
                    <div
                      v-if="isCurrentPlan(plan)"
                      class="inline-flex items-center gap-2 rounded-lg border border-green-200 bg-green-50 px-3 py-1.5 text-sm font-medium text-green-700 dark:border-green-800 dark:bg-green-900/20 dark:text-green-300"
                    >
                      <span class="i-lucide-check-circle text-base" />
                      {{ $t('BILLING_SETTINGS.V2_BILLING.CURRENT_PLAN') }}
                    </div>
                    <template v-else>
                      <div class="flex items-center gap-2">
                        <label
                          class="text-sm font-medium text-n-slate-11"
                          :for="`seats-${plan.id}`"
                        >
                          Seats:
                        </label>
                        <input
                          :id="`seats-${plan.id}`"
                          type="number"
                          min="1"
                          max="100"
                          :value="getPlanQuantity(plan)"
                          class="w-20 rounded-lg border border-n-weak bg-n-solid-1 px-3 py-1.5 text-sm text-n-slate-12 focus:border-n-brand focus:outline-none focus:ring-1 focus:ring-n-brand"
                          @input="e => setPlanQuantity(plan, e.target.value)"
                        />
                      </div>
                      <ButtonV4
                        sm
                        solid
                        blue
                        icon="i-lucide-shopping-cart"
                        :disabled="isPlanActionDisabled(plan)"
                        :is-loading="isPlanLoading(plan)"
                        @click="onSelectPlan(plan)"
                      >
                        {{ actionLabelForPlan(plan) }}
                      </ButtonV4>
                    </template>
                  </div>
                </template>

                <div class="space-y-5 px-5 pb-5">
                  <div class="flex flex-wrap items-baseline gap-2">
                    <span class="text-3xl font-semibold text-n-slate-12">
                      {{ planPriceLabel(plan) }}
                    </span>
                    <span class="text-sm text-n-slate-11">
                      {{
                        $t('BILLING_SETTINGS.V2_BILLING.PLAN_CARD.PER_MONTH')
                      }}
                    </span>
                  </div>
                  <ul class="space-y-2 text-sm text-n-slate-12">
                    <li
                      v-for="(highlight, index) in getPlanHighlights(plan)"
                      :key="`${plan.id}-highlight-${index}`"
                      class="flex items-start gap-2"
                    >
                      <span
                        class="i-lucide-check mt-0.5 text-base text-n-brand"
                        aria-hidden="true"
                      />
                      <span class="leading-5">
                        {{ highlight }}
                      </span>
                    </li>
                  </ul>
                  <div
                    class="grid gap-2 border-t border-n-weak pt-4 sm:grid-cols-2"
                  >
                    <DetailItem
                      :label="
                        $t(
                          'BILLING_SETTINGS.V2_BILLING.PLAN_CARD.BASE_FEE_LABEL'
                        )
                      "
                      :value="baseFeeDetailValue(plan)"
                    />
                    <DetailItem
                      :label="
                        $t(
                          'BILLING_SETTINGS.V2_BILLING.PLAN_CARD.MONTHLY_CREDITS_LABEL'
                        )
                      "
                      :value="
                        formatNumber(extractCreditAmount(plan.components))
                      "
                    />
                  </div>
                </div>
              </BillingCard>
            </div>
          </div>
        </section>
      </section>
    </template>
  </SettingsLayout>

  <ConfirmationModal
    ref="confirmationModal"
    :title="$t('BILLING_SETTINGS.V2_BILLING.CANCEL_SUBSCRIPTION.CONFIRM_TITLE')"
    :description="
      $t('BILLING_SETTINGS.V2_BILLING.CANCEL_SUBSCRIPTION.CONFIRM_DESCRIPTION')
    "
    :confirm-label="
      $t('BILLING_SETTINGS.V2_BILLING.CANCEL_SUBSCRIPTION.CONFIRM_LABEL')
    "
    :cancel-label="
      $t('BILLING_SETTINGS.V2_BILLING.CANCEL_SUBSCRIPTION.CANCEL_LABEL')
    "
  />

  <BillingTopupModal
    :model-value="isTopupModalOpen"
    :options="topupOptions"
    :is-loading="isTopupProcessing"
    @update:model-value="onToggleTopupModal"
    @confirm="onPurchaseTopup"
  />
</template>
