<script setup>
import { computed, onMounted, ref } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useSubscription } from 'dashboard/composables/useSubscription';
import { useAlert } from 'dashboard/composables';
import { format } from 'date-fns';
import subscriptionAPI from 'dashboard/api/subscription';

import BillingCard from './components/BillingCard.vue';
import DetailItem from './components/DetailItem.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ButtonV4 from 'next/button/Button.vue';

const { currentAccount, accountScopedRoute } = useAccount();
const { currentTier, currentTierDisplayName, isBasicTier } = useSubscription();

const uiFlags = useMapGetter('accounts/getUIFlags');
const store = useStore();
const isManagingSubscription = ref(false);
const customAttributes = computed(() => {
  return currentAccount.value.custom_attributes || {};
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
 * Checks for both Enterprise billing (plan_name) and new subscription system (subscription_tier)
 * @returns {boolean}
 */
const hasABillingPlan = computed(() => {
  // Check for Enterprise billing (plan_name) or new subscription system (always has a tier)
  return !!planName.value || !!currentTier.value;
});

const fetchAccountDetails = async () => {
  // Only fetch Enterprise billing if using Enterprise system (has plan_name)
  if (planName.value && !hasABillingPlan.value) {
    store.dispatch('accounts/subscription');
  }
};

const onClickBillingPortal = () => {
  store.dispatch('accounts/checkout');
};

const onManageSubscription = async () => {
  isManagingSubscription.value = true;
  try {
    const response = await subscriptionAPI.createPortalSession();
    if (response.data.portal_url) {
      window.location.href = response.data.portal_url;
    }
  } catch (error) {
    useAlert(
      error.response?.data?.error || 'Failed to open subscription portal'
    );
  } finally {
    isManagingSubscription.value = false;
  }
};

onMounted(fetchAccountDetails);
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetchingItem"
    :loading-message="$t('ATTRIBUTES_MGMT.LOADING')"
    :no-records-found="!hasABillingPlan"
    :no-records-message="$t('BILLING_SETTINGS.NO_BILLING_USER')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('BILLING_SETTINGS.TITLE')"
        :description="$t('BILLING_SETTINGS.DESCRIPTION')"
        :link-text="$t('BILLING_SETTINGS.VIEW_PRICING')"
        feature-name="billing"
      />
    </template>
    <template #body>
      <section class="grid gap-4">
        <!-- Upgrade Card for Basic Tier Users -->
        <BillingCard
          v-if="isBasicTier"
          :title="$t('SUBSCRIPTION.UPGRADE.TITLE')"
          :description="$t('SUBSCRIPTION.UPGRADE.DESCRIPTION')"
        >
          <template #action>
            <ButtonV4
              sm
              solid
              blue
              @click="$router.push(accountScopedRoute('home'))"
            >
              {{ $t('SUBSCRIPTION.UPGRADE.VIEW_PLANS') }}
            </ButtonV4>
          </template>
          <div
            class="grid lg:grid-cols-3 sm:grid-cols-2 grid-cols-1 gap-2 divide-x divide-n-weak"
          >
            <DetailItem
              :label="$t('SUBSCRIPTION.BILLING.CURRENT_TIER')"
              :value="currentTierDisplayName"
            />
          </div>
        </BillingCard>

        <!-- User Subscription Management -->
        <BillingCard
          v-if="!isBasicTier"
          :title="$t('SUBSCRIPTION.BILLING.TITLE')"
          :description="$t('SUBSCRIPTION.BILLING.DESCRIPTION')"
        >
          <template #action>
            <ButtonV4
              sm
              solid
              blue
              :disabled="isManagingSubscription"
              @click="onManageSubscription"
            >
              {{
                isManagingSubscription
                  ? $t('SUBSCRIPTION.BILLING.MANAGING')
                  : $t('SUBSCRIPTION.BILLING.MANAGE_BUTTON')
              }}
            </ButtonV4>
          </template>
          <div
            class="grid lg:grid-cols-3 sm:grid-cols-2 grid-cols-1 gap-2 divide-x divide-n-weak"
          >
            <DetailItem
              :label="$t('SUBSCRIPTION.BILLING.CURRENT_TIER')"
              :value="currentTierDisplayName"
            />
          </div>
        </BillingCard>

        <!-- Enterprise Billing (only for Chatwoot Cloud Enterprise customers) -->
        <BillingCard
          v-if="planName"
          :title="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.TITLE')"
          :description="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.DESCRIPTION')"
        >
          <template #action>
            <ButtonV4 sm solid blue @click="onClickBillingPortal">
              {{ $t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.BUTTON_TXT') }}
            </ButtonV4>
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
      </section>
    </template>
  </SettingsLayout>
</template>
