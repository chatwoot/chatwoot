import { flushPromises } from '@vue/test-utils';
import { useAlert, useTrack } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useConversationRequiredAttributes } from 'dashboard/composables/useConversationRequiredAttributes';
import { useMacroExecution } from '../useMacroExecution';

vi.mock('dashboard/composables/store');
vi.mock('dashboard/composables');
vi.mock('dashboard/composables/useConversationRequiredAttributes');
vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

const CONVERSATION_ID = 42;

const addLabel = { action_name: 'add_label', action_params: ['spam'] };
const resolveConversation = {
  action_name: 'resolve_conversation',
  action_params: [],
};

const macroWith = actions => ({ id: 7, name: 'Test macro', actions });

const dispatch = vi.fn();
const checkMissingAttributes = vi.fn();

const mockConversation = (customAttributes = {}) => {
  useMapGetter.mockImplementation(getter =>
    getter === 'getConversationById'
      ? { value: () => ({ custom_attributes: customAttributes }) }
      : { value: null }
  );
};

describe('useMacroExecution', () => {
  beforeEach(() => {
    dispatch.mockReset().mockResolvedValue(undefined);
    checkMissingAttributes.mockReset().mockReturnValue({
      hasMissing: false,
      missing: [],
    });
    useAlert.mockClear();
    useTrack.mockClear();

    useStore.mockReturnValue({ dispatch });
    useConversationRequiredAttributes.mockReturnValue({
      checkMissingAttributes,
    });
    mockConversation();
  });

  it('runs a macro that cannot resolve the conversation straight away', async () => {
    const { execute } = useMacroExecution();

    const pending = execute(macroWith([addLabel]), CONVERSATION_ID);
    await flushPromises();

    expect(pending).toBeNull();
    expect(checkMissingAttributes).not.toHaveBeenCalled();
    expect(dispatch).toHaveBeenCalledWith('macros/execute', {
      macroId: 7,
      conversationIds: [CONVERSATION_ID],
    });
    expect(useAlert).toHaveBeenCalledWith(
      'MACROS.EXECUTE.EXECUTED_SUCCESSFULLY'
    );
  });

  it('runs a resolving macro when no required attributes are missing', async () => {
    const { execute } = useMacroExecution();

    const pending = execute(macroWith([resolveConversation]), CONVERSATION_ID);
    await flushPromises();

    expect(pending).toBeNull();
    expect(checkMissingAttributes).toHaveBeenCalled();
    expect(dispatch).toHaveBeenCalledWith('macros/execute', expect.anything());
  });

  it('holds back a resolving macro and reports the missing attributes', async () => {
    checkMissingAttributes.mockReturnValue({
      hasMissing: true,
      missing: ['priority'],
    });
    mockConversation({ category: 'sales' });

    const { execute } = useMacroExecution();

    const pending = execute(macroWith([resolveConversation]), CONVERSATION_ID);
    await flushPromises();

    expect(pending).toEqual({
      missing: ['priority'],
      customAttributes: { category: 'sales' },
    });
    expect(dispatch).not.toHaveBeenCalled();
  });

  it.each([['resolved'], [1]])(
    'treats change_status %s as resolving the conversation',
    async status => {
      checkMissingAttributes.mockReturnValue({
        hasMissing: true,
        missing: ['priority'],
      });

      const { execute } = useMacroExecution();
      const macro = macroWith([
        { action_name: 'change_status', action_params: [status] },
      ]);

      expect(execute(macro, CONVERSATION_ID)).not.toBeNull();
      await flushPromises();
      expect(dispatch).not.toHaveBeenCalled();
    }
  );

  it('does not treat change_status open as resolving the conversation', async () => {
    checkMissingAttributes.mockReturnValue({
      hasMissing: true,
      missing: ['priority'],
    });

    const { execute } = useMacroExecution();
    const macro = macroWith([
      { action_name: 'change_status', action_params: ['open'] },
    ]);

    expect(execute(macro, CONVERSATION_ID)).toBeNull();
    await flushPromises();
    expect(dispatch).toHaveBeenCalledWith('macros/execute', expect.anything());
  });

  it('saves the submitted attributes before running the pending macro', async () => {
    checkMissingAttributes.mockReturnValue({
      hasMissing: true,
      missing: ['priority'],
    });
    mockConversation({ category: 'sales' });

    const { execute, submitPendingAttributes } = useMacroExecution();
    execute(macroWith([resolveConversation]), CONVERSATION_ID);
    await submitPendingAttributes({ attributes: { priority: 'high' } });
    await flushPromises();

    expect(dispatch).toHaveBeenNthCalledWith(1, 'updateCustomAttributes', {
      conversationId: CONVERSATION_ID,
      customAttributes: { category: 'sales', priority: 'high' },
    });
    expect(dispatch).toHaveBeenNthCalledWith(2, 'macros/execute', {
      macroId: 7,
      conversationIds: [CONVERSATION_ID],
    });
  });

  it('does not run the macro when saving the attributes fails', async () => {
    checkMissingAttributes.mockReturnValue({
      hasMissing: true,
      missing: ['priority'],
    });
    dispatch.mockRejectedValueOnce(new Error('nope'));

    const { execute, submitPendingAttributes } = useMacroExecution();
    execute(macroWith([resolveConversation]), CONVERSATION_ID);
    await submitPendingAttributes({ attributes: { priority: 'high' } });
    await flushPromises();

    expect(dispatch).toHaveBeenCalledTimes(1);
    expect(useAlert).toHaveBeenCalledWith(
      'CUSTOM_ATTRIBUTES.FORM.UPDATE.ERROR'
    );
  });

  it('still runs the macro when the prompt is dismissed', async () => {
    checkMissingAttributes.mockReturnValue({
      hasMissing: true,
      missing: ['priority'],
    });

    const { execute, dismissPendingAttributes } = useMacroExecution();
    execute(macroWith([resolveConversation]), CONVERSATION_ID);
    dismissPendingAttributes();
    await flushPromises();

    expect(dispatch).toHaveBeenCalledWith('macros/execute', expect.anything());
    expect(useAlert).toHaveBeenCalledWith(
      'MACROS.EXECUTE.EXECUTED_WITHOUT_RESOLVING'
    );
  });

  it('ignores a dismissal when nothing is pending', async () => {
    const { dismissPendingAttributes } = useMacroExecution();

    dismissPendingAttributes();
    await flushPromises();

    expect(dispatch).not.toHaveBeenCalled();
  });

  it('alerts when the macro fails to run', async () => {
    dispatch.mockRejectedValueOnce(new Error('boom'));

    const { execute, executingMacroId } = useMacroExecution();
    execute(macroWith([addLabel]), CONVERSATION_ID);
    await flushPromises();

    expect(useAlert).toHaveBeenCalledWith('MACROS.ERROR');
    expect(executingMacroId.value).toBeNull();
  });
});
