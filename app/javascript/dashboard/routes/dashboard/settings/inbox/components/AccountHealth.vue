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

const getQualityRatingTextColor = rating => {
  const colors = {
    GREEN: 'text-n-teal-11',
    YELLOW: 'text-n-yellow-11',
    RED: 'text-n-red-11',
    UNKNOWN: 'text-n-slate-12',
  };
  return colors[rating] || colors.UNKNOWN;
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

const getModeStatusTextColor = mode => {
  return mode === 'LIVE' ? 'text-n-teal-11' : 'text-n-slate-12';
};

const getStatusTextColor = status => {
  const colors = {
    APPROVED: 'text-n-teal-11',
    PENDING_REVIEW: 'text-n-yellow-11',
    AVAILABLE_WITHOUT_REVIEW: 'text-n-blue-11',
    REJECTED: 'text-n-red-11',
  };
  return colors[status] || 'text-n-slate-12';
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
            Review your WhatsApp account status, messaging limits, and quality.
            Update settings or resolve issues if needed
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
            <div class="flex flex-1 items-center min-w-0">
              <span class="text-sm font-medium text-n-slate-11 min-w-48">
                {{ item.label }}
              </span>
            </div>
            <div class="flex items-center gap-2 flex-shrink-0">
              <span
                v-if="item.type === 'quality'"
                class="inline-flex items-center px-2 py-0.5 h-6 text-xs font-medium rounded-md bg-n-alpha-2"
                :class="getQualityRatingTextColor(item.value)"
              >
                {{ item.value }}
              </span>
              <span
                v-else-if="item.type === 'status'"
                class="inline-flex items-center px-2 py-0.5 h-6 text-xs font-medium rounded-md bg-n-alpha-2"
                :class="getStatusTextColor(item.value)"
              >
                {{ formatStatusDisplay(item.value) }}
              </span>
              <span
                v-else-if="item.type === 'mode'"
                class="inline-flex items-center px-2 py-0.5 h-6 text-xs font-medium rounded-md bg-n-alpha-2"
                :class="getModeStatusTextColor(item.value)"
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
              <i
                v-tooltip.top="item.tooltip"
                class="flex-shrink-0 w-4 h-4 cursor-help i-lucide-info text-n-slate-9"
              />
            </div>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>
