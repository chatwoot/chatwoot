import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useLocale } from 'shared/composables/useLocale';
import { useMapGetter } from 'dashboard/composables/store';
import { emitter } from 'shared/helpers/mitt';
import { useTrack } from 'dashboard/composables';
import wootConstants from 'dashboard/constants/globals';
import { generateSnoozeSuggestions } from 'dashboard/helper/snoozeHelpers';
import { SNOOZE_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { ICON_SNOOZE } from 'dashboard/helper/commandbar/actions';
import {
  CMD_BULK_ACTION_SNOOZE_CONVERSATION,
  CMD_SNOOZE_CONVERSATION,
  CMD_SNOOZE_NOTIFICATION,
} from 'dashboard/helper/commandbar/events';

const SNOOZE_PAGES = {
  snooze_conversation: {
    event: CMD_SNOOZE_CONVERSATION,
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_CONVERSATION',
  },
  snooze_notification: {
    event: CMD_SNOOZE_NOTIFICATION,
    section: 'COMMAND_BAR.SECTIONS.SNOOZE_NOTIFICATION',
  },
  bulk_action_snooze_conversation: {
    event: CMD_BULK_ACTION_SNOOZE_CONVERSATION,
    section: 'COMMAND_BAR.SECTIONS.BULK_ACTIONS',
  },
};

const ROOT_PAGE = 'snooze_conversation';

export function useSnoozeSuggestions() {
  const { t, tm } = useI18n();
  const { resolvedLocale } = useLocale();
  const currentChat = useMapGetter('getSelectedChat');

  const translations = computed(() => {
    const raw = tm('SNOOZE_PARSER');
    return raw && typeof raw === 'object'
      ? JSON.parse(JSON.stringify(raw))
      : {};
  });

  const suggestionsFor = (page, text) => {
    const target = SNOOZE_PAGES[page];
    const suggestions = generateSnoozeSuggestions(text, new Date(), {
      translations: translations.value,
      locale: resolvedLocale.value,
    });

    return suggestions.map((parsed, index) => ({
      id: `snooze-suggestion-${index}`,
      title: parsed.label,
      subtitle:
        parsed.label === parsed.formattedDate
          ? undefined
          : parsed.formattedDate,
      parent: page,
      section: t(target.section),
      icon: ICON_SNOOZE,
      run: () => {
        emitter.emit(target.event, parsed.resolve());
        useTrack(SNOOZE_EVENTS.NLP_SNOOZE_APPLIED, { label: parsed.label });
      },
    }));
  };

  const searchSnoozeSuggestions = ({ page, text }) =>
    SNOOZE_PAGES[page] && text ? suggestionsFor(page, text) : [];

  const snoozeCommands = ({ page, text, context }) => {
    if (page || !text || !context.scopes?.includes('conversation')) return [];
    if (currentChat.value?.status !== wootConstants.STATUS_TYPE.OPEN) return [];

    return suggestionsFor(ROOT_PAGE, text).map(item => ({
      ...item,
      keywords: [text],
      scopes: ['conversation'],
    }));
  };

  return { searchSnoozeSuggestions, snoozeCommands };
}
