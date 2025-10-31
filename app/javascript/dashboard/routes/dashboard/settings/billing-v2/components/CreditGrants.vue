<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import format from 'date-fns/format';
import BillingCard from 'dashboard/routes/dashboard/settings/billing/components/BillingCard.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  grants: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();

const formatDate = dateStr => {
  if (!dateStr) return null;
  return format(new Date(dateStr), 'MMM dd, yyyy');
};

const formatNumber = num => new Intl.NumberFormat('en-US').format(num);

const sortedGrants = computed(
  () =>
    [...props.grants]?.sort((a, b) => {
      if (a.voided_at && !b.voided_at) return 1;
      if (!a.voided_at && b.voided_at) return -1;
      return new Date(b.created_at) - new Date(a.created_at);
    }) || []
);

const CATEGORY_CONFIG = computed(() => {
  return {
    paid: {
      label: t('BILLING_SETTINGS_V2.CREDIT_GRANTS.TOPUPS'),
      class: 'bg-n-blue-3 text-n-blue-11 outline outline-1 outline-n-blue-4',
    },
    granted: {
      label: t('BILLING_SETTINGS_V2.CREDIT_GRANTS.MONTHLY'),
      class: 'bg-n-teal-3 text-n-teal-11 outline outline-1 outline-n-teal-4',
    },
  };
});

const getCategoryConfig = category =>
  CATEGORY_CONFIG.value[category] || CATEGORY_CONFIG.value.granted;
</script>

<template>
  <BillingCard
    :title="$t('BILLING_SETTINGS_V2.CREDIT_GRANTS.TITLE')"
    :description="$t('BILLING_SETTINGS_V2.CREDIT_GRANTS.DESCRIPTION')"
  >
    <div class="px-5 pb-5">
      <div v-if="sortedGrants.length" class="space-y-3">
        <div
          v-for="grant in sortedGrants"
          :key="grant.id"
          class="p-4 rounded-xl outline outline-1 outline-n-weak transition-opacity"
          :class="{ 'opacity-50': grant.voided_at }"
        >
          <div class="flex items-start justify-between gap-4">
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 mb-2">
                <span
                  class="px-2 py-0.5 text-xs font-semibold rounded-md"
                  :class="getCategoryConfig(grant.category).class"
                >
                  {{ getCategoryConfig(grant.category).label }}
                </span>
                <span
                  v-if="grant.voided_at"
                  class="px-2 py-0.5 text-xs font-semibold rounded-md bg-n-ruby-3 text-n-ruby-11 outline outline-1 outline-n-ruby-4"
                >
                  {{ t('BILLING_SETTINGS_V2.CREDIT_GRANTS.VOIDED') }}
                </span>
              </div>

              <h4 class="text-sm font-semibold text-n-slate-12 truncate">
                {{ grant.name }}
              </h4>
              <p class="mt-1 text-xs text-n-slate-11">
                {{ formatNumber(grant.credits) }}
                {{ t('BILLING_SETTINGS_V2.CREDIT_GRANTS.CREDITS') }}
              </p>
            </div>

            <div class="text-right flex-shrink-0">
              <div v-if="grant.expires_at" class="text-xs text-n-slate-11">
                <span class="font-medium">
                  {{ t('BILLING_SETTINGS_V2.CREDIT_GRANTS.EXPIRES') }}
                </span>
                <div class="mt-0.5">{{ formatDate(grant.expires_at) }}</div>
              </div>

              <div v-else class="text-xs text-n-teal-10 font-medium">
                {{ t('BILLING_SETTINGS_V2.CREDIT_GRANTS.NO_EXPIRY') }}
              </div>

              <div v-if="grant.created_at" class="mt-1 text-xs text-n-slate-10">
                {{
                  t('BILLING_SETTINGS_V2.CREDIT_GRANTS.ADDED', {
                    date: formatDate(grant.created_at),
                  })
                }}
              </div>
            </div>
          </div>
        </div>
      </div>
      <div v-else-if="!isLoading" class="py-8 text-center">
        <p class="text-sm text-n-slate-11">
          {{ t('BILLING_SETTINGS_V2.CREDIT_GRANTS.NO_GRANTS') }}
        </p>
      </div>
      <div v-else class="py-8 flex justify-center items-center">
        <Spinner class="text-n-brand" />
      </div>
    </div>
  </BillingCard>
</template>
