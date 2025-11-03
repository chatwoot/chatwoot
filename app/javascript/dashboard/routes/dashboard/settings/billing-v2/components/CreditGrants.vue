<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import format from 'date-fns/format';
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
  <div class="mt-4 max-h-96 overflow-y-auto">
    <h6 class="text-base font-semibold mb-2">
      {{ t('BILLING_SETTINGS_V2.CREDIT_GRANTS.TITLE') }}
    </h6>
    <div v-if="sortedGrants.length" class="space-y-2">
      <div
        v-for="grant in sortedGrants"
        :key="grant.id"
        class="flex items-center justify-between gap-4 p-3 rounded-lg border border-n-weak"
        :class="{ 'opacity-60': grant.voided_at }"
      >
        <div class="flex items-center gap-2.5 min-w-0 flex-1">
          <span
            class="px-2 py-0.5 text-xs font-semibold rounded whitespace-nowrap"
            :class="getCategoryConfig(grant.category).class"
          >
            {{ getCategoryConfig(grant.category).label }}
          </span>
          <span class="text-sm font-medium text-n-slate-12 truncate">
            {{ grant.name }}
          </span>
        </div>

        <div class="flex items-center gap-4 flex-shrink-0">
          <div
            class="text-sm font-semibold text-n-slate-12 whitespace-nowrap hidden sm:block"
          >
            {{ formatNumber(grant.credits) }}
            <span class="text-xs font-normal text-n-slate-10 ml-1">
              {{ t('BILLING_SETTINGS_V2.CREDIT_GRANTS.CREDITS') }}
            </span>
          </div>

          <div class="text-sm text-right min-w-[110px]">
            <span
              v-if="grant.expires_at"
              class="font-medium text-n-slate-11"
              :title="t('BILLING_SETTINGS_V2.CREDIT_GRANTS.EXPIRES')"
            >
              {{ formatDate(grant.expires_at) }}
            </span>
            <span v-else class="font-medium text-n-teal-10">
              {{ t('BILLING_SETTINGS_V2.CREDIT_GRANTS.NO_EXPIRY') }}
            </span>
          </div>

          <div
            v-if="grant.created_at"
            class="text-xs text-n-slate-10 whitespace-nowrap"
            :title="
              t('BILLING_SETTINGS_V2.CREDIT_GRANTS.ADDED', {
                date: formatDate(grant.created_at),
              })
            "
          >
            {{ formatDate(grant.created_at) }}
          </div>

          <span
            v-if="grant.voided_at"
            class="px-2 py-0.5 text-xs font-semibold rounded bg-n-ruby-3 text-n-ruby-11 border border-n-ruby-6 whitespace-nowrap"
          >
            {{ t('BILLING_SETTINGS_V2.CREDIT_GRANTS.VOIDED') }}
          </span>
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
</template>
