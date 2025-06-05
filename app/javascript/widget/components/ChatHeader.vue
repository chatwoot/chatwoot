<script setup>
import { toRef, computed } from 'vue';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import HeaderActions from './HeaderActions.vue';
import AvailabilityContainer from 'widget/components/Availability/AvailabilityContainer.vue';
import { isOnline as checkIsOnline } from 'widget/helpers/availabilityHelpers';
import { useReplaceRoute } from 'widget/composables/useReplaceRoute';

const props = defineProps({
  avatarUrl: { type: String, default: '' },
  title: { type: String, default: '' },
  showPopoutButton: { type: Boolean, default: false },
  showBackButton: { type: Boolean, default: false },
  availableAgents: { type: Array, default: () => [] },
});

const availableAgents = toRef(props, 'availableAgents');

const { replaceRoute } = useReplaceRoute();

const channelConfig = computed(() => window.chatwootWebChannel || {});

const inboxConfig = computed(() => ({
  workingHours: channelConfig.value.workingHours || [],
  workingHoursEnabled: channelConfig.value.workingHoursEnabled || false,
  timezone: channelConfig.value.timezone || 'UTC',
  utcOffset:
    channelConfig.value.utcOffset || channelConfig.value.timezone || 'UTC',
  replyTime: channelConfig.value.replyTime || 'in_a_few_minutes',
}));

const currentTime = computed(() => new Date());
const workingHours = computed(() => props.inboxConfig.workingHours || []);
const workingHoursEnabled = computed(
  () => props.inboxConfig.workingHoursEnabled || false
);
const utcOffset = computed(
  () => props.inboxConfig.utcOffset || props.inboxConfig.timezone || 'UTC'
);
const hasOnlineAgents = computed(() => props.agents.length > 0);

const isOnline = computed(() =>
  checkIsOnline(
    workingHoursEnabled.value,
    currentTime.value,
    utcOffset.value,
    workingHours.value,
    hasOnlineAgents.value
  )
);

const onBackButtonClick = () => {
  replaceRoute('home');
};
</script>

<template>
  <header class="flex justify-between w-full p-5 bg-n-background gap-2">
    <div class="flex items-center">
      <button
        v-if="showBackButton"
        class="px-2 ltr:-ml-3 rtl:-mr-3"
        @click="onBackButtonClick"
      >
        <FluentIcon icon="chevron-left" size="24" class="text-n-slate-12" />
      </button>
      <img
        v-if="avatarUrl"
        class="w-8 h-8 ltr:mr-3 rtl:ml-3 rounded-full"
        :src="avatarUrl"
        alt="avatar"
      />
      <div class="flex flex-col gap-1">
        <div
          class="flex items-center text-base font-medium leading-4 text-n-slate-12"
        >
          <span v-dompurify-html="title" class="ltr:mr-1 rtl:ml-1" />
          <div
            :class="`h-2 w-2 rounded-full
              ${isOnline ? 'bg-green-500' : 'hidden'}`"
          />
        </div>
        <AvailabilityContainer
          :inbox-config="inboxConfig"
          :agents="availableAgents"
          :show-header="false"
          :show-avatars="false"
          class="[&_.availability-text]:text-xs [&_.availability-text]:leading-3"
        />
      </div>
    </div>
    <HeaderActions :show-popout-button="showPopoutButton" />
  </header>
</template>
