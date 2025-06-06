<script setup>
import { computed, toRef } from 'vue';
import { useI18n } from 'vue-i18n';
import GroupedAvatars from 'widget/components/GroupedAvatars.vue';
import AvailabilityText from './AvailabilityText.vue';
import { useAvailability } from 'widget/composables/useAvailability';

const props = defineProps({
  agents: {
    type: Array,
    default: () => [],
  },
  showHeader: {
    type: Boolean,
    default: true,
  },
  showAvatars: {
    type: Boolean,
    default: true,
  },
});

const { t } = useI18n();

const availableAgents = toRef(props, 'agents');

const {
  currentTime,
  hasOnlineAgents,
  isOnline,
  inboxConfig,
  isInWorkingHours,
} = useAvailability(availableAgents);

const workingHours = computed(() => inboxConfig.value.workingHours || []);
const workingHoursEnabled = computed(
  () => inboxConfig.value.workingHoursEnabled || false
);
const utcOffset = computed(
  () => inboxConfig.value.utcOffset || inboxConfig.value.timezone || 'UTC'
);
const replyTime = computed(
  () => inboxConfig.value.replyTime || 'in_a_few_minutes'
);

const headerText = computed(() =>
  isOnline.value || (workingHoursEnabled.value && isInWorkingHours.value) // If online or in working hours
    ? t('TEAM_AVAILABILITY.ONLINE')
    : t('TEAM_AVAILABILITY.OFFLINE')
);
</script>

<template>
  <div class="flex items-center justify-between gap-2">
    <div class="flex flex-col gap-1">
      <div v-if="showHeader" class="font-medium text-n-slate-12">
        {{ headerText }}
      </div>

      <AvailabilityText
        :time="currentTime"
        :utc-offset="utcOffset"
        :working-hours="workingHours"
        :working-hours-enabled="workingHoursEnabled"
        :has-online-agents="hasOnlineAgents"
        :reply-time="replyTime"
        :is-online="isOnline"
        :is-in-working-hours="isInWorkingHours"
        class="text-n-slate-11 availability-text"
      />
    </div>

    <GroupedAvatars v-if="showAvatars && isOnline" :users="agents" />
  </div>
</template>
