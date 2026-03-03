<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import ButtonV4 from 'next/button/Button.vue';

const props = defineProps({
  plans: {
    type: Array,
    default: () => [],
  },
  currentPlan: {
    type: Object,
    default: null,
  },
  isCheckingOut: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select']);

const { t } = useI18n();

const billingInterval = ref('month');

const filteredPlans = computed(() => {
  return props.plans.filter(plan => plan.interval === billingInterval.value);
});

const isCurrentPlan = plan => {
  return props.currentPlan?.key === plan.key;
};

const formatPrice = plan => {
  const interval =
    plan.interval === 'month'
      ? t('BILLING_SETTINGS.PLAN_SELECTOR.PER_MONTH')
      : t('BILLING_SETTINGS.PLAN_SELECTOR.PER_YEAR');
  return t('BILLING_SETTINGS.PLAN_SELECTOR.PRICE', {
    amount: plan.amount_kd,
    interval,
  });
};

const onSelectPlan = planKey => {
  emit('select', planKey);
};
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-4">
      <h2 class="text-base font-medium text-n-slate-12">
        {{ t('BILLING_SETTINGS.PLAN_SELECTOR.TITLE') }}
      </h2>
      <div
        class="inline-flex rounded-lg border border-n-weak bg-n-solid-2 p-0.5"
      >
        <button
          class="px-3 py-1.5 text-sm rounded-md transition-colors"
          :class="
            billingInterval === 'month'
              ? 'bg-n-brand text-white'
              : 'text-n-slate-11 hover:text-n-slate-12'
          "
          @click="billingInterval = 'month'"
        >
          {{ t('BILLING_SETTINGS.PLAN_SELECTOR.MONTHLY') }}
        </button>
        <button
          class="px-3 py-1.5 text-sm rounded-md transition-colors"
          :class="
            billingInterval === 'year'
              ? 'bg-n-brand text-white'
              : 'text-n-slate-11 hover:text-n-slate-12'
          "
          @click="billingInterval = 'year'"
        >
          {{ t('BILLING_SETTINGS.PLAN_SELECTOR.ANNUAL') }}
        </button>
      </div>
    </div>

    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
      <div
        v-for="plan in filteredPlans"
        :key="plan.key"
        class="rounded-xl border p-5 space-y-4 transition-shadow hover:shadow-md"
        :class="
          isCurrentPlan(plan)
            ? 'border-n-brand bg-n-blue-2'
            : 'border-n-weak bg-n-solid-2'
        "
      >
        <div>
          <div class="flex items-center gap-2">
            <h3 class="text-lg font-semibold text-n-slate-12">
              {{ plan.name }}
            </h3>
            <span
              v-if="isCurrentPlan(plan)"
              class="px-2 py-0.5 text-xs font-medium rounded-full bg-n-brand text-white"
            >
              {{ t('BILLING_SETTINGS.PLAN_SELECTOR.CURRENT') }}
            </span>
          </div>
          <div class="mt-2">
            <span class="text-2xl font-bold text-n-slate-12">
              {{ formatPrice(plan) }}
            </span>
          </div>
        </div>

        <ul class="space-y-2 text-sm text-n-slate-11">
          <li class="flex items-center gap-2">
            <i class="i-lucide-check text-n-teal-10" />
            {{
              t('BILLING_SETTINGS.PLAN_SELECTOR.AI_RESPONSES', {
                count: plan.limits?.ai_responses_per_month?.toLocaleString(),
              })
            }}
          </li>
          <li class="flex items-center gap-2">
            <i class="i-lucide-check text-n-teal-10" />
            {{
              t('BILLING_SETTINGS.PLAN_SELECTOR.KB_DOCS', {
                count: plan.limits?.knowledge_base_documents,
              })
            }}
          </li>
          <li
            v-if="plan.features?.crm_integration"
            class="flex items-center gap-2"
          >
            <i class="i-lucide-check text-n-teal-10" />
            {{ t('BILLING_SETTINGS.PLAN_SELECTOR.CRM') }}
          </li>
          <li v-if="plan.features?.api_access" class="flex items-center gap-2">
            <i class="i-lucide-check text-n-teal-10" />
            {{ t('BILLING_SETTINGS.PLAN_SELECTOR.API_ACCESS') }}
          </li>
        </ul>

        <ButtonV4
          v-if="!isCurrentPlan(plan)"
          sm
          solid
          blue
          :is-loading="isCheckingOut"
          @click="onSelectPlan(plan.key)"
        >
          {{ t('BILLING_SETTINGS.PLAN_SELECTOR.SUBSCRIBE') }}
        </ButtonV4>
      </div>
    </div>
  </div>
</template>
