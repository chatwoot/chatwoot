<script setup>
import { computed } from 'vue';
import { format, fromUnixTime, intervalToDuration } from 'date-fns';
import { useMapGetter } from 'dashboard/composables/store';

const currentChat = useMapGetter('getSelectedChat');

const appliedSla = computed(() => currentChat.value?.applied_sla);
const slaEvents = computed(() => currentChat.value?.sla_events || []);

const formatDuration = seconds => {
  if (!seconds || seconds < 0) return '--';

  const duration = intervalToDuration({
    start: 0,
    end: seconds * 1000,
  });

  const parts = [];
  if (duration.days) parts.push(`${duration.days}d`);
  if (duration.hours) parts.push(`${duration.hours}h`);
  if (duration.minutes) parts.push(`${duration.minutes}m`);
  if (!parts.length && duration.seconds) parts.push(`${duration.seconds}s`);

  return parts.join(' ') || '0s';
};

const formatSlaStartTime = computed(() => {
  return appliedSla.value?.created_at
    ? format(fromUnixTime(appliedSla.value.created_at), 'MMM dd, yyyy, HH:mm')
    : '--';
});

const getEventByType = type => slaEvents.value.find(e => e.event_type === type);

const calculateRealTime = (event, threshold) => {
  if (!event || !appliedSla.value?.created_at) {
    return { time: '--', status: 'none' };
  }

  const realSeconds = event.created_at - appliedSla.value.created_at;
  const time = formatDuration(realSeconds);

  if (!threshold) {
    return { time, status: 'none' };
  }

  const diff = realSeconds - threshold;

  if (diff <= 0) {
    return { time, status: 'hit' };
  }

  if (diff <= threshold * 0.2) {
    return { time, status: 'warning' };
  }

  return { time, status: 'missed' };
};

const frt = computed(() =>
  calculateRealTime(
    getEventByType('frt'),
    appliedSla.value?.sla_first_response_time_threshold
  )
);

const nrt = computed(() =>
  calculateRealTime(
    getEventByType('nrt'),
    appliedSla.value?.sla_next_response_time_threshold
  )
);

const rt = computed(() =>
  calculateRealTime(
    getEventByType('rt'),
    appliedSla.value?.sla_resolution_time_threshold
  )
);
</script>

<template>
  <div v-if="appliedSla" class="flex flex-col gap-4 px-4 py-3">
    <div class="flex flex-col gap-3">
      <div class="flex flex-col gap-1">
        <span class="text-xs font-medium text-n-slate-11">
          {{ $t('CONVERSATION_SIDEBAR.SLA.POLICY') }}
        </span>
        <span class="text-sm text-n-slate-12">
          {{ appliedSla.sla_name || '--' }}
        </span>
      </div>

      <div class="flex flex-col gap-1">
        <span class="text-xs font-medium text-n-slate-11">
          {{ $t('CONVERSATION_SIDEBAR.SLA.START_TIME') }}
        </span>
        <span class="text-sm text-n-slate-12">
          {{ formatSlaStartTime }}
        </span>
      </div>

      <div class="flex flex-col gap-2">
        <span class="text-xs font-medium text-n-slate-11">
          {{ $t('CONVERSATION_SIDEBAR.SLA.FIRST_RESPONSE_TIME') }}
        </span>
        <div class="flex flex-col gap-1">
          <div class="flex items-center gap-2">
            <span class="text-xs text-n-slate-11">{{
              $t('CONVERSATION_SIDEBAR.SLA.TARGET')
            }}</span>
            <span class="text-sm font-medium text-n-slate-12">
              {{
                appliedSla.sla_first_response_time_threshold
                  ? formatDuration(appliedSla.sla_first_response_time_threshold)
                  : '--'
              }}
            </span>
          </div>
          <div class="flex items-center gap-2">
            <span class="text-xs text-n-slate-11">{{
              $t('CONVERSATION_SIDEBAR.SLA.ACTUAL')
            }}</span>
            <span
              class="text-sm font-medium"
              :class="
                frt.status === 'missed'
                  ? 'text-n-ruby-11'
                  : frt.status === 'warning'
                    ? 'text-n-amber-11'
                    : frt.status === 'hit'
                      ? 'text-n-teal-11'
                      : 'text-n-slate-12'
              "
            >
              {{ frt.time }}
            </span>
            <span
              v-if="frt.status !== 'none'"
              class="w-2 h-2 rounded-full flex-shrink-0"
              :class="
                frt.status === 'missed'
                  ? 'bg-n-ruby-11'
                  : frt.status === 'warning'
                    ? 'bg-n-amber-11'
                    : 'bg-n-teal-11'
              "
            />
          </div>
        </div>
      </div>

      <div
        v-if="appliedSla.sla_next_response_time_threshold"
        class="flex flex-col gap-2"
      >
        <span class="text-xs font-medium text-n-slate-11">
          {{ $t('CONVERSATION_SIDEBAR.SLA.NEXT_RESPONSE_TIME') }}
        </span>
        <div class="flex flex-col gap-1">
          <div class="flex items-center gap-2">
            <span class="text-xs text-n-slate-11">{{
              $t('CONVERSATION_SIDEBAR.SLA.TARGET')
            }}</span>
            <span class="text-sm font-medium text-n-slate-12">
              {{ formatDuration(appliedSla.sla_next_response_time_threshold) }}
            </span>
          </div>
          <div class="flex items-center gap-2">
            <span class="text-xs text-n-slate-11">{{
              $t('CONVERSATION_SIDEBAR.SLA.ACTUAL')
            }}</span>
            <span
              class="text-sm font-medium"
              :class="
                nrt.status === 'missed'
                  ? 'text-n-ruby-11'
                  : nrt.status === 'warning'
                    ? 'text-n-amber-11'
                    : nrt.status === 'hit'
                      ? 'text-n-teal-11'
                      : 'text-n-slate-12'
              "
            >
              {{ nrt.time }}
            </span>
            <span
              v-if="nrt.status !== 'none'"
              class="w-2 h-2 rounded-full flex-shrink-0"
              :class="
                nrt.status === 'missed'
                  ? 'bg-n-ruby-11'
                  : nrt.status === 'warning'
                    ? 'bg-n-amber-11'
                    : 'bg-n-teal-11'
              "
            />
          </div>
        </div>
      </div>

      <div
        v-if="appliedSla.sla_resolution_time_threshold"
        class="flex flex-col gap-2"
      >
        <span class="text-xs font-medium text-n-slate-11">
          {{ $t('CONVERSATION_SIDEBAR.SLA.RESOLUTION_TIME') }}
        </span>
        <div class="flex flex-col gap-1">
          <div class="flex items-center gap-2">
            <span class="text-xs text-n-slate-11">{{
              $t('CONVERSATION_SIDEBAR.SLA.TARGET')
            }}</span>
            <span class="text-sm font-medium text-n-slate-12">
              {{ formatDuration(appliedSla.sla_resolution_time_threshold) }}
            </span>
          </div>
          <div class="flex items-center gap-2">
            <span class="text-xs text-n-slate-11">{{
              $t('CONVERSATION_SIDEBAR.SLA.ACTUAL')
            }}</span>
            <span
              class="text-sm font-medium"
              :class="
                rt.status === 'missed'
                  ? 'text-n-ruby-11'
                  : rt.status === 'warning'
                    ? 'text-n-amber-11'
                    : rt.status === 'hit'
                      ? 'text-n-teal-11'
                      : 'text-n-slate-12'
              "
            >
              {{ rt.time }}
            </span>
            <span
              v-if="rt.status !== 'none'"
              class="w-2 h-2 rounded-full flex-shrink-0"
              :class="
                rt.status === 'missed'
                  ? 'bg-n-ruby-11'
                  : rt.status === 'warning'
                    ? 'bg-n-amber-11'
                    : 'bg-n-teal-11'
              "
            />
          </div>
        </div>
      </div>
    </div>
  </div>
  <div v-else class="flex items-center justify-center py-5 px-4">
    <span class="text-sm text-n-slate-11">
      {{ $t('CONVERSATION_SIDEBAR.SLA.NO_SLA') }}
    </span>
  </div>
</template>
