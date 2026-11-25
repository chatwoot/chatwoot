import { useBulkActions } from '../useBulkActions';

const dispatch = vi.fn();

vi.mock('vuex', () => ({
  useStore: () => ({ dispatch }),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/composables/store.js', () => ({
  useMapGetter: () => ({ value: [11, 12] }),
}));

vi.mock('dashboard/composables/useConversationRequiredAttributes', () => ({
  useConversationRequiredAttributes: () => ({
    checkMissingAttributes: () => ({ hasMissing: false }),
  }),
}));

const useAlert = vi.fn();
const useAssignmentError = vi.fn();

vi.mock('dashboard/composables', () => ({
  useAlert: (...args) => useAlert(...args),
  useAssignmentError: (...args) => useAssignmentError(...args),
}));

describe('useBulkActions#onAssignAgent', () => {
  const agent = { id: 7, name: 'Agent' };

  beforeEach(() => {
    dispatch.mockReset();
    dispatch.mockResolvedValue({});
    useAlert.mockReset();
    useAssignmentError.mockReset();
  });

  // The context menu carries a single conversation and needs a synchronous
  // answer: bulk_actions replies `head :ok` before the job runs, so a rejected
  // assignment could never reach the agent.
  it('routes a single conversation through the synchronous endpoint', async () => {
    const { onAssignAgent } = useBulkActions();

    await onAssignAgent(agent, [42]);

    expect(dispatch).toHaveBeenCalledWith('assignAgent', {
      conversationId: 42,
      assignee: agent,
    });
  });

  it('reports a rejected assignment through the conflict handler', async () => {
    const error = { response: { status: 409, data: { agent_name: 'Owner' } } };
    dispatch.mockRejectedValue(error);
    const { onAssignAgent } = useBulkActions();

    await onAssignAgent(agent, [42]);

    expect(useAssignmentError).toHaveBeenCalledWith(
      error,
      'BULK_ACTION.ASSIGN_FAILED'
    );
    expect(useAlert).not.toHaveBeenCalled();
  });

  it('keeps a multi-select selection on the bulk endpoint', async () => {
    const { onAssignAgent } = useBulkActions();

    await onAssignAgent(agent);

    expect(dispatch).toHaveBeenCalledWith('bulkActions/process', {
      type: 'Conversation',
      ids: [11, 12],
      fields: { assignee_id: agent.id },
    });
  });
});
