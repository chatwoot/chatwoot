<script setup>
import { computed, ref } from 'vue';
import { useSubscription } from 'dashboard/composables/useSubscription';
import { useI18n } from 'vue-i18n';
import subscriptionAPI from 'dashboard/api/subscription';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  featureName: {
    type: String,
    required: true,
  },
  title: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();
const { currentTierDisplayName, requiredTierFor, getTierDisplayName } =
  useSubscription();

const requiredTier = computed(() => requiredTierFor(props.featureName));
const requiredTierName = computed(() => getTierDisplayName(requiredTier.value));
const isUpgrading = ref(false);

const displayTitle = computed(() => {
  return props.title || t('SUBSCRIPTION.PAYWALL.DEFAULT_TITLE');
});

const displayDescription = computed(() => {
  return props.description || t('SUBSCRIPTION.PAYWALL.DEFAULT_DESCRIPTION');
});

const handleUpgrade = async () => {
  isUpgrading.value = true;
  try {
    const response = await subscriptionAPI.createCheckoutSession(
      requiredTier.value
    );
    if (response.data.checkout_url) {
      window.location.href = response.data.checkout_url;
    }
  } catch (error) {
    useAlert(
      error.response?.data?.error || t('SUBSCRIPTION.PAYWALL.UPGRADE_ERROR')
    );
  } finally {
    isUpgrading.value = false;
  }
};
</script>

<template>
  <div
    class="min-h-screen bg-n-solid-1 p-4 overflow-y-auto flex items-center justify-center"
  >
    <div
      class="max-w-md w-full bg-n-solid-2 rounded-lg shadow-lg p-8 border border-n-weak my-8"
    >
      <!-- Icon -->
      <div class="flex justify-center mb-6">
        <div
          class="w-16 h-16 bg-n-solid-3 rounded-full flex items-center justify-center"
        >
          <i class="i-lucide-lock text-3xl text-n-slate-11" />
        </div>
      </div>

      <!-- Title -->
      <h2 class="text-2xl font-semibold text-center mb-4 text-n-slate-12">
        {{ displayTitle }}
      </h2>

      <!-- Description -->
      <p class="text-center text-n-slate-11 mb-6">
        {{ displayDescription }}
      </p>

      <!-- Current & Required Tier -->
      <div class="bg-n-solid-3 rounded-lg p-4 mb-6">
        <div class="flex justify-between items-center mb-2">
          <span class="text-sm text-n-slate-11">{{
            t('SUBSCRIPTION.PAYWALL.CURRENT_PLAN')
          }}</span>
          <span class="font-medium text-n-slate-12">{{
            currentTierDisplayName
          }}</span>
        </div>
        <div class="flex justify-between items-center">
          <span class="text-sm text-n-slate-11">{{
            t('SUBSCRIPTION.PAYWALL.REQUIRED_PLAN')
          }}</span>
          <span class="font-medium text-n-slate-12">{{
            requiredTierName
          }}</span>
        </div>
      </div>

      <!-- Feature Benefits -->
      <div class="mb-6">
        <h3 class="font-medium mb-3 text-n-slate-12">
          {{ t('SUBSCRIPTION.PAYWALL.FEATURES_TITLE') }}
        </h3>
        <ul class="space-y-2">
          <li class="flex items-start">
            <i class="i-lucide-check text-green-500 mr-2 mt-1 flex-shrink-0" />
            <span class="text-sm text-n-slate-11">{{
              t('SUBSCRIPTION.PAYWALL.FEATURE_1')
            }}</span>
          </li>
          <li class="flex items-start">
            <i class="i-lucide-check text-green-500 mr-2 mt-1 flex-shrink-0" />
            <span class="text-sm text-n-slate-11">{{
              t('SUBSCRIPTION.PAYWALL.FEATURE_2')
            }}</span>
          </li>
          <li class="flex items-start">
            <i class="i-lucide-check text-green-500 mr-2 mt-1 flex-shrink-0" />
            <span class="text-sm text-n-slate-11">{{
              t('SUBSCRIPTION.PAYWALL.FEATURE_3')
            }}</span>
          </li>
        </ul>
      </div>

      <!-- CTA Button -->
      <button
        class="w-full bg-woot-500 hover:bg-woot-600 text-white font-medium py-3 px-4 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        :disabled="isUpgrading"
        @click="handleUpgrade"
      >
        <span v-if="isUpgrading">
          {{ t('SUBSCRIPTION.PAYWALL.UPGRADING') }}
        </span>
        <span v-else>
          {{
            t('SUBSCRIPTION.PAYWALL.UPGRADE_BUTTON', { tier: requiredTierName })
          }}
        </span>
      </button>

      <!-- Contact Support Link -->
      <p class="text-center text-sm text-n-slate-11 mt-4">
        {{ t('SUBSCRIPTION.PAYWALL.CONTACT_SUPPORT') }}
      </p>
    </div>
  </div>
</template>
