import { useMapGetter, useStore } from 'dashboard/composables/store';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useCannedResponseCommands } from '../useCannedResponseCommands';

vi.mock('vue-i18n');
vi.mock('vue-router');
vi.mock('dashboard/composables/store');
vi.mock('dashboard/composables/usePolicy');
vi.mock('shared/helpers/mitt');

describe('useCannedResponseCommands', () => {
  let store;

  beforeEach(() => {
    store = {
      dispatch: vi.fn(),
      getters: {
        getSelectedChat: {
          id: 1,
          inbox_id: 3,
          meta: { sender: { id: 9, name: 'Sarah' } },
        },
        getCurrentUser: { name: 'Agent Smith' },
        'contacts/getContact': () => ({ id: 9, name: 'Sarah' }),
        'inboxes/getInbox': () => ({ id: 3, name: 'Support' }),
        getCannedResponses: [
          { id: 4, short_code: 'hello', content: 'Hi {{contact.name}}' },
        ],
      },
    };
    useStore.mockReturnValue(store);
    useMapGetter.mockImplementation(key => ({ value: store.getters[key] }));
    useI18n.mockReturnValue({ t: key => key });
    useRoute.mockReturnValue({ name: 'inbox_conversation' });
    usePolicy.mockReturnValue({ isFeatureFlagEnabled: () => true });
  });

  it('lists canned responses under an insert page on a conversation', () => {
    const { cannedResponseCommands } = useCannedResponseCommands();
    const ids = cannedResponseCommands.value.map(command => command.id);

    expect(ids).toEqual(['insert_canned_response', 'canned-4']);
    expect(cannedResponseCommands.value[1]).toEqual(
      expect.objectContaining({
        title: '/hello',
        prefix: '/',
        parent: 'insert_canned_response',
      })
    );
  });

  it('previews and searches the response with its variables resolved', () => {
    store.getters.getCannedResponses = [
      {
        id: 4,
        short_code: 'hello',
        content: '**Hi** {{contact.name}}, how can I help?',
      },
    ];
    const { cannedResponseCommands } = useCannedResponseCommands();

    expect(cannedResponseCommands.value[1].subtitle).toBe(
      'Hi Sarah, how can I help?'
    );
  });

  it('inserts the response with its variables resolved', () => {
    const { cannedResponseCommands } = useCannedResponseCommands();
    cannedResponseCommands.value[1].run();

    expect(emitter.emit).toHaveBeenCalledWith(
      BUS_EVENTS.INSERT_INTO_RICH_EDITOR,
      'Hi Sarah'
    );
  });

  it('is empty away from a conversation', () => {
    useRoute.mockReturnValue({ name: 'contacts_dashboard_index' });
    const { cannedResponseCommands } = useCannedResponseCommands();

    expect(cannedResponseCommands.value).toEqual([]);
  });

  it('loads the responses once when a conversation is opened', () => {
    store.getters.getCannedResponses = [];
    useCannedResponseCommands();

    expect(store.dispatch).toHaveBeenCalledWith('getCannedResponse');
  });
});
