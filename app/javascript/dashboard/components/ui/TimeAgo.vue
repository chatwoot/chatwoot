<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  dynamicTime,
  dateFormat,
  shortTimestamp,
} from 'shared/helpers/timeHelper';

const props = defineProps({
  isAutoRefreshEnabled: {
    type: Boolean,
    default: true,
  },
  lastActivityTimestamp: {
    type: [String, Date, Number],
    default: '',
  },
  createdAtTimestamp: {
    type: [String, Date, Number],
    default: '',
  },
});

const MINUTE_IN_MILLI_SECONDS = 60000;
const HOUR_IN_MILLI_SECONDS = MINUTE_IN_MILLI_SECONDS * 60;
const DAY_IN_MILLI_SECONDS = HOUR_IN_MILLI_SECONDS * 24;

const { t } = useI18n();

const lastActivityAtTimeAgo = ref(dynamicTime(props.lastActivityTimestamp));
const createdAtTimeAgo = ref(dynamicTime(props.createdAtTimestamp));
const timer = ref(null);

const lastActivityTime = computed(() =>
  shortTimestamp(lastActivityAtTimeAgo.value)
);

const createdAtTime = computed(() => shortTimestamp(createdAtTimeAgo.value));

const createdAt = computed(() => {
  const createdTimeDiff = Date.now() - props.createdAtTimestamp * 1000;
  const isBeforeAMonth = createdTimeDiff > DAY_IN_MILLI_SECONDS * 30;
  return !isBeforeAMonth
    ? `${t('CHAT_LIST.CHAT_TIME_STAMP.CREATED.LATEST')} ${createdAtTimeAgo.value}`
    : `${t('CHAT_LIST.CHAT_TIME_STAMP.CREATED.OLDEST')} ${dateFormat(props.createdAtTimestamp)}`;
});

const lastActivity = computed(() => {
  const lastActivityTimeDiff = Date.now() - props.lastActivityTimestamp * 1000;
  const isNotActive = lastActivityTimeDiff > DAY_IN_MILLI_SECONDS * 30;
  return !isNotActive
    ? `${t('CHAT_LIST.CHAT_TIME_STAMP.LAST_ACTIVITY.ACTIVE')} ${lastActivityAtTimeAgo.value}`
    : `${t('CHAT_LIST.CHAT_TIME_STAMP.LAST_ACTIVITY.NOT_ACTIVE')} ${dateFormat(props.lastActivityTimestamp)}`;
});

const tooltipText = computed(() => {
  return `${createdAt.value}
${lastActivity.value}`;
});

const refreshTime = () => {
  const timeDiff = Date.now() - props.lastActivityTimestamp * 1000;
  if (timeDiff > DAY_IN_MILLI_SECONDS) {
    return DAY_IN_MILLI_SECONDS;
  }
  if (timeDiff > HOUR_IN_MILLI_SECONDS) {
    return HOUR_IN_MILLI_SECONDS;
  }
  return MINUTE_IN_MILLI_SECONDS;
};

const createTimer = () => {
  timer.value = setTimeout(() => {
    lastActivityAtTimeAgo.value = dynamicTime(props.lastActivityTimestamp);
    createdAtTimeAgo.value = dynamicTime(props.createdAtTimestamp);
    createTimer();
  }, refreshTime());
};

watch(
  () => props.lastActivityTimestamp,
  () => {
    lastActivityAtTimeAgo.value = dynamicTime(props.lastActivityTimestamp);
  }
);

watch(
  () => props.createdAtTimestamp,
  () => {
    createdAtTimeAgo.value = dynamicTime(props.createdAtTimestamp);
  }
);

onMounted(() => {
  if (props.isAutoRefreshEnabled) {
    createTimer();
  }
});

onUnmounted(() => {
  clearTimeout(timer.value);
});
</script>

<template>
  <div
    v-tooltip.top="{
      content: tooltipText,
      delay: { show: 1000, hide: 0 },
    }"
    class="ml-auto text-label-small text-n-slate-11 hover:text-n-slate-12"
  >
    <span>{{ `${createdAtTime} • ${lastActivityTime}` }}</span>
  </div>
</template>
