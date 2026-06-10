<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import CardPriorityIcon from 'dashboard/components-next/Conversation/ConversationCard/CardPriorityIcon.vue';
import ConversationResolveAttributesModal from 'dashboard/components-next/ConversationWorkflow/ConversationResolveAttributesModal.vue';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useHaptics } from 'dashboard/composables/useHaptics';
import { useConversationRequiredAttributes } from 'dashboard/composables/useConversationRequiredAttributes';
import { findSnoozeTime } from 'dashboard/helper/snoozeHelpers';
import wootConstants from 'dashboard/constants/globals';
import MobileActionPickerSheet from './MobileActionPickerSheet.vue';
import MobileMultiPickerSheet from './MobileMultiPickerSheet.vue';

const props = defineProps({
  conversationId: {
    type: Number,
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();
const { medium, success } = useHaptics();
const { checkMissingAttributes } = useConversationRequiredAttributes();
const currentChat = useMapGetter('getSelectedChat');

const resolveAttributesModalRef = ref(null);
const showAssigneeSheet = ref(false);
const showTeamSheet = ref(false);
const showPrioritySheet = ref(false);
const showLabelsSheet = ref(false);
const showParticipantsSheet = ref(false);

const conversation = computed(() => {
  if (currentChat.value?.id === props.conversationId) {
    return currentChat.value;
  }

  return store.getters.getConversationById(props.conversationId) || null;
});

const accountLabels = computed(() => store.getters['labels/getLabels'] || []);
const conversationLabels = computed(
  () =>
    store.getters['conversationLabels/getConversationLabels'](
      props.conversationId
    ) || []
);
const conversationParticipants = computed(
  () =>
    store.getters['conversationWatchers/getByConversationId'](
      props.conversationId
    ) || []
);
const agents = computed(() => store.getters['agents/getAgents'] || []);
const teams = computed(() => store.getters['teams/getTeams'] || []);

const currentAssignee = computed(
  () => conversation.value?.meta?.assignee || null
);
const currentTeam = computed(() => conversation.value?.meta?.team || null);
const currentPriority = computed(() => conversation.value?.priority || null);

const statusCards = computed(() => [
  {
    key: wootConstants.STATUS_TYPE.OPEN,
    icon: 'i-lucide-refresh-cw',
    label: t('MOBILE.ACTIONS.STATUS.OPEN'),
    containerClass: 'bg-n-slate-2 border-n-slate-7',
    iconClass: 'text-n-slate-11',
  },
  {
    key: wootConstants.STATUS_TYPE.PENDING,
    icon: 'i-lucide-circle-dot-dashed',
    label: t('MOBILE.ACTIONS.STATUS.PENDING'),
    containerClass: 'bg-n-amber-3 border-n-amber-7',
    iconClass: 'text-n-amber-10',
  },
  {
    key: wootConstants.STATUS_TYPE.SNOOZED,
    icon: 'i-lucide-moon-star',
    label: t('MOBILE.ACTIONS.STATUS.SNOOZE'),
    containerClass: 'bg-n-indigo-3 border-n-indigo-7',
    iconClass: 'text-n-indigo-10',
  },
  {
    key: wootConstants.STATUS_TYPE.RESOLVED,
    icon: 'i-lucide-check-check',
    label: t('MOBILE.ACTIONS.STATUS.RESOLVE'),
    containerClass: 'bg-n-teal-3 border-n-teal-7',
    iconClass: 'text-n-teal-10',
  },
]);

const assigneeItems = computed(() => [
  {
    key: 'none',
    value: null,
    label: t('MOBILE.ACTIONS.ASSIGNEE.NONE'),
    description: t('MOBILE.ACTIONS.CTA.ASSIGN'),
    icon: 'i-lucide-user-round-x',
  },
  ...agents.value.map(agent => ({
    key: agent.id,
    value: agent.id,
    label: agent.name,
    description: agent.email,
    avatar: agent.thumbnail || agent.avatar_url || '',
    name: agent.name,
  })),
]);

const teamItems = computed(() => [
  {
    key: 'none',
    value: 0,
    label: t('MOBILE.ACTIONS.TEAM.NONE'),
    description: t('MOBILE.ACTIONS.CTA.ASSIGN'),
    icon: 'i-lucide-shield-off',
  },
  ...teams.value.map(team => ({
    key: team.id,
    value: team.id,
    label: team.name,
    description: t('MOBILE.ACTIONS.SECTIONS.SETTINGS'),
    icon: 'i-lucide-shield',
  })),
]);

const priorityItems = computed(() => [
  {
    key: 'none',
    value: null,
    label: t('CONVERSATION.PRIORITY.OPTIONS.NONE'),
    icon: 'i-lucide-signal-low',
  },
  {
    key: 'urgent',
    value: 'urgent',
    label: t('CONVERSATION.PRIORITY.OPTIONS.URGENT'),
    icon: 'i-lucide-signal-high',
  },
  {
    key: 'high',
    value: 'high',
    label: t('CONVERSATION.PRIORITY.OPTIONS.HIGH'),
    icon: 'i-lucide-signal-high',
  },
  {
    key: 'medium',
    value: 'medium',
    label: t('CONVERSATION.PRIORITY.OPTIONS.MEDIUM'),
    icon: 'i-lucide-signal-medium',
  },
  {
    key: 'low',
    value: 'low',
    label: t('CONVERSATION.PRIORITY.OPTIONS.LOW'),
    icon: 'i-lucide-signal',
  },
]);

const labelItems = computed(() =>
  accountLabels.value.map(label => ({
    key: label.title,
    label: label.title,
  }))
);

const participantItems = computed(() =>
  agents.value.map(agent => ({
    key: agent.id,
    label: agent.name,
    description: agent.email,
    avatar: agent.thumbnail || agent.avatar_url || '',
    name: agent.name,
  }))
);

const formattedConversationAttributes = computed(() => {
  const currentConversation = conversation.value;
  if (!currentConversation) return [];

  const additionalAttributes = currentConversation.additional_attributes || {};
  const browser = additionalAttributes.browser || {};
  const senderAttributes =
    currentConversation.meta?.sender?.additional_attributes || {};

  const rows = [
    {
      key: 'conversation-id',
      label: t('MOBILE.ACTIONS.ATTRIBUTES.CONVERSATION_ID'),
      value: String(currentConversation.id),
    },
    {
      key: 'browser',
      label: t('MOBILE.ACTIONS.ATTRIBUTES.BROWSER'),
      value: [browser.browser_name, browser.browser_version]
        .filter(Boolean)
        .join(' '),
    },
    {
      key: 'operating-system',
      label: t('MOBILE.ACTIONS.ATTRIBUTES.OPERATING_SYSTEM'),
      value: [browser.platform_name, browser.platform_version]
        .filter(Boolean)
        .join(' '),
    },
    {
      key: 'referer',
      label: t('MOBILE.ACTIONS.ATTRIBUTES.REFERER'),
      value: additionalAttributes.referer,
    },
    {
      key: 'ip-address',
      label: t('MOBILE.ACTIONS.ATTRIBUTES.IP_ADDRESS'),
      value: senderAttributes.created_at_ip,
    },
  ].filter(item => item.value);

  const customAttributes = Object.entries(
    currentConversation.custom_attributes || {}
  ).map(([key, value]) => ({
    key: `custom-${key}`,
    label: key
      .split('_')
      .filter(Boolean)
      .map(part => part.charAt(0).toUpperCase() + part.slice(1))
      .join(' '),
    value: (() => {
      if (Array.isArray(value)) return value.join(', ');
      if (typeof value === 'object' && value !== null) {
        return JSON.stringify(value);
      }
      return String(value);
    })(),
  }));

  return [...rows, ...customAttributes].filter(
    item => item.value && item.value !== 'null'
  );
});

const updateStatus = async (status, customAttributes = null) => {
  const payload = {
    conversationId: props.conversationId,
    status,
    snoozedUntil:
      status === wootConstants.STATUS_TYPE.SNOOZED
        ? findSnoozeTime(wootConstants.SNOOZE_OPTIONS.UNTIL_NEXT_REPLY) || null
        : null,
  };

  if (customAttributes) payload.customAttributes = customAttributes;

  await store.dispatch('toggleStatus', payload);
  if (status === wootConstants.STATUS_TYPE.RESOLVED) {
    success();
  } else {
    medium();
  }
  useAlert(t('CONVERSATION.CHANGE_STATUS'));
};

const handleStatusChange = async status => {
  if (!conversation.value || conversation.value.status === status) return;

  if (status !== wootConstants.STATUS_TYPE.RESOLVED) {
    await updateStatus(status);
    return;
  }

  const currentCustomAttributes = conversation.value.custom_attributes || {};
  const { hasMissing, missing } = checkMissingAttributes(
    currentCustomAttributes
  );

  if (hasMissing) {
    resolveAttributesModalRef.value?.open(missing, currentCustomAttributes, {
      id: props.conversationId,
      snoozedUntil: conversation.value.snoozed_until,
    });
    return;
  }

  await updateStatus(status);
};

const handleResolveWithAttributes = async ({ attributes, context }) => {
  if (!context) return;

  const currentCustomAttributes = conversation.value?.custom_attributes || {};
  const mergedAttributes = { ...currentCustomAttributes, ...attributes };
  await updateStatus(wootConstants.STATUS_TYPE.RESOLVED, mergedAttributes);
};

const handleAssigneeSelect = async item => {
  const assignee = item.value
    ? agents.value.find(agent => agent.id === item.value) || null
    : null;

  store.dispatch('setCurrentChatAssignee', {
    conversationId: props.conversationId,
    assignee,
  });
  await store.dispatch('assignAgent', {
    conversationId: props.conversationId,
    agentId: item.value,
  });
  medium();
  useAlert(t('CONVERSATION.CHANGE_AGENT'));
  showAssigneeSheet.value = false;
};

const handleTeamSelect = async item => {
  const team = item.value
    ? teams.value.find(entry => entry.id === item.value) || null
    : null;

  store.dispatch('setCurrentChatTeam', {
    conversationId: props.conversationId,
    team,
  });
  await store.dispatch('assignTeam', {
    conversationId: props.conversationId,
    teamId: item.value,
  });
  medium();
  useAlert(t('CONVERSATION.CHANGE_TEAM'));
  showTeamSheet.value = false;
};

const handlePrioritySelect = async item => {
  store.dispatch('setCurrentChatPriority', {
    conversationId: props.conversationId,
    priority: item.value,
  });
  await store.dispatch('assignPriority', {
    conversationId: props.conversationId,
    priority: item.value,
  });
  medium();
  useAlert(
    t('CONVERSATION.PRIORITY.CHANGE_PRIORITY.SUCCESSFUL', {
      priority: item.label,
      conversationId: props.conversationId,
    })
  );
  showPrioritySheet.value = false;
};

const handleLabelsApply = async selectedKeys => {
  await store.dispatch('conversationLabels/update', {
    conversationId: props.conversationId,
    labels: selectedKeys,
  });
  medium();
  useAlert(t('CONVERSATION.ASSIGN_LABEL_SUCCESFUL'));
  showLabelsSheet.value = false;
};

const handleParticipantsApply = async selectedKeys => {
  let alertMessage = t('CONVERSATION_PARTICIPANTS.API.SUCCESS_MESSAGE');

  try {
    await store.dispatch('conversationWatchers/update', {
      conversationId: props.conversationId,
      userIds: selectedKeys,
    });
    medium();
  } catch (error) {
    alertMessage =
      error?.message || t('CONVERSATION_PARTICIPANTS.API.ERROR_MESSAGE');
  } finally {
    useAlert(alertMessage);
  }

  showParticipantsSheet.value = false;
  store.dispatch('conversationWatchers/show', {
    conversationId: props.conversationId,
  });
};

const refreshConversationSideData = () => {
  store.dispatch('teams/get');
  store.dispatch('labels/get');
  store.dispatch('conversationLabels/get', props.conversationId);
  store.dispatch('conversationWatchers/show', {
    conversationId: props.conversationId,
  });
};

onMounted(refreshConversationSideData);

watch(
  () => props.conversationId,
  () => {
    refreshConversationSideData();
  }
);
</script>

<template>
  <div
    class="min-h-full bg-n-surface-1 pb-[calc(24px+env(safe-area-inset-bottom))]"
  >
    <section class="px-4 pt-5">
      <div class="grid grid-cols-4 gap-3">
        <button
          v-for="card in statusCards"
          :key="card.key"
          class="relative flex min-w-0 flex-col items-center overflow-hidden rounded-2xl border px-1 pb-3.5 pt-5 shadow-sm transition-transform duration-150 active:scale-[0.96]"
          :class="[
            card.containerClass,
            conversation?.status === card.key
              ? 'ring-2 ring-n-slate-8'
              : 'border-transparent',
          ]"
          @click="handleStatusChange(card.key)"
        >
          <span class="block text-center" :class="card.iconClass">
            <span class="mx-auto block size-7" :class="card.icon" />
          </span>
          <span
            class="mt-3 block w-full break-words px-0.5 text-center text-[13px] font-medium leading-tight text-n-slate-12"
          >
            {{ card.label }}
          </span>
        </button>
      </div>
    </section>

    <section class="px-4 pt-6">
      <div
        class="overflow-hidden rounded-2xl border border-n-weak bg-white dark:bg-n-background shadow-sm"
      >
        <button
          class="flex w-full items-center gap-3 px-4 py-3 text-left active:bg-n-alpha-2"
          @click="showAssigneeSheet = true"
        >
          <Avatar
            :src="
              currentAssignee?.thumbnail || currentAssignee?.avatar_url || ''
            "
            :name="currentAssignee?.name || t('MOBILE.ACTIONS.ASSIGNEE.NONE')"
            :size="36"
            class="shrink-0"
          />
          <div class="min-w-0 flex-1">
            <p class="truncate text-sm font-medium text-n-slate-12">
              {{ currentAssignee?.name || t('MOBILE.ACTIONS.ASSIGNEE.NONE') }}
            </p>
          </div>
          <span class="text-sm text-n-slate-10">{{
            t('MOBILE.ACTIONS.CTA.CHANGE')
          }}</span>
          <span class="i-lucide-chevron-right size-4 text-n-slate-9" />
        </button>

        <button
          class="flex w-full items-center gap-3 border-t border-n-weak px-4 py-3 text-left active:bg-n-alpha-2"
          @click="showTeamSheet = true"
        >
          <span
            class="flex size-9 shrink-0 items-center justify-center rounded-full bg-n-surface-2 text-n-slate-11"
          >
            <span class="i-lucide-shield size-5" />
          </span>
          <div class="min-w-0 flex-1">
            <p class="truncate text-sm font-medium text-n-slate-12">
              {{ currentTeam?.name || t('MOBILE.ACTIONS.TEAM.NONE') }}
            </p>
          </div>
          <span class="text-sm text-n-slate-10">
            {{
              currentTeam
                ? t('MOBILE.ACTIONS.CTA.CHANGE')
                : t('MOBILE.ACTIONS.CTA.ASSIGN')
            }}
          </span>
          <span class="i-lucide-chevron-right size-4 text-n-slate-9" />
        </button>

        <button
          class="flex w-full items-center gap-3 border-t border-n-weak px-4 py-3 text-left active:bg-n-alpha-2"
          @click="showPrioritySheet = true"
        >
          <span
            class="flex size-9 shrink-0 items-center justify-center rounded-full bg-n-surface-2 text-n-slate-11"
          >
            <CardPriorityIcon
              v-if="currentPriority"
              :priority="currentPriority"
            />
            <span v-else class="i-lucide-bar-chart-3 size-5" />
          </span>
          <div class="min-w-0 flex-1">
            <p class="truncate text-sm font-medium text-n-slate-12">
              {{
                currentPriority
                  ? t(
                      `CONVERSATION.PRIORITY.OPTIONS.${currentPriority.toUpperCase()}`
                    )
                  : t('MOBILE.ACTIONS.PRIORITY.NONE')
              }}
            </p>
          </div>
          <span class="text-sm text-n-slate-10">{{
            t('MOBILE.ACTIONS.CTA.CHANGE')
          }}</span>
          <span class="i-lucide-chevron-right size-4 text-n-slate-9" />
        </button>
      </div>
    </section>

    <section class="px-4 pt-7">
      <div class="mb-2 flex items-center justify-between gap-3">
        <h3 class="text-[13px] font-medium text-n-slate-10">
          {{ t('MOBILE.ACTIONS.SECTIONS.LABELS') }}
        </h3>
        <Button
          :label="t('MOBILE.ACTIONS.CTA.ADD_LABEL')"
          color="blue"
          variant="faded"
          sm
          icon="i-lucide-tag"
          @click="showLabelsSheet = true"
        />
      </div>

      <div
        class="min-h-[4.75rem] rounded-2xl border border-n-weak bg-white dark:bg-n-background px-4 py-4 shadow-sm"
      >
        <div v-if="conversationLabels.length" class="flex flex-wrap gap-2">
          <span
            v-for="label in conversationLabels"
            :key="label"
            class="rounded-full bg-n-brand/10 px-3 py-1 text-sm font-medium text-n-brand"
          >
            {{ label }}
          </span>
        </div>
        <p v-else class="text-sm text-n-slate-10">
          {{ t('MOBILE.ACTIONS.LABELS.EMPTY') }}
        </p>
      </div>
    </section>

    <section class="px-4 pt-7">
      <h3 class="mb-2 text-[13px] font-medium text-n-slate-10">
        {{ t('MOBILE.ACTIONS.SECTIONS.PARTICIPANTS') }}
      </h3>
      <div
        class="overflow-hidden rounded-2xl border border-n-weak bg-white dark:bg-n-background shadow-sm"
      >
        <div v-if="conversationParticipants.length">
          <div
            v-for="participant in conversationParticipants.slice(0, 4)"
            :key="participant.id"
            class="flex items-center gap-3 px-4 py-3"
            :class="{
              'border-t border-n-weak':
                participant !== conversationParticipants[0],
            }"
          >
            <Avatar
              :src="participant.thumbnail || participant.avatar_url || ''"
              :name="participant.name"
              :size="36"
              class="shrink-0"
            />
            <p class="truncate text-sm font-medium text-n-slate-12">
              {{ participant.name }}
            </p>
          </div>
        </div>
        <p v-else class="px-4 py-4 text-sm text-n-slate-10">
          {{ t('MOBILE.ACTIONS.PARTICIPANTS.EMPTY') }}
        </p>

        <button
          class="flex w-full items-center gap-3 border-t border-n-weak px-4 py-3 text-left active:bg-n-blue-2"
          @click="showParticipantsSheet = true"
        >
          <span
            class="flex size-9 items-center justify-center rounded-full bg-n-blue-2 text-n-blue-9"
          >
            <span class="i-lucide-user-round-plus size-5" />
          </span>
          <span class="text-base font-medium text-n-blue-9">
            {{ t('MOBILE.ACTIONS.CTA.ADD_PARTICIPANT') }}
          </span>
        </button>
      </div>
    </section>

    <section class="px-4 pt-7">
      <h3 class="mb-2 text-[13px] font-medium text-n-slate-10">
        {{ t('MOBILE.ACTIONS.SECTIONS.ATTRIBUTES') }}
      </h3>
      <div
        class="overflow-hidden rounded-2xl border border-n-weak bg-white dark:bg-n-background shadow-sm"
      >
        <div
          v-for="attribute in formattedConversationAttributes"
          :key="attribute.key"
          class="px-4 py-3"
          :class="{
            'border-t border-n-weak':
              attribute !== formattedConversationAttributes[0],
          }"
        >
          <div class="flex items-start justify-between gap-4">
            <span class="text-sm text-n-slate-11">{{ attribute.label }}</span>
            <span
              class="max-w-[55%] break-words text-right text-sm font-medium text-n-slate-12"
            >
              {{ attribute.value }}
            </span>
          </div>
        </div>
      </div>
    </section>

    <MobileActionPickerSheet
      :open="showAssigneeSheet"
      :title="t('MOBILE.ACTIONS.PICKERS.ASSIGNEE')"
      :items="assigneeItems"
      :selected-key="currentAssignee?.id || 'none'"
      :search-placeholder="t('MOBILE.ACTIONS.SEARCH.ASSIGNEE')"
      :empty-text="t('MOBILE.ACTIONS.EMPTY.ASSIGNEE')"
      @close="showAssigneeSheet = false"
      @select="handleAssigneeSelect"
    />

    <MobileActionPickerSheet
      :open="showTeamSheet"
      :title="t('MOBILE.ACTIONS.PICKERS.TEAM')"
      :items="teamItems"
      :selected-key="currentTeam?.id || 'none'"
      :search-placeholder="t('MOBILE.ACTIONS.SEARCH.TEAM')"
      :empty-text="t('MOBILE.ACTIONS.EMPTY.TEAM')"
      @close="showTeamSheet = false"
      @select="handleTeamSelect"
    />

    <MobileActionPickerSheet
      :open="showPrioritySheet"
      :title="t('MOBILE.ACTIONS.PICKERS.PRIORITY')"
      :items="priorityItems"
      :selected-key="currentPriority || 'none'"
      :empty-text="t('MOBILE.ACTIONS.EMPTY.PRIORITY')"
      @close="showPrioritySheet = false"
      @select="handlePrioritySelect"
    />

    <MobileMultiPickerSheet
      :open="showLabelsSheet"
      :title="t('MOBILE.ACTIONS.PICKERS.LABELS')"
      :items="labelItems"
      :selected-keys="conversationLabels"
      :search-placeholder="t('MOBILE.ACTIONS.SEARCH.LABELS')"
      :empty-text="t('MOBILE.ACTIONS.EMPTY.LABELS')"
      :apply-label="t('MOBILE.ACTIONS.CTA.APPLY')"
      @close="showLabelsSheet = false"
      @apply="handleLabelsApply"
    />

    <MobileMultiPickerSheet
      :open="showParticipantsSheet"
      :title="t('MOBILE.ACTIONS.PICKERS.PARTICIPANTS')"
      :items="participantItems"
      :selected-keys="
        conversationParticipants.map(participant => participant.id)
      "
      :search-placeholder="t('MOBILE.ACTIONS.SEARCH.PARTICIPANTS')"
      :empty-text="t('MOBILE.ACTIONS.EMPTY.PARTICIPANTS')"
      :apply-label="t('MOBILE.ACTIONS.CTA.APPLY')"
      @close="showParticipantsSheet = false"
      @apply="handleParticipantsApply"
    />

    <ConversationResolveAttributesModal
      ref="resolveAttributesModalRef"
      @submit="handleResolveWithAttributes"
    />
  </div>
</template>
