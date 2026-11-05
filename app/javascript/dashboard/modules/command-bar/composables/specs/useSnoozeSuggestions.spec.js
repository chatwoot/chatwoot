import { useI18n } from 'vue-i18n';
import { useLocale } from 'shared/composables/useLocale';
import { useMapGetter } from 'dashboard/composables/store';
import { emitter } from 'shared/helpers/mitt';
import { generateSnoozeSuggestions } from 'dashboard/helper/snoozeHelpers';
import { CMD_SNOOZE_CONVERSATION } from 'dashboard/helper/commandbar/events';
import { useSnoozeSuggestions } from '../useSnoozeSuggestions';

vi.mock('vue-i18n');
vi.mock('shared/composables/useLocale');
vi.mock('dashboard/composables/store');
vi.mock('shared/helpers/mitt');
vi.mock('dashboard/helper/snoozeHelpers');
vi.mock('dashboard/composables', () => ({ useTrack: vi.fn() }));

describe('useSnoozeSuggestions', () => {
  let chat;

  beforeEach(() => {
    chat = { value: { id: 7, status: 'open' } };
    useMapGetter.mockReturnValue(chat);
    useI18n.mockReturnValue({ t: key => key, tm: () => ({}) });
    useLocale.mockReturnValue({ resolvedLocale: { value: 'en' } });
    generateSnoozeSuggestions.mockReturnValue([
      {
        label: 'Tomorrow',
        formattedDate: 'Feb 3, 9:00 AM',
        resolve: () => 1700000000,
      },
    ]);
  });

  it('returns nothing outside the snooze pages', () => {
    const { searchSnoozeSuggestions } = useSnoozeSuggestions();
    expect(searchSnoozeSuggestions({ page: null, text: 'tomorrow' })).toEqual(
      []
    );
    expect(
      searchSnoozeSuggestions({ page: 'assign_an_agent', text: 'tom' })
    ).toEqual([]);
  });

  it('returns nothing on a snooze page until something is typed', () => {
    const { searchSnoozeSuggestions } = useSnoozeSuggestions();
    expect(
      searchSnoozeSuggestions({ page: 'snooze_conversation', text: '' })
    ).toEqual([]);
  });

  it('turns the parsed dates into children of the open snooze page', () => {
    const { searchSnoozeSuggestions } = useSnoozeSuggestions();
    const [item] = searchSnoozeSuggestions({
      page: 'snooze_conversation',
      text: 'tomorrow',
    });

    expect(item).toEqual(
      expect.objectContaining({
        parent: 'snooze_conversation',
        title: 'Tomorrow',
        subtitle: 'Feb 3, 9:00 AM',
      })
    );
  });

  it('emits the resolved time on the bus event of the page', () => {
    const { searchSnoozeSuggestions } = useSnoozeSuggestions();
    const [item] = searchSnoozeSuggestions({
      page: 'snooze_conversation',
      text: 'tomorrow',
    });
    item.run();

    expect(emitter.emit).toHaveBeenCalledWith(
      CMD_SNOOZE_CONVERSATION,
      1700000000
    );
  });

  it('suggests snoozing the open conversation straight from the root', () => {
    const { snoozeCommands } = useSnoozeSuggestions();
    const [item] = snoozeCommands({
      page: null,
      text: 'snooze till monday 6pm',
      context: { scopes: ['conversation'] },
    });

    expect(item).toEqual(
      expect.objectContaining({
        parent: 'snooze_conversation',
        title: 'Tomorrow',
        keywords: ['snooze till monday 6pm'],
        scopes: ['conversation'],
      })
    );
    item.run();
    expect(emitter.emit).toHaveBeenCalledWith(
      CMD_SNOOZE_CONVERSATION,
      1700000000
    );
  });

  it('stays quiet at the root away from an open conversation', () => {
    const { snoozeCommands } = useSnoozeSuggestions();
    const request = {
      page: null,
      text: 'tomorrow',
      context: { scopes: ['conversation'] },
    };

    expect(snoozeCommands({ ...request, context: { scopes: [] } })).toEqual([]);
    chat.value = { id: 7, status: 'resolved' };
    expect(snoozeCommands(request)).toEqual([]);
  });
});
