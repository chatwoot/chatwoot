import { computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { emitter } from 'shared/helpers/mitt';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import {
  getReplyVariables,
  resolveVariablesInMessage,
} from 'dashboard/helper/editorHelper';
import {
  isAConversationRoute,
  isAInboxViewRoute,
} from 'dashboard/helper/routeHelpers';

const ICON = 'i-lucide-message-square-quote';
const SCOPES = ['conversation'];

export function useCannedResponseCommands() {
  const { t } = useI18n();
  const store = useStore();
  const route = useRoute();
  const { isFeatureFlagEnabled } = usePolicy();
  const { getPlainText } = useMessageFormatter();

  const currentChat = useMapGetter('getSelectedChat');
  const currentUser = useMapGetter('getCurrentUser');
  const getContact = useMapGetter('contacts/getContact');
  const getInbox = useMapGetter('inboxes/getInbox');
  const cannedResponses = useMapGetter('getCannedResponses');

  const isAvailable = computed(
    () =>
      isFeatureFlagEnabled(FEATURE_FLAGS.CANNED_RESPONSES) &&
      (isAConversationRoute(route.name) || isAInboxViewRoute(route.name))
  );

  watch(
    isAvailable,
    active => {
      if (active && !cannedResponses.value.length) {
        store.dispatch('getCannedResponse');
      }
    },
    { immediate: true }
  );

  const variables = computed(() => {
    const chat = currentChat.value;
    if (!chat) return {};
    return getReplyVariables({
      conversation: chat,
      contact: getContact.value(chat.meta.sender.id),
      inbox: getInbox.value(chat.inbox_id),
      user: currentUser.value,
    });
  });

  const cannedResponseCommands = computed(() => {
    if (!isAvailable.value || !cannedResponses.value.length) return [];

    const section = t('COMMAND_BAR.SECTIONS.CANNED_RESPONSES');
    return [
      {
        id: 'insert_canned_response',
        title: t('COMMAND_BAR.COMMANDS.INSERT_CANNED_RESPONSE'),
        section,
        icon: ICON,
        scopes: SCOPES,
        page: true,
      },
      ...cannedResponses.value.map(response => {
        const content = resolveVariablesInMessage(
          response.content,
          variables.value
        );
        return {
          id: `canned-${response.id}`,
          title: `/${response.short_code}`,
          subtitle: getPlainText(content).replace(/\s+/g, ' ').trim(),
          parent: 'insert_canned_response',
          section,
          icon: ICON,
          prefix: '/',
          scopes: SCOPES,
          run: () => emitter.emit(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, content),
        };
      }),
    ];
  });

  return { cannedResponseCommands };
}
