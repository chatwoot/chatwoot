<script setup>
import { useI18n } from 'vue-i18n';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import {
  currentDateLocale,
  dateTimeFormat,
} from 'shared/helpers/localizedDate';

defineProps({ usage: { type: Object, default: null } });

const { t } = useI18n();
const formatTime = timestamp =>
  // The fields toLocaleString fills in when only the zone is asked for.
  dateTimeFormat(currentDateLocale(), {
    year: 'numeric',
    month: 'numeric',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    second: '2-digit',
    timeZone: 'UTC',
    timeZoneName: 'short',
  }).format(new Date(timestamp * 1000));
</script>

<template>
  <Banner v-if="usage?.limit_reached" color="amber" role="status" class="mb-4">
    <div class="flex items-start gap-2">
      <span
        class="i-lucide-triangle-alert mt-0.5 size-4 shrink-0"
        aria-hidden="true"
      />
      <div class="flex flex-col gap-1">
        <p class="m-0 font-medium">
          {{
            t('MONITORS.USAGE.LIMIT_REACHED', {
              limit: usage.limit.toLocaleString(),
            })
          }}
        </p>
        <p class="m-0">
          {{
            t('MONITORS.USAGE.RESETS', { time: formatTime(usage.resets_at) })
          }}
        </p>
        <p v-if="usage.limit_reached_at" class="m-0 text-xs">
          {{
            t('MONITORS.USAGE.REACHED_AT', {
              time: formatTime(usage.limit_reached_at),
            })
          }}
        </p>
      </div>
    </div>
  </Banner>
</template>
