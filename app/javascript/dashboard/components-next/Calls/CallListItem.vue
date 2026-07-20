<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { relativeDayTimestamp } from 'shared/helpers/timeHelper';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import AudioPlayer from 'dashboard/components-next/audio/AudioPlayer.vue';
import {
  VOICE_CALL_DIRECTION,
  VOICE_CALL_STATUS,
} from 'dashboard/components-next/message/constants';
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
  if (kind.value === CALL_KIND.INCOMING) return t('CALLS_PAGE.ROW.PICKED_BY');
  // Ongoing collapses direction, so resolve dialed-vs-picked from the raw value.
  if (kind.value === CALL_KIND.ONGOING) {
    return props.call.direction === VOICE_CALL_DIRECTION.OUTBOUND
      ? t('CALLS_PAGE.ROW.DIALED_BY')
      : t('CALLS_PAGE.ROW.PICKED_BY');
  }
  return '';
});

const resultLabel = computed(() => {
  if (kind.value === CALL_KIND.MISSED) return t('CALLS_PAGE.ROW.NO_AGENT');
  if (kind.value === CALL_KIND.NO_REPLY) {
    return t('CALLS_PAGE.ROW.NO_CONTACT_ANSWER');
  }
  if (kind.value === CALL_KIND.FAILED) return t('CALLS_PAGE.ROW.FAILED');
  if (kind.value === CALL_KIND.ONGOING) {
    return props.call.status === VOICE_CALL_STATUS.RINGING
      ? t('CALLS_PAGE.ROW.RINGING')
      : t('CALLS_PAGE.ROW.IN_PROGRESS');
  }
  return t('CALLS_PAGE.ROW.ANSWERED');
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
  query: { messageId: props.call.messageId },
}));
</script>

<template>
  <div class="flex flex-col gap-2 py-3.5 border-b border-n-weak lg:hidden">
    <div class="flex items-center gap-2 min-w-0">
      <Avatar
        :src="call.contact.avatar"
        :name="contactName"
        :size="24"
        rounded-full
      />
      <span
        v-tooltip.top="{ content: contactName, delay: { show: 500, hide: 0 } }"
        class="text-heading-3 font-medium truncate text-n-slate-12 min-w-0"
      >
        {{ contactName }}
      </span>
      <CallStatusBadge :kind="kind" class="ms-auto shrink-0" />
      <RouterLink
        :to="conversationRoute"
        class="inline-flex items-center h-6 gap-1 px-2 text-label-small outline outline-1 -outline-offset-1 rounded-md outline-n-weak text-n-slate-11 hover:bg-n-alpha-1 shrink-0"
      >
        <Icon icon="i-lucide-message-circle" class="size-3.5 text-n-slate-11" />
        {{ call.conversation.displayId }}
        <Icon icon="i-lucide-arrow-up-right" class="size-3.5 text-n-slate-11" />
      </RouterLink>
    </div>
    <div class="flex items-center gap-1.5 min-w-0">
      <template v-if="agentActionLabel">
        <span class="text-label-small text-n-slate-10 shrink-0">
          {{ agentActionLabel }}
        </span>
        <Avatar
          :src="call.agent.avatar"
          :name="call.agent.name"
          :size="20"
          rounded-full
        />
        <span class="text-body-main truncate text-n-slate-12 min-w-0">
          {{ call.agent.name }}
        </span>
      </template>
      <span v-else class="text-body-main truncate text-n-slate-10 min-w-0">
        {{ resultLabel }}
      </span>
      <span class="w-px h-3 bg-n-strong shrink-0" />
      <Icon :icon="providerIcon" class="size-4 text-n-slate-11 shrink-0" />
      <span class="text-body-main truncate text-n-slate-11 min-w-0">
        {{ call.inbox.name }}
      </span>
      <span
        v-if="!call.recordingUrl"
        class="ms-auto shrink-0 text-label-small text-n-slate-11 tabular-nums"
      >
        {{ createdAtLabel }}
      </span>
    </div>
    <div
      v-if="call.recordingUrl"
      class="flex items-center gap-2 min-w-0 justify-between"
    >
      <AudioPlayer
        :src="call.recordingUrl"
        :fallback-duration="call.durationSeconds || 0"
        class="flex-1 sm:flex-[0.7] min-w-0"
      />
      <span class="shrink-0 text-label-small text-n-slate-11 tabular-nums">
        {{ createdAtLabel }}
      </span>
    </div>
  </div>

  <div
    class="hidden items-center gap-x-1.5 gap-y-2.5 border-b border-n-weak lg:flex lg:items-center lg:gap-1.5"
  >
    <div class="flex items-center gap-2.5 min-w-0 w-40 shrink-0 py-3.5">
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
      class="flex flex-nowrap items-center gap-x-2 gap-y-2 min-w-0 grow shrink"
    >
      <div class="flex items-center gap-x-2 min-w-0 lg:contents py-3.5">
        <CallStatusBadge :kind="kind" class="shrink-0" />
        <template v-if="agentActionLabel">
          <span
            class="text-label-small text-n-slate-10 truncate min-w-0 shrink min-w-8"
          >
            {{ agentActionLabel }}
          </span>
          <span class="flex items-center gap-1.5 min-w-16 shrink-[20]">
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
          class="text-body-main truncate text-n-slate-10 min-w-0 shrink-[20]"
        >
          {{ resultLabel }}
        </span>
      </div>
      <AudioPlayer
        v-if="call.recordingUrl"
        :src="call.recordingUrl"
        :fallback-duration="call.durationSeconds || 0"
        class="w-auto min-w-44 shrink mx-auto"
      />
    </div>
    <div
      v-tooltip.top="{
        content: call.inbox.name,
        delay: { show: 500, hide: 0 },
      }"
      class="flex items-center gap-1.5 justify-start min-w-14 shrink-[100] py-3.5"
    >
      <Icon :icon="providerIcon" class="size-4 text-n-slate-11 shrink-0" />
      <span class="text-body-main truncate text-n-slate-11">
        {{ call.inbox.name }}
      </span>
    </div>
    <RouterLink
      :to="conversationRoute"
      class="inline-flex items-center h-6 gap-1 px-2 text-label-small py-3.5 outline outline-1 -outline-offset-1 rounded-md outline-n-weak text-n-slate-11 hover:bg-n-alpha-1 shrink-0 justify-self-start"
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
      class="text-label-small text-end text-n-slate-11 truncate py-3.5 tabular-nums justify-self-end w-16 shrink-0"
    >
      {{ createdAtLabel }}
    </span>
  </div>
</template>
