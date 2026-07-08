<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { relativeDayTimestamp } from 'shared/helpers/timeHelper';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import AudioPlayer from 'dashboard/components-next/audio/AudioPlayer.vue';
import CallStatusBadge from './CallStatusBadge.vue';
import { CALL_KIND, getCallKind } from './constants';

const props = defineProps({
  call: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const route = useRoute();

const kind = computed(() => getCallKind(props.call));

const contactName = computed(
  () => props.call.contact.name || props.call.contact.phoneNumber
);

const agentActionLabel = computed(() => {
  if (!props.call.agent) return '';
  if (kind.value === CALL_KIND.OUTGOING) return t('CALLS_PAGE.ROW.DIALED_BY');
  if ([CALL_KIND.ONGOING, CALL_KIND.INCOMING].includes(kind.value)) {
    return t('CALLS_PAGE.ROW.PICKED_BY');
  }
  return '';
});

const resultLabel = computed(() => {
  if (kind.value === CALL_KIND.MISSED) return t('CALLS_PAGE.ROW.NO_AGENT');
  if (kind.value === CALL_KIND.NO_REPLY) {
    return t('CALLS_PAGE.ROW.NO_CONTACT_ANSWER');
  }
  if (kind.value === CALL_KIND.FAILED) return t('CALLS_PAGE.ROW.FAILED');
  return '';
});

const providerIcon = computed(() =>
  props.call.provider === 'whatsapp' ? 'i-woot-whatsapp' : 'i-lucide-phone'
);

const createdAtLabel = computed(() =>
  relativeDayTimestamp(props.call.createdAt, t('CALLS_PAGE.ROW.YESTERDAY'))
);

const conversationRoute = computed(() => ({
  name: 'inbox_conversation',
  params: {
    accountId: route.params.accountId,
    conversation_id: props.call.conversation.displayId,
  },
}));
</script>

<template>
  <div
    class="grid items-center gap-x-1.5 gap-y-2.5 py-3.5 border-b border-n-weak grid-cols-[minmax(0,auto)_minmax(3.5rem,1fr)_auto_auto] [grid-template-areas:'contact_inbox_chip_date''status_status_status_status'] lg:flex lg:items-center lg:gap-1.5"
  >
    <div
      class="[grid-area:contact] flex items-center gap-2.5 min-w-0 lg:w-40 lg:shrink-0"
    >
      <Avatar
        :src="call.contact.avatar"
        :name="contactName"
        :size="24"
        rounded-full
      />
      <span
        v-tooltip.top="{ content: contactName, delay: { show: 500, hide: 0 } }"
        class="text-heading-3 font-medium truncate text-n-slate-12"
      >
        {{ contactName }}
      </span>
    </div>
    <div
      class="[grid-area:status] flex flex-wrap lg:flex-nowrap items-center gap-x-2 gap-y-2 min-w-0 lg:grow lg:shrink"
    >
      <!-- Nowrap sub-group keeps the badge and labels on one line (truncating)
           on mobile; lg:contents dissolves it so the lg flex layout is untouched. -->
      <div class="flex items-center gap-x-2 min-w-0 lg:contents">
        <CallStatusBadge :kind="kind" class="shrink-0" />
        <template v-if="agentActionLabel">
          <span
            class="text-label-small text-n-slate-10 truncate min-w-0 shrink-0 lg:shrink lg:min-w-8"
          >
            {{ agentActionLabel }}
          </span>
          <span
            class="flex items-center gap-1.5 min-w-0 lg:min-w-16 lg:shrink-[20]"
          >
            <Avatar
              :src="call.agent.avatar"
              :name="call.agent.name"
              :size="20"
              rounded-full
            />
            <span
              v-tooltip.top="{
                content: call.agent.name,
                delay: { show: 500, hide: 0 },
              }"
              class="text-body-main truncate text-n-slate-12 min-w-0"
            >
              {{ call.agent.name }}
            </span>
          </span>
        </template>
        <span
          v-else-if="resultLabel"
          class="text-body-main truncate text-n-slate-10 min-w-0 lg:shrink-[20]"
        >
          {{ resultLabel }}
        </span>
      </div>
      <AudioPlayer
        v-if="call.recordingUrl"
        :src="call.recordingUrl"
        :fallback-duration="call.durationSeconds || 0"
        class="w-full lg:w-auto lg:min-w-44 lg:shrink lg:mx-auto"
      />
    </div>
    <div
      v-tooltip.top="{
        content: call.inbox.name,
        delay: { show: 500, hide: 0 },
      }"
      class="[grid-area:inbox] flex items-center gap-1.5 min-w-0 justify-end lg:justify-start lg:min-w-14 lg:shrink-[100]"
    >
      <Icon :icon="providerIcon" class="size-4 text-n-slate-11 shrink-0" />
      <span class="text-body-main truncate text-n-slate-11">
        {{ call.inbox.name }}
      </span>
    </div>
    <RouterLink
      :to="conversationRoute"
      class="[grid-area:chip] inline-flex items-center h-6 gap-1 px-2 text-label-small outline outline-1 -outline-offset-1 rounded-md outline-n-weak text-n-slate-11 hover:bg-n-alpha-1 shrink-0 justify-self-start"
    >
      <Icon icon="i-lucide-message-circle" class="size-3.5 text-n-slate-11" />
      {{ call.conversation.displayId }}
      <Icon icon="i-lucide-arrow-up-right" class="size-3.5 text-n-slate-11" />
    </RouterLink>
    <span
      v-tooltip.top="{
        content: createdAtLabel,
        delay: { show: 500, hide: 0 },
      }"
      class="[grid-area:date] text-label-small text-end text-n-slate-11 truncate tabular-nums justify-self-end w-16 lg:shrink-0"
    >
      {{ createdAtLabel }}
    </span>
  </div>
</template>
