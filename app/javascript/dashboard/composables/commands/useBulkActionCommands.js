import { computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useBulkActions } from 'dashboard/composables/chatlist/useBulkActions';
import { useOrderedMacros } from 'dashboard/composables/useOrderedMacros';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { emitter } from 'shared/helpers/mitt';

import {
  CMD_BULK_ACTION_REOPEN_CONVERSATION,
  CMD_BULK_ACTION_RESOLVE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';
import {
  ICON_SNOOZE,
  commandPage,
  createSnoozeOptions,
  localizeActions,
} from 'dashboard/helper/commandbar/actions';
import { isAConversationRoute } from 'dashboard/helper/routeHelpers';

const SECTION = 'COMMAND_BAR.SECTIONS.BULK_ACTIONS';
const SCOPES = ['bulk'];
const ICON_TEAM = 'i-lucide-users';
const ICON_LABEL = 'i-lucide-tag';
const ICON_MACRO = 'i-lucide-toy-brick';
const ICON_NONE = 'i-lucide-circle-slash';

// Status changes go through the bulk toolbar, which owns the custom snooze modal.
const BULK_ACTIONS = [
  {
    id: 'bulk_action_snooze_conversation',
    title: 'COMMAND_BAR.COMMANDS.SNOOZE_CONVERSATION',
    section: SECTION,
    icon: ICON_SNOOZE,
    page: true,
    placeholder: 'COMMAND_BAR.SNOOZE_PLACEHOLDER',
  },
  ...createSnoozeOptions('bulk_action_snooze_conversation'),
  {
    id: 'bulk_action_reopen_conversation',
    title: 'COMMAND_BAR.COMMANDS.REOPEN_CONVERSATION',
    section: SECTION,
    icon: 'i-lucide-rotate-ccw',
    run: () => emitter.emit(CMD_BULK_ACTION_REOPEN_CONVERSATION),
  },
  {
    id: 'bulk_action_resolve_conversation',
    title: 'COMMAND_BAR.COMMANDS.RESOLVE_CONVERSATION',
    section: SECTION,
    icon: 'i-lucide-circle-check',
    run: () => emitter.emit(CMD_BULK_ACTION_RESOLVE_CONVERSATION),
  },
];

export function useBulkActionCommands() {
  const { t } = useI18n();
  const route = useRoute();
  const store = useStore();
  const { isFeatureFlagEnabled } = usePolicy();
  const { orderedMacros } = useOrderedMacros();
  const {
    onAssignAgent,
    onAssignTeamsForBulk,
    onAssignLabels,
    onRemoveLabels,
    onUpdateConversations,
    onExecuteMacro,
  } = useBulkActions();

  const selectedConversations = useMapGetter(
    'bulkActions/getSelectedConversationIds'
  );
  const getConversationById = useMapGetter('getConversationById');
  const getAssignableAgents = useMapGetter(
    'inboxAssignableAgents/getAssignableAgents'
  );
  const teams = useMapGetter('teams/getTeams');
  const labels = useMapGetter('labels/getLabels');
  const isMacrosEnabled = () => isFeatureFlagEnabled(FEATURE_FLAGS.MACROS);

  const selected = computed(() =>
    selectedConversations.value
      .map(id => getConversationById.value(id))
      .filter(Boolean)
  );
  const inboxIds = computed(() => [
    ...new Set(selected.value.map(conversation => conversation.inbox_id)),
  ]);
  const appliedLabels = computed(() => [
    ...new Set(selected.value.flatMap(conversation => conversation.labels)),
  ]);

  watch(
    () => inboxIds.value.join(','),
    ids => {
      if (ids) store.dispatch('inboxAssignableAgents/fetch', inboxIds.value);
    },
    { immediate: true }
  );
  // A selection can start on a list page, where nothing else has loaded macros.
  watch(
    () => selectedConversations.value.length,
    count => {
      if (count && isMacrosEnabled() && !orderedMacros.value.length) {
        store.dispatch('macros/get');
      }
    },
    { immediate: true }
  );

  const section = () => t(SECTION);
  const page = (id, titleKey, icon, children) =>
    commandPage({ id, title: t(titleKey), section: section(), icon, children });

  const agentCommands = computed(() =>
    page(
      'bulk_assign_agent',
      'COMMAND_BAR.COMMANDS.ASSIGN_AN_AGENT',
      'i-lucide-user-round-plus',
      [
        { id: null, name: t('BULK_ACTION.NONE') },
        ...getAssignableAgents.value(inboxIds.value.join(',')),
      ].map(agent => ({
        id: `bulk-agent-${agent.id ?? 'none'}`,
        title: agent.name,
        section: section(),
        ...(agent.id
          ? {
              avatar: {
                name: agent.name,
                src: agent.thumbnail,
                status: agent.availability_status,
              },
            }
          : { icon: ICON_NONE }),
        run: () => onAssignAgent(agent),
      }))
    )
  );

  const teamCommands = computed(() =>
    page(
      'bulk_assign_team',
      'COMMAND_BAR.COMMANDS.ASSIGN_A_TEAM',
      ICON_TEAM,
      [{ id: 0, name: t('BULK_ACTION.TEAMS.NONE') }, ...teams.value].map(
        team => ({
          id: `bulk-team-${team.id}`,
          title: team.name,
          section: section(),
          icon: team.id ? ICON_TEAM : ICON_NONE,
          run: () => onAssignTeamsForBulk(team),
        })
      )
    )
  );

  const labelCommands = computed(() => [
    ...page(
      'bulk_add_labels',
      'BULK_ACTION.LABELS.ASSIGN_LABELS',
      ICON_LABEL,
      labels.value.map(label => ({
        id: `bulk-add-label-${label.title}`,
        title: label.title,
        section: section(),
        icon: ICON_LABEL,
        run: () => onAssignLabels([label.title]),
      }))
    ),
    ...(appliedLabels.value.length
      ? page(
          'bulk_remove_labels',
          'BULK_ACTION.LABELS.REMOVE_LABELS',
          'i-lucide-bookmark-x',
          appliedLabels.value.map(title => ({
            id: `bulk-remove-label-${title}`,
            title,
            section: section(),
            icon: ICON_LABEL,
            run: () => onRemoveLabels([title]),
          }))
        )
      : []),
  ]);

  const macroCommands = computed(() =>
    isMacrosEnabled() && orderedMacros.value.length
      ? page(
          'bulk_execute_macro',
          'COMMAND_BAR.COMMANDS.EXECUTE_A_MACRO',
          ICON_MACRO,
          orderedMacros.value.map(macro => ({
            id: `bulk-macro-${macro.id}`,
            title: macro.name,
            section: section(),
            icon: ICON_MACRO,
            run: () => onExecuteMacro(macro),
          }))
        )
      : []
  );

  const bulkActionCommands = computed(() => {
    // The selection outlives the list when the user navigates away from it.
    if (!selectedConversations.value.length) return [];
    if (!isAConversationRoute(route.name, true)) return [];

    return [
      ...localizeActions(BULK_ACTIONS, t),
      {
        id: 'bulk_action_pending_conversation',
        title: t('CONVERSATION.CARD_CONTEXT_MENU.PENDING'),
        section: section(),
        icon: 'i-lucide-clock',
        run: () => onUpdateConversations('pending', null),
      },
      ...agentCommands.value,
      ...teamCommands.value,
      ...labelCommands.value,
      ...macroCommands.value,
    ].map(command => ({ ...command, scopes: SCOPES }));
  });

  return { bulkActionCommands };
}
