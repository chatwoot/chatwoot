import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';
import { emitter } from 'shared/helpers/mitt';
import { useAlert } from 'dashboard/composables';
import { useConversationLabels } from 'dashboard/composables/useConversationLabels';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useAgentsList } from 'dashboard/composables/useAgentsList';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { conversationUrl, frontendURL } from 'dashboard/helper/URLHelper';
import { CMD_AI_ASSIST } from 'dashboard/helper/commandbar/events';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';
import wootConstants from 'dashboard/constants/globals';
import {
  OPEN_CONVERSATION_ACTIONS,
  SNOOZE_CONVERSATION_ACTIONS,
  RESOLVED_CONVERSATION_ACTIONS,
  SEND_TRANSCRIPT_ACTION,
  UNMUTE_ACTION,
  MUTE_ACTION,
  localizeActions,
} from 'dashboard/helper/commandbar/actions';
import {
  isAConversationRoute,
  isAInboxViewRoute,
} from 'dashboard/helper/routeHelpers';

const SCOPES = ['conversation'];

const PRIORITIES = [
  {
    key: null,
    title: 'CONVERSATION.PRIORITY.OPTIONS.NONE',
    icon: 'i-lucide-circle-dashed',
  },
  {
    key: 'urgent',
    title: 'CONVERSATION.PRIORITY.OPTIONS.URGENT',
    icon: 'i-woot-priority-urgent',
  },
  {
    key: 'high',
    title: 'CONVERSATION.PRIORITY.OPTIONS.HIGH',
    icon: 'i-woot-priority-high',
  },
  {
    key: 'medium',
    title: 'CONVERSATION.PRIORITY.OPTIONS.MEDIUM',
    icon: 'i-woot-priority-medium',
  },
  {
    key: 'low',
    title: 'CONVERSATION.PRIORITY.OPTIONS.LOW',
    icon: 'i-woot-priority-low',
  },
];

const AI_REPLY_OPTIONS = [
  {
    key: 'reply_suggestion',
    title: 'INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.REPLY_SUGGESTION',
    icon: 'i-lucide-sparkles',
  },
];

const AI_SUMMARY_OPTIONS = [
  {
    key: 'summarize',
    title: 'INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.SUMMARIZE',
    icon: 'i-lucide-text',
  },
];

const AI_DRAFT_OPTIONS = [
  {
    key: 'confident',
    title: 'INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.CONFIDENT',
    icon: 'i-lucide-sparkles',
  },
  {
    key: 'fix_spelling_grammar',
    title: 'INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.FIX_SPELLING_GRAMMAR',
    icon: 'i-lucide-spell-check',
  },
  {
    key: 'professional',
    title: 'INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.PROFESSIONAL',
    icon: 'i-lucide-maximize-2',
  },
  {
    key: 'casual',
    title: 'INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.CASUAL',
    icon: 'i-lucide-minimize-2',
  },
  {
    key: 'friendly',
    title: 'INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.MAKE_FRIENDLY',
    icon: 'i-lucide-sparkles',
  },
  {
    key: 'straightforward',
    title: 'INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.STRAIGHTFORWARD',
    icon: 'i-lucide-sparkles',
  },
];

export function useConversationCommands() {
  const { t } = useI18n();
  const store = useStore();
  const route = useRoute();
  const router = useRouter();

  const {
    activeLabels,
    inactiveLabels,
    addLabelToConversation,
    removeLabelFromConversation,
  } = useConversationLabels();
  const { captainTasksEnabled } = useCaptain();
  const { agentsList } = useAgentsList();

  const currentChat = useMapGetter('getSelectedChat');
  const currentAccountId = useMapGetter('getCurrentAccountId');
  const replyMode = useMapGetter('draftMessages/getReplyEditorMode');
  const contextMenuChatId = useMapGetter('getContextMenuChatId');
  const teams = useMapGetter('teams/getTeams');
  const getDraftMessage = useMapGetter('draftMessages/get');

  const conversationId = computed(() => currentChat.value?.id);
  const draftMessage = computed(() =>
    getDraftMessage.value(`draft-${conversationId.value}-${replyMode.value}`)
  );

  const section = key => t(`COMMAND_BAR.SECTIONS.${key}`);

  const page = (id, titleKey, icon, children) => [
    {
      id,
      title: t(`COMMAND_BAR.COMMANDS.${titleKey}`),
      section: section('CONVERSATION'),
      icon,
      page: true,
    },
    ...children.map(child => ({ ...child, parent: id })),
  ];

  const statusCommands = computed(() => {
    const { status } = currentChat.value ?? {};
    if (status === wootConstants.STATUS_TYPE.OPEN) {
      return [...OPEN_CONVERSATION_ACTIONS, ...SNOOZE_CONVERSATION_ACTIONS];
    }
    if (
      status === wootConstants.STATUS_TYPE.RESOLVED ||
      status === wootConstants.STATUS_TYPE.SNOOZED
    ) {
      return RESOLVED_CONVERSATION_ACTIONS;
    }
    return [];
  });

  const assignAgentCommands = computed(() =>
    page(
      'assign_an_agent',
      'ASSIGN_AN_AGENT',
      'i-lucide-user-round-plus',
      agentsList.value.map(agent => ({
        id: `agent-${agent.id}`,
        title: agent.name,
        section: section('CHANGE_ASSIGNEE'),
        prefix: '@',
        ...(agent.id
          ? {
              avatar: {
                name: agent.name,
                src: agent.thumbnail,
                status: agent.availability_status,
              },
            }
          : { icon: 'i-lucide-circle-slash' }),
        run: () =>
          store.dispatch('assignAgent', {
            conversationId: conversationId.value,
            agentId: agent.id,
          }),
      }))
    )
  );

  const assignTeamCommands = computed(() => {
    const options = currentChat.value?.meta?.team
      ? [{ id: 0, name: t('TEAMS_SETTINGS.LIST.NONE') }, ...teams.value]
      : teams.value;
    return page(
      'assign_a_team',
      'ASSIGN_A_TEAM',
      'i-lucide-users',
      options.map(team => ({
        id: `team-${team.id}`,
        title: team.name,
        section: section('CHANGE_TEAM'),
        icon: team.id ? 'i-lucide-users' : 'i-lucide-circle-slash',
        run: () =>
          store.dispatch('assignTeam', {
            conversationId: conversationId.value,
            teamId: team.id,
          }),
      }))
    );
  });

  const assignPriorityCommands = computed(() =>
    page(
      'assign_priority',
      'ASSIGN_PRIORITY',
      'i-lucide-signal-high',
      PRIORITIES.filter(
        priority => priority.key !== currentChat.value?.priority
      ).map(priority => ({
        id: `priority-${priority.key}`,
        title: t(priority.title),
        section: section('CHANGE_PRIORITY'),
        icon: priority.icon,
        run: () =>
          store.dispatch('assignPriority', {
            conversationId: conversationId.value,
            priority: priority.key,
          }),
      }))
    )
  );

  const labelOption = (label, sectionKey, run) => ({
    id: `${sectionKey.toLowerCase().replace('_', '-')}-${label.title}`,
    title: label.title,
    section: section(sectionKey),
    icon: 'i-lucide-tag',
    prefix: '#',
    run,
  });

  const labelCommands = computed(() => [
    ...page(
      'add_a_label_to_the_conversation',
      'ADD_LABELS_TO_CONVERSATION',
      'i-lucide-tag',
      inactiveLabels.value.map(label =>
        labelOption(label, 'ADD_LABEL', () =>
          addLabelToConversation({ title: label.title })
        )
      )
    ),
    ...(activeLabels.value.length
      ? page(
          'remove_a_label_to_the_conversation',
          'REMOVE_LABEL_FROM_CONVERSATION',
          'i-lucide-bookmark-x',
          activeLabels.value.map(label =>
            labelOption(label, 'REMOVE_LABEL', () =>
              removeLabelFromConversation(label.title)
            )
          )
        )
      : []),
  ]);

  const aiAssistCommands = computed(() => {
    let options = AI_DRAFT_OPTIONS;
    if (!draftMessage.value) {
      options =
        replyMode.value === REPLY_EDITOR_MODES.REPLY
          ? AI_REPLY_OPTIONS
          : AI_SUMMARY_OPTIONS;
    }
    return page(
      'ai_assist',
      'AI_ASSIST',
      'i-lucide-sparkles',
      options.map(option => ({
        id: `ai-assist-${option.key}`,
        title: t(option.title),
        section: section('AI_ASSIST'),
        icon: option.icon,
        run: () => emitter.emit(CMD_AI_ASSIST, option.key),
      }))
    );
  });

  const copyConversationLink = async () => {
    const path = conversationUrl({
      accountId: currentAccountId.value,
      id: conversationId.value,
    });
    await copyTextToClipboard(`${window.location.origin}${frontendURL(path)}`);
    useAlert(t('COMMAND_BAR.LINK_COPIED'));
  };

  const contactCommands = computed(() => [
    {
      id: 'view_contact',
      title: t('COMMAND_BAR.COMMANDS.VIEW_CONTACT'),
      section: section('CONVERSATION'),
      icon: 'i-lucide-contact-round',
      run: () =>
        router.push(
          frontendURL(
            `accounts/${currentAccountId.value}/contacts/${currentChat.value.meta.sender.id}`
          )
        ),
    },
    {
      id: 'copy_conversation_link',
      title: t('COMMAND_BAR.COMMANDS.COPY_CONVERSATION_LINK'),
      section: section('CONVERSATION'),
      icon: 'i-lucide-link',
      run: copyConversationLink,
    },
  ]);

  const defaultCommands = computed(() => [
    ...localizeActions(
      [
        ...statusCommands.value,
        currentChat.value?.muted ? UNMUTE_ACTION : MUTE_ACTION,
        SEND_TRANSCRIPT_ACTION,
      ],
      t
    ),
    ...assignAgentCommands.value,
    ...assignTeamCommands.value,
    ...labelCommands.value,
    ...assignPriorityCommands.value,
    ...contactCommands.value,
    ...(captainTasksEnabled.value ? aiAssistCommands.value : []),
  ]);

  const conversationCommands = computed(() => {
    let commands = [];
    if (
      isAConversationRoute(route.name, true, false) &&
      contextMenuChatId.value
    ) {
      commands = localizeActions(SNOOZE_CONVERSATION_ACTIONS, t);
    } else if (
      isAConversationRoute(route.name) ||
      isAInboxViewRoute(route.name)
    ) {
      commands = defaultCommands.value;
    }
    return commands.map(command => ({ ...command, scopes: SCOPES }));
  });

  return { conversationCommands };
}
