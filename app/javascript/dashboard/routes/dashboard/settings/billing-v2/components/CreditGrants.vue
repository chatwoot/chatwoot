<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import BillingCard from '../../billing/components/BillingCard.vue';

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
  const date = new Date(dateStr);
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }).format(date);
};

const formatNumber = num => {
  return new Intl.NumberFormat('en-US').format(num);
};

const sortedGrants = computed(() => {
  return [...props.grants].sort((a, b) => {
    // Sort by: active first, then by creation date (newest first)
    if (a.voided_at && !b.voided_at) return 1;
    if (!a.voided_at && b.voided_at) return -1;
    return new Date(b.created_at) - new Date(a.created_at);
  });
});

const getCategoryColor = category => {
  return category === 'paid' ? 'bg-b-50 text-b-700' : 'bg-g-50 text-g-700';
};

const getCategoryLabel = category => {
  return category === 'paid' ? 'Topup' : 'Monthly';
};
</script>

<template>
  <BillingCard
    :title="$t('BILLING_SETTINGS_V2.CREDIT_GRANTS.TITLE')"
    :description="$t('BILLING_SETTINGS_V2.CREDIT_GRANTS.DESCRIPTION')"
  >
    <div class="px-5 pb-5">
      <!-- Grants List -->
      <div class="space-y-3">
        <div
          v-for="grant in sortedGrants"
          :key="grant.id"
          class="p-4 border border-n-weak rounded-lg"
          :class="{ 'opacity-50': grant.voided_at }"
        >
          <div class="flex items-start justify-between">
            <div class="flex-1">
              <div class="flex items-center gap-2 mb-2">
                <span
                  class="px-2 py-0.5 text-xs font-semibold rounded"
                  :class="getCategoryColor(grant.category)"
                >
                  {{ getCategoryLabel(grant.category) }}
                </span>
                <span
                  v-if="grant.voided_at"
                  class="px-2 py-0.5 text-xs font-semibold rounded bg-r-50 text-r-700"
                >
                  Voided
                </span>
              </div>
              <h4 class="text-sm font-semibold text-n-800">
                {{ grant.name }}
              </h4>
              <p class="mt-1 text-xs text-n-600">
                {{ formatNumber(grant.credits) }}
                {{ $t('BILLING_SETTINGS_V2.CREDIT_GRANTS.CREDITS') }}
              </p>
            </div>
            <div class="text-right">
              <div v-if="grant.expires_at" class="text-xs text-n-600">
                <span class="font-medium">{{
                  $t('BILLING_SETTINGS_V2.CREDIT_GRANTS.EXPIRES')
                }}</span>
                <br />
                {{ formatDate(grant.expires_at) }}
              </div>
              <div v-else class="text-xs text-g-600 font-medium">
                {{ $t('BILLING_SETTINGS_V2.CREDIT_GRANTS.NO_EXPIRY') }}
              </div>
              <div class="mt-1 text-xs text-n-500">
                {{ $t('BILLING_SETTINGS_V2.CREDIT_GRANTS.ADDED') }}
                {{ formatDate(grant.created_at) }}
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div v-if="grants.length === 0 && !isLoading" class="py-8 text-center">
        <p class="text-sm text-n-600">
          {{ $t('BILLING_SETTINGS_V2.CREDIT_GRANTS.NO_GRANTS') }}
        </p>
      </div>
    </div>
  </BillingCard>
</template>
