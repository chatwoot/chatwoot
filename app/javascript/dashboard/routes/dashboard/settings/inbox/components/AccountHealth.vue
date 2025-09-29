<script setup>
import { computed } from 'vue';
import ButtonV4 from 'next/button/Button.vue';

const healthItems = computed(() => [
  {
    key: 'DISPLAY_PHONE_NUMBER',
    label: 'Display phone number',
    value: '+16503185215',
    tooltip: 'Display phone number',
    show: true,
  },
  {
    key: 'VERIFIED_NAME',
    label: 'Verified name',
    value: 'Saharidya AI',
    tooltip: 'Verified business name',
    show: true,
  },
  {
    key: 'DISPLAY_NAME_STATUS',
    label: 'Display name status',
    value: 'APPROVED',
    tooltip: 'Status of display name verification',
    show: true,
    type: 'status',
  },
  {
    key: 'QUALITY_RATING',
    label: 'Quality rating',
    value: 'GREEN',
    tooltip: 'Account quality rating',
    show: true,
    type: 'quality',
  },
  {
    key: 'MESSAGING_LIMIT_TIER',
    label: 'Messaging limit tier',
    value: 'TIER_1K',
    tooltip: 'Daily messaging limit tier',
    show: true,
    type: 'tier',
  },
  {
    key: 'ACCOUNT_MODE',
    label: 'Account mode',
    value: 'LIVE',
    tooltip: 'Account operating mode',
    show: true,
    type: 'mode',
  },
]);

const getQualityRatingClass = rating => {
  const classes = {
    GREEN: 'bg-green-50 text-green-700 border-green-200',
    YELLOW: 'bg-yellow-50 text-yellow-700 border-yellow-200',
    RED: 'bg-red-50 text-red-700 border-red-200',
    UNKNOWN: 'bg-gray-50 text-gray-700 border-gray-200',
  };
  return classes[rating] || classes.UNKNOWN;
};

const formatTierDisplay = tier => {
  const tierMap = {
    TIER_250: '250 customers per 24h',
    TIER_1K: '1K customers per 24h',
    TIER_10K: '10K customers per 24h',
    TIER_100K: '100K customers per 24h',
    TIER_UNLIMITED: 'Unlimited customers per 24h',
  };
  return tierMap[tier] || tier;
};

const formatStatusDisplay = status => {
  const statusMap = {
    APPROVED: 'Approved',
    PENDING_REVIEW: 'Pending Review',
    AVAILABLE_WITHOUT_REVIEW: 'Available Without Review',
    REJECTED: 'Rejected',
  };
  return statusMap[status] || status;
};

const formatModeDisplay = mode => {
  const modeMap = {
    SANDBOX: 'Sandbox',
    LIVE: 'Live',
  };
  return modeMap[mode] || mode;
};

const getModeStatusClass = mode => {
  return mode === 'LIVE'
    ? 'bg-teal-50 text-teal-700'
    : 'bg-gray-50 text-gray-700';
};

const getStatusBadgeClass = status => {
  const classes = {
    APPROVED: 'bg-green-50 text-green-700 border-green-200',
    PENDING_REVIEW: 'bg-yellow-50 text-yellow-700 border-yellow-200',
    AVAILABLE_WITHOUT_REVIEW: 'bg-blue-50 text-blue-700 border-blue-200',
    REJECTED: 'bg-red-50 text-red-700 border-red-200',
  };
  return classes[status] || 'bg-gray-50 text-gray-700 border-gray-200';
};
</script>

<template>
  <div class="gap-4 pt-8 mx-8">
    <div
      class="px-5 py-5 space-y-5 rounded-xl border shadow-sm border-n-weak bg-n-solid-2"
    >
      <div class="grid grid-cols-[1fr_auto] gap-5">
        <div>
          <span class="text-base font-medium text-n-slate-12">
            Manage your WhatsApp account
          </span>
          <p class="mt-1 text-sm text-n-slate-11">
            Check your display name, messaging limits, and quality rating.
            Update your settings or fix issues if needed.
          </p>
        </div>
        <ButtonV4 sm solid blue> Go to the settings </ButtonV4>
      </div>

      <div class="pt-8 space-y-4">
        <section
          class="w-full text-sm rounded-xl border divide-y border-n-weak bg-n-solid-1 text-n-slate-12 divide-n-weak"
        >
          <div
            v-for="item in healthItems"
            :key="item.key"
            class="flex justify-between items-center px-6 py-4 transition-colors hover:bg-n-alpha-1"
          >
            <div class="flex flex-1 gap-2 items-center min-w-0">
              <span class="text-sm font-medium text-n-slate-11 min-w-48">
                {{ item.label }}
              </span>
              <i
                v-tooltip.top="item.tooltip"
                class="flex-shrink-0 w-4 h-4 cursor-help i-lucide-info text-n-slate-9"
              />
            </div>
            <div class="flex-shrink-0">
              <span
                v-if="item.type === 'quality'"
                class="inline-flex px-3 py-1.5 text-xs font-semibold rounded-full border"
                :class="getQualityRatingClass(item.value)"
              >
                {{ item.value }}
              </span>
              <span
                v-else-if="item.type === 'status'"
                class="inline-flex px-3 py-1.5 text-xs font-semibold rounded-full border"
                :class="getStatusBadgeClass(item.value)"
              >
                {{ formatStatusDisplay(item.value) }}
              </span>
              <span
                v-else-if="item.type === 'mode'"
                class="inline-flex items-center px-3 py-1.5 text-xs font-semibold rounded-full"
                :class="getModeStatusClass(item.value)"
              >
                {{ formatModeDisplay(item.value) }}
              </span>
              <span
                v-else-if="item.type === 'tier'"
                class="text-sm font-medium text-n-slate-12"
              >
                {{ formatTierDisplay(item.value) }}
              </span>
              <span v-else class="text-sm font-medium text-n-slate-12">{{
                item.value
              }}</span>
            </div>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>
