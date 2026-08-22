import { useAssistantSettings } from './useAssistantSettings';
import { useStore, useFunctionGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';

vi.mock('dashboard/composables/store');
vi.mock('dashboard/composables');
vi.mock('vue-router');
vi.mock('vue-i18n');

describe('useAssistantSettings', () => {
  const assistant = { id: 7, name: 'Support bot' };
  const mockStore = { dispatch: vi.fn() };

  beforeEach(() => {
    vi.clearAllMocks();
    useStore.mockReturnValue(mockStore);
    useFunctionGetter.mockReturnValue({ value: assistant });
    useRoute.mockReturnValue({ params: { assistantId: '7' } });
    useI18n.mockReturnValue({ t: key => key });
  });

  it('exposes the numeric assistant id from the route', () => {
    expect(useAssistantSettings().assistantId.value).toBe(7);
  });

  it('reads the assistant from the store getter', () => {
    const { assistant: record, assistantId } = useAssistantSettings();

    expect(useFunctionGetter).toHaveBeenCalledWith(
      'captainAssistants/getRecord',
      assistantId
    );
    expect(record.value).toEqual(assistant);
  });

  it('dispatches the update with the assistant id and alerts success', async () => {
    const { updateAssistant } = useAssistantSettings();

    await updateAssistant({ config: { audience: null } });

    expect(mockStore.dispatch).toHaveBeenCalledWith(
      'captainAssistants/update',
      { id: 7, config: { audience: null } }
    );
    expect(useAlert).toHaveBeenCalledWith(
      'CAPTAIN.ASSISTANTS.EDIT.SUCCESS_MESSAGE'
    );
  });

  it('alerts the error message when the update fails', async () => {
    mockStore.dispatch.mockRejectedValueOnce(new Error('Audience is invalid'));
    const { updateAssistant } = useAssistantSettings();

    await updateAssistant({ name: 'New name' });

    expect(useAlert).toHaveBeenCalledWith('Audience is invalid');
  });

  it('falls back to the generic error message when the error has none', async () => {
    mockStore.dispatch.mockRejectedValueOnce({});
    const { updateAssistant } = useAssistantSettings();

    await updateAssistant({ name: 'New name' });

    expect(useAlert).toHaveBeenCalledWith(
      'CAPTAIN.ASSISTANTS.EDIT.ERROR_MESSAGE'
    );
  });
});
