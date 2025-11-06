<script setup>
/**
 * BillingWrapper Component
 *
 * This component handles the conditional display of billing UI versions.
 *
 * Logic Flow:
 * 1. If stripe_billing_version === 2 AND stripe_customer_id exists → Show V2 Billing UI
 * 2. If stripe_billing_version === 2 BUT stripe_customer_id is null → Create customer via subscription API, then refresh
 * 3. All other cases (stripe_billing_version !== 2 or null) → Show V1 Billing UI
 *
 * The component ensures backward compatibility by defaulting to V1 billing
 * for all accounts that haven't been migrated to V2.
 */
import { computed, onMounted, ref } from 'vue';
import { useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import sessionStorage from 'shared/helpers/sessionStorage';
import IndexV2 from '../billing-v2/IndexV2.vue';
import Index from './Index.vue';

const store = useStore();
const { currentAccount } = useAccount();

const BILLING_CUSTOMER_CREATION_ATTEMPTED = 'billing_customer_creation_attempted';
const isCreatingCustomer = ref(false);

const customAttributes = computed(() => {
  return currentAccount.value?.custom_attributes || {};
});

const stripeCustomerId = computed(() => {
  return customAttributes.value.stripe_customer_id;
});

const stripeBillingVersion = computed(() => {
  return customAttributes.value.stripe_billing_version;
});

/**
 * Determines if V2 billing UI should be displayed
 * Conditions:
 * 1. stripe_billing_version must equal 2
 * 2. stripe_customer_id must not be null
 */
const shouldShowV2Billing = computed(() => {
  return stripeBillingVersion.value === 2 && !!stripeCustomerId.value;
});

/**
 * Creates Stripe customer if not exists
 * This is called when stripe_customer_id is null
 */
const createStripeCustomer = async () => {
  isCreatingCustomer.value = true;
  try {
    await store.dispatch('accounts/subscription');

    // Show alert asking user to refresh the page
    useAlert('Stripe customer setup initiated. Please refresh the page to continue.');

    // Auto refresh after 3 seconds
    setTimeout(() => {
      window.location.reload();
    }, 3000);
  } catch (error) {
    useAlert('Failed to create Stripe customer. Please try again later.');
    console.error('Error creating Stripe customer:', error);
  } finally {
    isCreatingCustomer.value = false;
  }
};

onMounted(async () => {
  // Check if we need to create Stripe customer for V2 billing
  if (stripeBillingVersion.value === 2 && !stripeCustomerId.value) {
    const customerCreationAttempted = sessionStorage.get(BILLING_CUSTOMER_CREATION_ATTEMPTED);

    // Only attempt once per session to avoid infinite loops
    if (!customerCreationAttempted) {
      sessionStorage.set(BILLING_CUSTOMER_CREATION_ATTEMPTED, true);
      await createStripeCustomer();
    }
  }
});
</script>

<template>
  <div v-if="isCreatingCustomer" class="flex items-center justify-center p-8">
    <div class="text-center">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-woot-500 mx-auto mb-4"></div>
      <p class="text-slate-600">Setting up your billing account...</p>
      <p class="text-sm text-slate-500 mt-2">This will only take a moment.</p>
    </div>
  </div>

  <!-- Show V2 Billing UI when conditions are met -->
  <IndexV2 v-else-if="shouldShowV2Billing" />

  <!-- Show V1 Billing UI as fallback -->
  <Index v-else />
</template>
