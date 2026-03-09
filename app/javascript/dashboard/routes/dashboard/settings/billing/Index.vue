<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useBillingStore } from 'dashboard/stores/billing';
import { useAlert } from 'dashboard/composables';
import { format } from 'date-fns';

import BillingCard from './components/BillingCard.vue';
import BillingHeader from './components/BillingHeader.vue';
import BillingMeter from './components/BillingMeter.vue';
import DetailItem from './components/DetailItem.vue';
import PlanSelector from './components/PlanSelector.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ButtonV4 from 'next/button/Button.vue';

const { t } = useI18n();
const billingStore = useBillingStore();

const hasSubscription = computed(() => !!billingStore.subscription);

const planName = computed(
  () => billingStore.plan?.name || t('BILLING_SETTINGS.NO_PLAN')
);

const subscriptionStatus = computed(
  () => billingStore.subscription?.status || ''
);

const renewsOn = computed(() => {
  const endDate = billingStore.subscription?.current_period_end;
  if (!endDate) return '';
  return format(new Date(endDate), 'dd MMM, yyyy');
});

const trialEndsOn = computed(() => {
  const endDate = billingStore.subscription?.trial_ends_at;
  if (!endDate) return '';
  return format(new Date(endDate), 'dd MMM, yyyy');
});

const aiUsage = computed(() => billingStore.usage?.ai_responses_count || 0);
const aiLimit = computed(() => billingStore.usage?.ai_responses_limit || 0);

const onManageBilling = async () => {
  try {
    await billingStore.openPortal();
  } catch {
    useAlert(t('BILLING_SETTINGS.API.PORTAL_ERROR'));
  }
};

const onCancel = async () => {
  if (!window.confirm(t('BILLING_SETTINGS.CONFIRM.CANCEL'))) return;
  try {
    await billingStore.cancel();
    useAlert(t('BILLING_SETTINGS.API.CANCEL_SUCCESS'));
  } catch {
    useAlert(t('BILLING_SETTINGS.API.CANCEL_ERROR'));
  }
};

const onResume = async () => {
  try {
    await billingStore.resume();
    useAlert(t('BILLING_SETTINGS.API.RESUME_SUCCESS'));
  } catch {
    useAlert(t('BILLING_SETTINGS.API.RESUME_ERROR'));
  }
};

const onSelectPlan = async planKey => {
  try {
    await billingStore.checkout(planKey);
  } catch {
    useAlert(t('BILLING_SETTINGS.API.CHECKOUT_ERROR'));
  }
};

const onSwapPlan = async planKey => {
  if (!window.confirm(t('BILLING_SETTINGS.CONFIRM.SWAP'))) return;
  try {
    await billingStore.swapPlan(planKey);
    useAlert(t('BILLING_SETTINGS.API.SWAP_SUCCESS'));
  } catch {
    useAlert(t('BILLING_SETTINGS.API.SWAP_ERROR'));
  }
};

onMounted(() => billingStore.fetch());
</script>

<template>
  <SettingsLayout
    :is-loading="billingStore.uiFlags.isFetching"
    :loading-message="$t('BILLING_SETTINGS.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('BILLING_SETTINGS.TITLE')"
        :description="$t('BILLING_SETTINGS.DESCRIPTION')"
        feature-name="billing"
      />
    </template>
    <template #body>
      <section class="grid gap-6">
        <!-- Current Plan Card -->
        <BillingCard
          :title="$t('BILLING_SETTINGS.CURRENT_PLAN.TITLE')"
          :description="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.DESCRIPTION')"
        >
          <template #action>
            <div class="flex gap-2">
              <ButtonV4
                v-if="hasSubscription"
                sm
                solid
                blue
                @click="onManageBilling"
              >
                {{ $t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.BUTTON_TXT') }}
              </ButtonV4>
              <ButtonV4
                v-if="hasSubscription && !billingStore.onGracePeriod"
                sm
                faded
                slate
                @click="onCancel"
              >
                {{ $t('BILLING_SETTINGS.ACTIONS.CANCEL') }}
              </ButtonV4>
              <ButtonV4
                v-if="billingStore.onGracePeriod"
                sm
                solid
                blue
                @click="onResume"
              >
                {{ $t('BILLING_SETTINGS.ACTIONS.RESUME') }}
              </ButtonV4>
            </div>
          </template>

          <div
            v-if="hasSubscription"
            class="grid lg:grid-cols-4 sm:grid-cols-2 grid-cols-1 gap-2 divide-x divide-n-weak px-5"
          >
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.PLAN_LABEL')"
              :value="planName"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.STATUS')"
              :value="subscriptionStatus"
            />
            <DetailItem
              v-if="renewsOn"
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.RENEWS_ON')"
              :value="renewsOn"
            />
            <DetailItem
              v-if="trialEndsOn"
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.TRIAL_ENDS')"
              :value="trialEndsOn"
            />
          </div>
          <div v-else class="px-5 text-sm text-n-slate-11">
            {{ $t('BILLING_SETTINGS.NO_PLAN') }}
          </div>
        </BillingCard>

        <!-- Usage Card -->
        <BillingCard
          v-if="hasSubscription && aiLimit"
          :title="$t('BILLING_SETTINGS.USAGE.TITLE')"
          :description="$t('BILLING_SETTINGS.USAGE.DESCRIPTION')"
        >
          <div class="px-5 pb-2">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.USAGE.AI_RESPONSES')"
              :consumed="aiUsage"
              :total-count="aiLimit"
            />
          </div>
        </BillingCard>

        <!-- Plan Selector -->
        <PlanSelector
          :plans="billingStore.plans"
          :current-plan="billingStore.plan"
          :is-checking-out="billingStore.uiFlags.isCheckingOut"
          @select="hasSubscription ? onSwapPlan($event) : onSelectPlan($event)"
        />

        <!-- Help Section -->
        <BillingHeader
          class="px-1 mt-2"
          :title="$t('BILLING_SETTINGS.CHAT_WITH_US.TITLE')"
          :description="$t('BILLING_SETTINGS.CHAT_WITH_US.DESCRIPTION')"
        >
          <ButtonV4
            sm
            solid
            slate
            icon="i-lucide-life-buoy"
            @click="$chatwoot && $chatwoot.toggle()"
          >
            {{ $t('BILLING_SETTINGS.CHAT_WITH_US.BUTTON_TXT') }}
          </ButtonV4>
        </BillingHeader>
      </section>
    </template>
  </SettingsLayout>
</template>
