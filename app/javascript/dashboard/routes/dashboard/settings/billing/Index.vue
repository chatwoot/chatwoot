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
const localPlans = ref([]);
const isLoading = ref(true);
const billingInterval = ref('month');

const currentPlan = computed(() => billingData.value?.plan);
const subscription = computed(() => billingData.value?.subscription);
const usage = computed(() => billingData.value?.usage);

const allPlans = computed(() =>
  saasPlans.value?.length ? saasPlans.value : localPlans.value
);

// Filter plans by interval (monthly vs annual)
const availablePlans = computed(() =>
  allPlans.value.filter(p => p.interval === billingInterval.value)
);

// Get the matching monthly plan for an annual plan (to show savings)
const getMonthlyCounterpart = plan => {
  if (plan.interval !== 'year') return null;
  return allPlans.value.find(
    p => p.interval === 'month' && p.base_name === plan.base_name
  );
};

const hasSubscription = computed(
  () =>
    subscription.value &&
    subscription.value.status !== 'canceled' &&
    subscription.value.stripe_customer_id
);

const subscriptionStatus = computed(() => subscription.value?.status || '');

const renewsOn = computed(() => {
  if (!subscription.value?.current_period_end) return '';
  return format(
    new Date(subscription.value.current_period_end),
    'dd MMM, yyyy'
  );
});

const formatTokens = value => {
  if (!value && value !== 0) return '0';
  if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(1)}M`;
  if (value >= 1_000) return `${(value / 1_000).toFixed(0)}K`;
  return String(value);
};

const formatPrice = cents => (cents / 100).toFixed(2).replace('.', ',');

const annualSavings = plan => {
  const monthly = getMonthlyCounterpart(plan);
  if (!monthly) return null;
  const fullYearPrice = monthly.price_cents * 12;
  return fullYearPrice - plan.price_cents;
};

const monthlyEquivalent = plan => {
  if (plan.interval !== 'year') return null;
  return (plan.price_cents / 12 / 100).toFixed(2).replace('.', ',');
};

const planFeatureLabels = plan => {
  const labels = [];
  const f = plan.features || {};

  if (f.ai_agents) {
    const limit = f.ai_agents_limit;
    labels.push(
      limit === -1
        ? 'BILLING_SETTINGS.PLANS.FEATURE_AI_AGENTS_UNLIMITED'
        : {
            key: 'BILLING_SETTINGS.PLANS.FEATURE_AI_AGENTS',
            params: { count: limit },
          }
    );
  }
  if (f.voice_agents) {
    labels.push({
      key: 'BILLING_SETTINGS.PLANS.FEATURE_VOICE',
      params: { minutes: f.voice_minutes || 0 },
    });
  }
  if (f.workflows) labels.push('BILLING_SETTINGS.PLANS.FEATURE_WORKFLOWS');
  if (f.help_center) {
    const portals = f.help_center_portals;
    labels.push({
      key: 'BILLING_SETTINGS.PLANS.FEATURE_HELP_CENTER',
      params: { portals: portals === -1 ? '∞' : portals },
    });
  }
  if (f.sla) labels.push('BILLING_SETTINGS.PLANS.FEATURE_SLA');
  if (f.audit_logs) labels.push('BILLING_SETTINGS.PLANS.FEATURE_AUDIT_LOGS');
  if (f.white_label) labels.push('BILLING_SETTINGS.PLANS.FEATURE_WHITE_LABEL');
  if (f.saml_sso) labels.push('BILLING_SETTINGS.PLANS.FEATURE_SAML');
  if (f.custom_roles)
    labels.push('BILLING_SETTINGS.PLANS.FEATURE_CUSTOM_ROLES');

  return labels;
};

const fetchBillingData = async () => {
  isLoading.value = true;
  try {
    await Promise.all([
      store.dispatch('accounts/limits'),
      store.dispatch('accounts/fetchPlans'),
    ]);
    const SaasAccountAPI = (await import('dashboard/api/saas/account')).default;
    const [limitsResponse, plansResponse] = await Promise.all([
      SaasAccountAPI.getLimits(),
      SaasAccountAPI.getPlans(),
    ]);
    billingData.value = limitsResponse.data;
    localPlans.value = plansResponse.data;
  } catch {
    // silent
  } finally {
    isLoading.value = false;
  }
};

const onManageSubscription = () => {
  store.dispatch('accounts/subscription');
};

const whatsappSupportUrl = computed(() => {
  const message = encodeURIComponent(
    'Olá! Preciso de ajuda com minha assinatura do AirysChat.'
  );
  return `https://wa.me/5541935005174?text=${message}`;
});

const onSelectPlan = planId => {
  store.dispatch('accounts/checkout', planId);
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
          :title="$t('BILLING_SETTINGS.AI_USAGE.TITLE')"
          :description="$t('BILLING_SETTINGS.AI_USAGE.DESCRIPTION')"
        >
          <div class="px-5 space-y-4">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.AI_USAGE.AI_TOKENS')"
              :consumed="usage.ai_tokens_used || 0"
              :total-count="usage.ai_tokens_limit || 1"
            />
            <div
              class="grid lg:grid-cols-3 sm:grid-cols-2 grid-cols-1 gap-2 divide-x divide-n-weak"
            >
              <DetailItem
                :label="$t('BILLING_SETTINGS.AI_USAGE.TOKENS_USED')"
                :value="formatTokens(usage.ai_tokens_used)"
              />
              <DetailItem
                :label="$t('BILLING_SETTINGS.AI_USAGE.TOKENS_REMAINING')"
                :value="formatTokens(usage.ai_tokens_remaining)"
              />
              <DetailItem
                :label="$t('BILLING_SETTINGS.AI_USAGE.AGENTS')"
                :value="String(usage.agents || 0)"
              />
            </div>
          </div>
        </BillingCard>

        <!-- Available Plans -->
        <BillingHeader
          v-if="allPlans && allPlans.length"
          class="px-1 mt-5"
          :title="$t('BILLING_SETTINGS.PLANS.TITLE')"
          :description="$t('BILLING_SETTINGS.PLANS.DESCRIPTION')"
        />

        <!-- Monthly / Annual Toggle -->
        <div
          v-if="allPlans && allPlans.length"
          class="flex items-center justify-center gap-3 py-2"
        >
          <button
            class="px-4 py-2 rounded-lg text-sm font-medium transition-colors border"
            :class="
              billingInterval === 'month'
                ? 'bg-n-iris-9 text-white border-n-iris-9'
                : 'bg-n-solid-3 text-n-slate-12 border-n-strong hover:bg-n-alpha-3'
            "
            @click="billingInterval = 'month'"
          >
            {{ $t('BILLING_SETTINGS.PLANS.MONTHLY') }}
          </button>
          <button
            class="px-4 py-2 rounded-lg text-sm font-medium transition-colors flex items-center gap-2 border"
            :class="
              billingInterval === 'year'
                ? 'bg-n-iris-9 text-white border-n-iris-9'
                : 'bg-n-solid-3 text-n-slate-12 border-n-strong hover:bg-n-alpha-3'
            "
            @click="billingInterval = 'year'"
          >
            {{ $t('BILLING_SETTINGS.PLANS.ANNUAL') }}
            <span
              class="text-xs px-2 py-0.5 rounded-full"
              :class="
                billingInterval === 'year'
                  ? 'bg-white/20 text-white'
                  : 'bg-green-100 text-green-700'
              "
            >
              {{ $t('BILLING_SETTINGS.PLANS.ANNUAL_DISCOUNT') }}
            </span>
          </button>
        </div>

        <div
          v-if="availablePlans && availablePlans.length"
          class="grid lg:grid-cols-4 md:grid-cols-2 grid-cols-1 gap-4"
        >
          <div
            v-for="plan in availablePlans"
            :key="plan.id"
            class="rounded-xl border bg-n-solid-2 p-5 space-y-3 flex flex-col"
            :class="{
              'ring-2 ring-n-iris-9 border-n-iris-9':
                currentPlan && currentPlan.name === plan.base_name,
              'border-n-weak':
                !currentPlan || currentPlan.name !== plan.base_name,
            }"
          >
            <h3 class="text-lg font-semibold text-n-slate-12">
              {{ plan.base_name }}
            </h3>
            <div>
              <p class="text-2xl font-bold text-n-slate-12">
                {{
                  $t('BILLING_SETTINGS.PLANS.PRICE', {
                    price: formatPrice(plan.price_cents),
                  })
                }}
                <span class="text-sm font-normal text-n-slate-10">
                  {{
                    plan.interval === 'month'
                      ? $t('BILLING_SETTINGS.PLANS.PRICE_INTERVAL_MONTH')
                      : $t('BILLING_SETTINGS.PLANS.PRICE_INTERVAL_YEAR')
                  }}
                </span>
              </p>
              <p
                v-if="plan.interval === 'year' && monthlyEquivalent(plan)"
                class="text-sm text-n-slate-10 mt-0.5"
              >
                {{
                  $t('BILLING_SETTINGS.PLANS.PER_MONTH_ANNUAL', {
                    price: monthlyEquivalent(plan),
                  })
                }}
              </p>
              <p
                v-if="plan.interval === 'year' && annualSavings(plan)"
                class="text-xs text-green-600 font-medium mt-1"
              >
                {{
                  $t('BILLING_SETTINGS.PLANS.ANNUAL_SAVINGS', {
                    amount: formatPrice(annualSavings(plan)),
                  })
                }}
              </p>
            </div>

            <ul class="text-sm text-n-slate-11 space-y-1 flex-1">
              <li>
                {{
                  $t('BILLING_SETTINGS.PLANS.AGENTS', {
                    count: plan.agent_limit,
                  })
                }}
              </li>
              <li>
                {{
                  $t('BILLING_SETTINGS.PLANS.INBOXES', {
                    count: plan.inbox_limit,
                  })
                }}
              </li>
              <li>
                {{
                  $t('BILLING_SETTINGS.PLANS.AI_TOKENS', {
                    count: formatTokens(plan.ai_tokens_monthly),
                  })
                }}
              </li>
            </ul>

            <!-- Plan-specific features -->
            <div
              v-if="planFeatureLabels(plan).length"
              class="border-t border-n-weak pt-3"
            >
              <p class="text-xs font-medium text-n-slate-10 mb-1.5">
                {{ $t('BILLING_SETTINGS.PLANS.FEATURES') }}
              </p>
              <ul class="text-xs text-n-slate-11 space-y-1">
                <li
                  v-for="(label, idx) in planFeatureLabels(plan)"
                  :key="idx"
                  class="flex items-center gap-1"
                >
                  <span class="i-lucide-check text-green-500 size-3" />
                  <span v-if="typeof label === 'string'">{{ $t(label) }}</span>
                  <span v-else>{{ $t(label.key, label.params) }}</span>
                </li>
              </ul>
            </div>

            <ButtonV4
              v-if="!currentPlan || currentPlan.name !== plan.base_name"
              sm
              solid
              blue
              class="w-full"
              :is-loading="uiFlags.isCheckoutInProcess"
              @click="onSelectPlan(plan.id)"
            >
              {{ $t('BILLING_SETTINGS.PLANS.SELECT_PLAN') }}
            </ButtonV4>
            <div
              v-else
              class="text-center text-sm font-medium text-n-iris-11 py-2"
            >
              {{ $t('BILLING_SETTINGS.PLANS.CURRENT_PLAN') }}
            </div>
          </div>
        </div>

        <!-- Support -->
        <BillingHeader
          class="px-1 mt-5"
          :title="$t('BILLING_SETTINGS.CHAT_WITH_US.TITLE')"
          :description="$t('BILLING_SETTINGS.CHAT_WITH_US.DESCRIPTION')"
        >
          <a
            :href="whatsappSupportUrl"
            target="_blank"
            rel="noopener noreferrer"
          >
            <ButtonV4 sm solid slate icon="i-lucide-message-circle">
              {{ $t('BILLING_SETTINGS.CHAT_WITH_US.BUTTON_TXT') }}
            </ButtonV4>
          </a>
        </BillingHeader>
      </section>
    </template>
  </SettingsLayout>
</template>
