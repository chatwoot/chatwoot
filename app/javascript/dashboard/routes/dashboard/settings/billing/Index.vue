<script setup>
import { computed, onMounted, ref } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { format } from 'date-fns';

import BillingMeter from './components/BillingMeter.vue';
import BillingCard from './components/BillingCard.vue';
import BillingHeader from './components/BillingHeader.vue';
import DetailItem from './components/DetailItem.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ButtonV4 from 'next/button/Button.vue';

const store = useStore();
const uiFlags = useMapGetter('accounts/getUIFlags');
const saasPlans = useMapGetter('accounts/getSaasPlans');

const billingData = ref(null);
const isLoading = ref(true);

const currentPlan = computed(() => billingData.value?.plan);
const subscription = computed(() => billingData.value?.subscription);
const usage = computed(() => billingData.value?.usage);

const hasSubscription = computed(
  () => subscription.value && subscription.value.status !== 'canceled'
);

const subscriptionStatus = computed(() => subscription.value?.status || '');

const renewsOn = computed(() => {
  if (!subscription.value?.current_period_end) return '';
  return format(new Date(subscription.value.current_period_end), 'dd MMM, yyyy');
});

const formatTokens = value => {
  if (!value && value !== 0) return '0';
  if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(1)}M`;
  if (value >= 1_000) return `${(value / 1_000).toFixed(0)}K`;
  return String(value);
};

const fetchBillingData = async () => {
  isLoading.value = true;
  try {
    await Promise.all([
      store.dispatch('accounts/limits'),
      store.dispatch('accounts/fetchPlans'),
    ]);
    // limits action stores data via SET_ACCOUNT_LIMITS mutation;
    // we also read the raw response from the SaaS API
    const SaasAccountAPI = (await import('dashboard/api/saas/account')).default;
    const response = await SaasAccountAPI.getLimits();
    billingData.value = response.data;
  } catch {
    // silent
  } finally {
    isLoading.value = false;
  }
};

const onManageSubscription = () => {
  store.dispatch('accounts/subscription');
};

const onSelectPlan = planId => {
  store.dispatch('accounts/checkout', planId);
};

const onToggleChatWindow = () => {
  if (window.$chatwoot) {
    window.$chatwoot.toggle();
  }
};

onMounted(fetchBillingData);
</script>

<template>
  <SettingsLayout
    :is-loading="isLoading"
    :loading-message="$t('ATTRIBUTES_MGMT.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('BILLING_SETTINGS.TITLE')"
        :description="$t('BILLING_SETTINGS.DESCRIPTION')"
        feature-name="billing"
      />
    </template>
    <template #body>
      <section class="grid gap-4">
        <!-- Current Plan Card -->
        <BillingCard
          :title="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.TITLE')"
          :description="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.DESCRIPTION')"
        >
          <template #action>
            <ButtonV4
              v-if="hasSubscription"
              sm
              solid
              blue
              @click="onManageSubscription"
            >
              {{ $t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.BUTTON_TXT') }}
            </ButtonV4>
          </template>
          <div
            v-if="currentPlan"
            class="grid lg:grid-cols-4 sm:grid-cols-3 grid-cols-1 gap-2 divide-x divide-n-weak"
          >
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.TITLE')"
              :value="currentPlan.name"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.SEAT_COUNT')"
              :value="String(currentPlan.agent_limit)"
            />
            <DetailItem
              v-if="renewsOn"
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.RENEWS_ON')"
              :value="renewsOn"
            />
            <DetailItem
              v-if="subscriptionStatus"
              label="Status"
              :value="subscriptionStatus"
            />
          </div>
        </BillingCard>

        <!-- AI Usage Card -->
        <BillingCard
          v-if="usage"
          title="AI Usage"
          description="Your AI token consumption this billing period"
        >
          <div class="px-5 space-y-4">
            <BillingMeter
              title="AI Tokens"
              :consumed="usage.ai_tokens_used || 0"
              :total-count="usage.ai_tokens_limit || 1"
            />
            <div
              class="grid lg:grid-cols-3 sm:grid-cols-2 grid-cols-1 gap-2 divide-x divide-n-weak"
            >
              <DetailItem
                label="Tokens Used"
                :value="formatTokens(usage.ai_tokens_used)"
              />
              <DetailItem
                label="Tokens Remaining"
                :value="formatTokens(usage.ai_tokens_remaining)"
              />
              <DetailItem label="Agents" :value="String(usage.agents || 0)" />
            </div>
          </div>
        </BillingCard>

        <!-- Available Plans -->
        <BillingHeader
          v-if="saasPlans && saasPlans.length"
          class="px-1 mt-5"
          title="Available Plans"
          description="Choose a plan that fits your needs"
        />
        <div
          v-if="saasPlans && saasPlans.length"
          class="grid lg:grid-cols-3 sm:grid-cols-2 grid-cols-1 gap-4"
        >
          <div
            v-for="plan in saasPlans"
            :key="plan.id"
            class="rounded-xl border border-n-weak bg-n-solid-2 p-5 space-y-3"
            :class="{
              'ring-2 ring-iris-9 border-iris-9':
                currentPlan && currentPlan.id === plan.id,
            }"
          >
            <h3 class="text-lg font-semibold text-n-slate-12">
              {{ plan.name }}
            </h3>
            <p class="text-2xl font-bold text-n-slate-12">
              ${{ (plan.price_cents / 100).toFixed(2) }}
              <span class="text-sm font-normal text-n-slate-10">
                /{{ plan.interval }}
              </span>
            </p>
            <ul class="text-sm text-n-slate-11 space-y-1">
              <li>{{ plan.agent_limit }} agents</li>
              <li>{{ plan.inbox_limit }} inboxes</li>
              <li>{{ formatTokens(plan.ai_tokens_monthly) }} AI tokens/mo</li>
            </ul>
            <ButtonV4
              v-if="!currentPlan || currentPlan.id !== plan.id"
              sm
              solid
              blue
              class="w-full"
              :is-loading="uiFlags.isCheckoutInProcess"
              @click="onSelectPlan(plan.id)"
            >
              Select Plan
            </ButtonV4>
            <div
              v-else
              class="text-center text-sm font-medium text-iris-11 py-2"
            >
              Current Plan
            </div>
          </div>
        </div>

        <!-- Support -->
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
