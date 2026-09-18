<script setup>
import { computed, onMounted, onUnmounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';
import { useExactTimestamp } from 'shared/composables/useExactTimestamp';

const props = defineProps({
  isAutoRefreshEnabled: { type: Boolean, default: true },
  lastActivityTimestamp: { type: [String, Date, Number], default: '' },
  createdAtTimestamp: { type: [String, Date, Number], default: '' },
  lastMessageTimestamp: { type: Number, default: null },
  waitingSinceTimestamp: { type: Number, default: null },
  conversationId: { type: [String, Number], default: '' },
  sortBy: { type: String, default: 'last_activity_at_desc' },
});

const MINUTE_IN_MILLI_SECONDS = 60000;
const HOUR_IN_MILLI_SECONDS = MINUTE_IN_MILLI_SECONDS * 60;
const DAY_IN_MILLI_SECONDS = HOUR_IN_MILLI_SECONDS * 24;

const { t } = useI18n();
const exactTimestamp = useExactTimestamp();
const createdAtTime = ref('');
const selectedTime = ref('');
let timer;

const timestampType = computed(() => {
  const field = props.sortBy.replace(/_(asc|desc)$/, '');
  return ['last_message_at', 'waiting_since', 'created_at'].includes(field)
    ? field
    : 'last_activity_at';
});

const timestamp = computed(
  () =>
    ({
      last_activity_at: props.lastActivityTimestamp,
      last_message_at: props.lastMessageTimestamp,
      waiting_since: props.waitingSinceTimestamp,
      created_at: props.createdAtTimestamp,
    })[timestampType.value]
);

const timestampLabel = computed(
  () =>
    ({
      last_activity_at: t('CHAT_LIST.CHAT_TIME_STAMP.LAST_ACTIVITY.NOT_ACTIVE'),
      last_message_at: t('CHAT_LIST.CHAT_TIME_STAMP.LAST_MESSAGE'),
      waiting_since: t('CHAT_LIST.CHAT_TIME_STAMP.WAITING_SINCE'),
      created_at: t('CHAT_LIST.CHAT_TIME_STAMP.CREATED.OLDEST'),
    })[timestampType.value]
);

const emptyLabel = computed(() =>
  timestampType.value === 'waiting_since'
    ? t('CHAT_LIST.CHAT_TIME_STAMP.NOT_WAITING')
    : t('CHAT_LIST.CHAT_TIME_STAMP.NO_MESSAGES')
);

const tooltipText = computed(() => {
  const created = `${t('CHAT_LIST.CHAT_TIME_STAMP.CREATED.OLDEST')} ${exactTimestamp(props.createdAtTimestamp)}`;
  if (timestampType.value === 'created_at') return created;

  const selected = timestamp.value
    ? `${timestampLabel.value} ${exactTimestamp(timestamp.value)}`
    : emptyLabel.value;
  return `${created}\n${selected}`;
});

const refreshTimes = () => {
  createdAtTime.value = shortTimestamp(dynamicTime(props.createdAtTimestamp));
  selectedTime.value = timestamp.value
    ? shortTimestamp(dynamicTime(timestamp.value))
    : '';
};

const refresh = () => {
  clearTimeout(timer);
  refreshTimes();
  if (!props.isAutoRefreshEnabled) return;

  const age = Date.now() - (timestamp.value || props.createdAtTimestamp) * 1000;
  let interval = MINUTE_IN_MILLI_SECONDS;
  if (age > DAY_IN_MILLI_SECONDS) interval = DAY_IN_MILLI_SECONDS;
  else if (age > HOUR_IN_MILLI_SECONDS) interval = HOUR_IN_MILLI_SECONDS;
  timer = setTimeout(refresh, interval);
};

refreshTimes();
watch(
  [
    timestamp,
    () => props.createdAtTimestamp,
    () => props.conversationId,
    () => props.isAutoRefreshEnabled,
  ],
  refresh
);
onMounted(refresh);
onUnmounted(() => clearTimeout(timer));
</script>

<template>
  <div
    v-tooltip.top="{
      content: tooltipText,
      popperClass: 'whitespace-pre-line',
      delay: { show: 1000, hide: 0 },
    }"
    class="ms-auto whitespace-nowrap leading-4 text-xxs text-n-slate-10 hover:text-n-slate-11"
  >
    <span v-if="timestampType === 'last_activity_at'">
      {{ `${createdAtTime} • ${selectedTime}` }}
    </span>
    <span v-else>{{ selectedTime || emptyLabel }}</span>
  </div>
</template>
