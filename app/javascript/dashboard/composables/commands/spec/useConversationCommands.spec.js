import { useConversationCommands } from '../useConversationCommands';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useConversationLabels } from 'dashboard/composables/useConversationLabels';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useAgentsList } from 'dashboard/composables/useAgentsList';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';
import {
  mockAssignableAgents,
  mockCurrentChat,
  mockTeamsList,
  mockActiveLabels,
  mockInactiveLabels,
} from './fixtures';

vi.mock('dashboard/composables/store');
vi.mock('vue-i18n');
vi.mock('vue-router');
vi.mock('dashboard/composables/useConversationLabels');
vi.mock('dashboard/composables/useCaptain');
vi.mock('dashboard/composables/useAgentsList');

describe('useConversationCommands', () => {
  let store;

  beforeEach(() => {
    store = {
      dispatch: vi.fn(),
      getters: {
        getSelectedChat: mockCurrentChat,
        'draftMessages/getReplyEditorMode': REPLY_EDITOR_MODES.REPLY,
        getContextMenuChatId: null,
        getCurrentAccountId: 1,
        'teams/getTeams': mockTeamsList,
        'draftMessages/get': vi.fn(),
      },
    };

    useStore.mockReturnValue(store);
    useMapGetter.mockImplementation(key => ({
      value: store.getters[key],
    }));

    useI18n.mockReturnValue({ t: vi.fn(key => key) });
    useRoute.mockReturnValue({ name: 'inbox_conversation' });
    useRouter.mockReturnValue({ push: vi.fn() });
    useConversationLabels.mockReturnValue({
      activeLabels: { value: mockActiveLabels },
      inactiveLabels: { value: mockInactiveLabels },
      addLabelToConversation: vi.fn(),
      removeLabelFromConversation: vi.fn(),
    });
    useCaptain.mockReturnValue({ captainTasksEnabled: { value: true } });
    useAgentsList.mockReturnValue({
      agentsList: { value: mockAssignableAgents },
    });
  });

  it('should return the correct computed properties', () => {
    const { conversationCommands } = useConversationCommands();

    expect(conversationCommands.value).toBeDefined();
  });

  it('should generate conversation hot keys', () => {
    const { conversationCommands } = useConversationCommands();
    expect(conversationCommands.value.length).toBeGreaterThan(0);
  });

  it('should include AI assist actions when captain tasks is enabled', () => {
    const { conversationCommands } = useConversationCommands();
    const aiAssistAction = conversationCommands.value.find(
      action => action.id === 'ai_assist'
    );
    expect(aiAssistAction).toBeDefined();
  });

  it('should not include AI assist actions when captain tasks is disabled', () => {
    useCaptain.mockReturnValue({ captainTasksEnabled: { value: false } });
    const { conversationCommands } = useConversationCommands();
    const aiAssistAction = conversationCommands.value.find(
      action => action.id === 'ai_assist'
    );
    expect(aiAssistAction).toBeUndefined();
  });

  it('should assign the agent of the picked child', () => {
    const { conversationCommands } = useConversationCommands();
    const agentOption = conversationCommands.value.find(
      action => action.parent === 'assign_an_agent'
    );

    expect(agentOption).toEqual(
      expect.objectContaining({
        prefix: '@',
        avatar: expect.objectContaining({ name: 'John Doe', status: 'online' }),
      })
    );

    agentOption.run();
    expect(store.dispatch).toHaveBeenCalledWith('assignAgent', {
      conversationId: mockCurrentChat.id,
      agentId: mockAssignableAgents[0].id,
    });
  });

  it('should mark every command with the conversation scope', () => {
    const { conversationCommands } = useConversationCommands();
    conversationCommands.value.forEach(action => {
      expect(action.scopes).toEqual(['conversation']);
    });
  });

  it('should show the resolve shortcut', () => {
    const { conversationCommands } = useConversationCommands();
    const resolve = conversationCommands.value.find(
      action => action.id === 'resolve_conversation'
    );
    expect(resolve.shortcut).toHaveLength(2);
  });

  it('should offer to open the contact of the conversation', () => {
    const { conversationCommands } = useConversationCommands();
    const viewContact = conversationCommands.value.find(
      action => action.id === 'view_contact'
    );

    viewContact.run();
    expect(useRouter().push).toHaveBeenCalledWith(
      `/app/accounts/1/contacts/${mockCurrentChat.meta.sender.id}`
    );
  });

  it('should return snooze actions when in snooze context', () => {
    store.getters.getContextMenuChatId = 1;
    useMapGetter.mockImplementation(key => ({
      value: store.getters[key],
    }));
    useRoute.mockReturnValue({ name: 'inbox_conversation' });

    const { conversationCommands } = useConversationCommands();
    const snoozeAction = conversationCommands.value.find(action =>
      action.id.includes('snooze_conversation')
    );
    expect(snoozeAction).toBeDefined();
  });

  it('should return the correct label actions when there are active labels', () => {
    const { conversationCommands } = useConversationCommands();
    const addLabelAction = conversationCommands.value.find(
      action => action.id === 'add_a_label_to_the_conversation'
    );
    const removeLabelAction = conversationCommands.value.find(
      action => action.id === 'remove_a_label_to_the_conversation'
    );
    const labelOption = conversationCommands.value.find(
      action => action.parent === 'add_a_label_to_the_conversation'
    );

    expect(addLabelAction.page).toBe(true);
    expect(removeLabelAction.page).toBe(true);
    expect(labelOption).toEqual(
      expect.objectContaining({ title: 'Feature Request', prefix: '#' })
    );
  });

  it('should return only add label actions when there are no active labels', () => {
    useConversationLabels.mockReturnValue({
      activeLabels: { value: [] },
      inactiveLabels: { value: [{ title: 'inactive_label' }] },
      addLabelToConversation: vi.fn(),
      removeLabelFromConversation: vi.fn(),
    });

    const { conversationCommands } = useConversationCommands();
    const addLabelAction = conversationCommands.value.find(
      action => action.id === 'add_a_label_to_the_conversation'
    );
    const removeLabelAction = conversationCommands.value.find(
      action => action.id === 'remove_a_label_to_the_conversation'
    );

    expect(addLabelAction).toBeDefined();
    expect(removeLabelAction).toBeUndefined();
  });

  it('should return the correct team assignment actions', () => {
    const { conversationCommands } = useConversationCommands();
    const assignTeamAction = conversationCommands.value.find(
      action => action.id === 'assign_a_team'
    );

    expect(assignTeamAction.page).toBe(true);
    const teams = conversationCommands.value.filter(
      action => action.parent === 'assign_a_team'
    );
    expect(teams.length).toBe(mockTeamsList.length);
  });

  it('should return the correct priority assignment actions', () => {
    const { conversationCommands } = useConversationCommands();
    const assignPriorityAction = conversationCommands.value.find(
      action => action.id === 'assign_priority'
    );

    expect(assignPriorityAction.page).toBe(true);
    const priorities = conversationCommands.value.filter(
      action => action.parent === 'assign_priority'
    );
    expect(priorities.length).toBe(4);
  });

  it('should return the correct conversation additional actions', () => {
    const { conversationCommands } = useConversationCommands();
    const muteAction = conversationCommands.value.find(
      action => action.id === 'mute_conversation'
    );
    const sendTranscriptAction = conversationCommands.value.find(
      action => action.id === 'send_transcript'
    );

    expect(muteAction).toBeDefined();
    expect(sendTranscriptAction).toBeDefined();
  });

  it('should return unmute action when conversation is muted', () => {
    store.getters.getSelectedChat = { ...mockCurrentChat, muted: true };
    const { conversationCommands } = useConversationCommands();
    const unmuteAction = conversationCommands.value.find(
      action => action.id === 'unmute_conversation'
    );

    expect(unmuteAction).toBeDefined();
  });

  it('should not return conversation hot keys when not in conversation or inbox route', () => {
    useRoute.mockReturnValue({ name: 'some_other_route' });
    const { conversationCommands } = useConversationCommands();

    expect(conversationCommands.value.length).toBe(0);
  });
});
