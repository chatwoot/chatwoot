<script setup>
import { computed, onMounted } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { format } from 'date-fns';

import BillingCard from './components/BillingCard.vue';
import BillingHeader from './components/BillingHeader.vue';
import DetailItem from './components/DetailItem.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ButtonV4 from 'next/button/Button.vue';

const { currentAccount } = useAccount();
const { t } = useI18n();
const route = useRoute();

const uiFlags = useMapGetter('accounts/getUIFlags');
const store = useStore();
const customAttributes = computed(() => {
  return currentAccount.value.custom_attributes || {};
});

/**
 * Computed property for plan name with translation
 * @returns {string|undefined}
 */
const planName = computed(() => {
  const rawPlanName = customAttributes.value.plan_name;
  if (!rawPlanName) return undefined;

  const translationKey = `BILLING_SETTINGS.PLANS.${rawPlanName}`;
  const translatedName = t(translationKey);

  return translatedName !== translationKey ? translatedName : rawPlanName;
});

/**
 * Computed property for subscribed quantity
 * @returns {number|undefined}
 */
const subscribedQuantity = computed(() => {
  return customAttributes.value.subscribed_quantity;
});

const subscriptionRenewsOn = computed(() => {
  // Return '-' if subscription is not active or no end date
  if (
    customAttributes.value.subscription_status !== 'active' ||
    !customAttributes.value.subscription_ends_on
  ) {
    return '-';
  }

  const endDate = new Date(customAttributes.value.subscription_ends_on);
  return format(endDate, 'dd MMM, yyyy');
});

/**
 * Computed property for subscription status with translation
 * @returns {string}
 */
const subscriptionStatus = computed(() => {
  const rawStatus = customAttributes.value.subscription_status;
  if (!rawStatus) return '-';

  const translationKey = `BILLING_SETTINGS.SUBSCRIPTION_STATUS.${rawStatus}`;
  const translatedStatus = t(translationKey);

  return translatedStatus !== translationKey ? translatedStatus : rawStatus;
});

/**
 * Computed property for subscription end date
 * @returns {string}
 */
const subscriptionEndsOn = computed(() => {
  if (!customAttributes.value.subscription_ends_on) return '-';
  const endDate = new Date(customAttributes.value.subscription_ends_on);
  return format(endDate, 'dd MMM, yyyy');
});

/**
 * Computed property indicating if user has a billing plan
 * @returns {boolean}
 */
const hasABillingPlan = computed(() => {
  return !!planName.value;
});

/**
 * Computed property indicating if user has a fully set up billing (with Stripe customer)
 * @returns {boolean}
 */
const hasStripeCustomer = computed(() => {
  return !!customAttributes.value.stripe_customer_id;
});

/**
 * Computed property to determine the appropriate billing button action
 * @returns {object}
 */
const billingButtonConfig = computed(() => {
  const status = customAttributes.value.subscription_status;

  // For inactive subscriptions, treat them as needing a new subscription setup
  if (status === 'inactive') {
    return {
      text: t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.BUTTON_TXT'),
      action: 'create_new',
    };
  }

  // For all other cases (active, cancelled, trialing, etc.), use portal
  return {
    text: t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.BUTTON_TXT'),
    action: 'portal',
  };
});

const fetchAccountDetails = async () => {
  // Always fetch the latest subscription data
  await store.dispatch('accounts/subscription');
  // Fetch limits after subscription data is loaded
  await store.dispatch('accounts/limits');
};

const onClickBillingPortal = async () => {
  await store.dispatch('accounts/checkout');
};

const onCreateSubscription = async (planNameParam = 'free_trial') => {
  try {
    await store.dispatch('accounts/createSubscription', {
      planName: planNameParam,
    });
    // Refresh the account details after creating subscription
    await fetchAccountDetails();
  } catch (error) {
    // Handle error silently or use proper error handling
  }
};

const onBillingButtonClick = async () => {
  if (billingButtonConfig.value.action === 'create_new') {
    await onCreateSubscription('starter');
  } else {
    await onClickBillingPortal();
  }
};

const onToggleChatWindow = () => {
  if (window.$chatwoot) {
    window.$chatwoot.toggle();
  }
};

const checkForCheckoutSuccess = () => {
  if (route.query.success === 'true') {
    setTimeout(async () => {
      await fetchAccountDetails();
    }, 2000);
  }
};

onMounted(() => {
  fetchAccountDetails();
  checkForCheckoutSuccess();
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetchingItem"
    :loading-message="$t('ATTRIBUTES_MGMT.LOADING')"
    :no-records-found="false"
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
        <!-- Setup Subscription Card (for users without billing plans) -->
        <BillingCard
          v-if="!hasABillingPlan"
          :title="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.TITLE')"
          :description="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.DESCRIPTION')"
        >
          <template #action>
            <ButtonV4 sm solid blue @click="onCreateSubscription('starter')">
              {{ $t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.BUTTON_TXT') }}
            </ButtonV4>
          </template>
        </BillingCard>

        <!-- Manage Subscription Card (for users with billing plans) -->
        <BillingCard
          v-if="hasABillingPlan"
          :title="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.TITLE')"
          :description="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.DESCRIPTION')"
        >
          <template #action>
            <ButtonV4
              v-if="hasStripeCustomer"
              sm
              solid
              blue
              @click="onBillingButtonClick"
            >
              {{ billingButtonConfig.text }}
            </ButtonV4>
            <ButtonV4
              v-else
              sm
              solid
              blue
              @click="onCreateSubscription('starter')"
            >
              {{ t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.BUTTON_TXT') }}
            </ButtonV4>
          </template>
          <div
            v-if="planName || subscribedQuantity || subscriptionRenewsOn"
            class="grid lg:grid-cols-5 sm:grid-cols-5 grid-cols-1 gap-2 divide-x divide-n-weak"
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
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.ENDS_ON')"
              :value="subscriptionEndsOn"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.STATUS')"
              :value="subscriptionStatus"
            />
          </div>
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
            @click="onToggleChatWindow"
          >
            {{ $t('BILLING_SETTINGS.CHAT_WITH_US.BUTTON_TXT') }}
          </ButtonV4>
        </BillingHeader>
      </section>
    </template>
  </SettingsLayout>
</template>
