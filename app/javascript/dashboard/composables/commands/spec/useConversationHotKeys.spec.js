import { useConversationHotKeys } from '../useConversationHotKeys';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useConversationLabels } from 'dashboard/composables/useConversationLabels';
import { useAI } from 'dashboard/composables/useAI';
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
vi.mock('dashboard/composables/useAI');
vi.mock('dashboard/composables/useAgentsList');

describe('useConversationHotKeys', () => {
  let store;

  beforeEach(() => {
    store = {
      dispatch: vi.fn(),
      getters: {
        getSelectedChat: mockCurrentChat,
        'draftMessages/getReplyEditorMode': REPLY_EDITOR_MODES.REPLY,
        getContextMenuChatId: null,
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
    useConversationLabels.mockReturnValue({
      activeLabels: { value: mockActiveLabels },
      inactiveLabels: { value: mockInactiveLabels },
      addLabelToConversation: vi.fn(),
      removeLabelFromConversation: vi.fn(),
    });
    useAI.mockReturnValue({ isAIIntegrationEnabled: { value: true } });
    useAgentsList.mockReturnValue({
      agentsList: { value: [] },
      assignableAgents: { value: mockAssignableAgents },
    });
  });

  it('should return the correct computed properties', () => {
    const { conversationHotKeys } = useConversationHotKeys();

    expect(conversationHotKeys.value).toBeDefined();
  });

  it('should generate conversation hot keys', () => {
    const { conversationHotKeys } = useConversationHotKeys();
    expect(conversationHotKeys.value.length).toBeGreaterThan(0);
  });

  it('should include AI assist actions when AI integration is enabled', () => {
    const { conversationHotKeys } = useConversationHotKeys();
    const aiAssistAction = conversationHotKeys.value.find(
      action => action.id === 'ai_assist'
    );
    expect(aiAssistAction).toBeDefined();
  });

  it('should not include AI assist actions when AI integration is disabled', () => {
    useAI.mockReturnValue({ isAIIntegrationEnabled: { value: false } });
    const { conversationHotKeys } = useConversationHotKeys();
    const aiAssistAction = conversationHotKeys.value.find(
      action => action.id === 'ai_assist'
    );
    expect(aiAssistAction).toBeUndefined();
  });

  it('should dispatch actions when handlers are called', () => {
    const { conversationHotKeys } = useConversationHotKeys();
    const assignAgentAction = conversationHotKeys.value.find(
      action => action.id === 'assign_an_agent'
    );
    expect(assignAgentAction).toBeDefined();

    if (assignAgentAction && assignAgentAction.children) {
      const childAction = conversationHotKeys.value.find(
        action => action.id === assignAgentAction.children[0]
      );
      if (childAction && childAction.handler) {
        childAction.handler({ agentInfo: { id: 2 } });
        expect(store.dispatch).toHaveBeenCalledWith('assignAgent', {
          conversationId: 1,
          agentId: 2,
        });
      }
    }
  });

  it('should return snooze actions when in snooze context', () => {
    store.getters.getContextMenuChatId = 1;
    useMapGetter.mockImplementation(key => ({
      value: store.getters[key],
    }));
    useRoute.mockReturnValue({ name: 'inbox_conversation' });

    const { conversationHotKeys } = useConversationHotKeys();
    const snoozeAction = conversationHotKeys.value.find(action =>
      action.id.includes('snooze_conversation')
    );
    expect(snoozeAction).toBeDefined();
  });

  it('should return the correct label actions when there are active labels', () => {
    const { conversationHotKeys } = useConversationHotKeys();
    const addLabelAction = conversationHotKeys.value.find(
      action => action.id === 'add_a_label_to_the_conversation'
    );
    const removeLabelAction = conversationHotKeys.value.find(
      action => action.id === 'remove_a_label_to_the_conversation'
    );

    expect(addLabelAction).toBeDefined();
    expect(removeLabelAction).toBeDefined();
  });

  it('should return only add label actions when there are no active labels', () => {
    useConversationLabels.mockReturnValue({
      activeLabels: { value: [] },
      inactiveLabels: { value: [{ title: 'inactive_label' }] },
      addLabelToConversation: vi.fn(),
      removeLabelFromConversation: vi.fn(),
    });

    const { conversationHotKeys } = useConversationHotKeys();
    const addLabelAction = conversationHotKeys.value.find(
      action => action.id === 'add_a_label_to_the_conversation'
    );
    const removeLabelAction = conversationHotKeys.value.find(
      action => action.id === 'remove_a_label_to_the_conversation'
    );

    expect(addLabelAction).toBeDefined();
    expect(removeLabelAction).toBeUndefined();
  });

  it('should return the correct team assignment actions', () => {
    const { conversationHotKeys } = useConversationHotKeys();
    const assignTeamAction = conversationHotKeys.value.find(
      action => action.id === 'assign_a_team'
    );

    expect(assignTeamAction).toBeDefined();
    expect(assignTeamAction.children.length).toBe(mockTeamsList.length);
  });

  it('should return the correct priority assignment actions', () => {
    const { conversationHotKeys } = useConversationHotKeys();
    const assignPriorityAction = conversationHotKeys.value.find(
      action => action.id === 'assign_priority'
    );

    expect(assignPriorityAction).toBeDefined();
    expect(assignPriorityAction.children.length).toBe(4);
  });

  it('should return the correct conversation additional actions', () => {
    const { conversationHotKeys } = useConversationHotKeys();
    const muteAction = conversationHotKeys.value.find(
      action => action.id === 'mute_conversation'
    );
    const sendTranscriptAction = conversationHotKeys.value.find(
      action => action.id === 'send_transcript'
    );

    expect(muteAction).toBeDefined();
    expect(sendTranscriptAction).toBeDefined();
  });

  it('should return unmute action when conversation is muted', () => {
    store.getters.getSelectedChat = { ...mockCurrentChat, muted: true };
    const { conversationHotKeys } = useConversationHotKeys();
    const unmuteAction = conversationHotKeys.value.find(
      action => action.id === 'unmute_conversation'
    );

    expect(unmuteAction).toBeDefined();
  });

  it('should not return conversation hot keys when not in conversation or inbox route', () => {
    useRoute.mockReturnValue({ name: 'some_other_route' });
    const { conversationHotKeys } = useConversationHotKeys();

    expect(conversationHotKeys.value.length).toBe(0);
  });
});
