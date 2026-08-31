import { nextTick, ref } from 'vue';
import { flushPromises, shallowMount } from '@vue/test-utils';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import AssistantSystemSettingsForm from 'dashboard/components-next/captain/pageComponents/assistant/settings/AssistantSystemSettingsForm.vue';
import { useAssistantSettings } from './useAssistantSettings';
import System from './System.vue';

vi.mock('vue-i18n');
vi.mock('dashboard/composables');
vi.mock('dashboard/composables/useAccount');
vi.mock('./useAssistantSettings');

const deferredPromise = () => {
  let resolve;
  const promise = new Promise(resolvePromise => {
    resolve = resolvePromise;
  });
  return { promise, resolve };
};

const assistants = {
  1: { id: 1, pending_follow_up_automations: [] },
  2: {
    id: 2,
    pending_follow_up_automations: [{ id: 9, execution_delay: 60 }],
  },
};

const mountSystem = async () => {
  const wrapper = shallowMount(System, {
    global: {
      stubs: {
        SettingsPageLayout: { template: '<div><slot /></div>' },
      },
    },
  });
  await flushPromises();
  return wrapper;
};

const displayedAssistant = wrapper =>
  wrapper.findComponent(AssistantSystemSettingsForm).props('assistant');

describe('System', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    useI18n.mockReturnValue({ t: key => key });
    useAccount.mockReturnValue({ isCloudFeatureEnabled: vi.fn(() => false) });
  });

  it('shows settings for the newly selected assistant', async () => {
    const assistantId = ref(1);
    const assistant = ref();
    const fetchAssistant = vi.fn(() => {
      assistant.value = assistants[assistantId.value];
      return assistant.value;
    });

    useAssistantSettings.mockReturnValue({
      assistantId,
      assistant,
      fetchAssistant,
      updateAssistant: vi.fn(),
    });

    const wrapper = await mountSystem();
    expect(displayedAssistant(wrapper)).toEqual(assistants[1]);

    assistantId.value = 2;
    await flushPromises();

    expect(displayedAssistant(wrapper)).toEqual(assistants[2]);
  });

  it('keeps the selected assistant when an earlier request finishes last', async () => {
    const assistantId = ref(1);
    const requests = {
      1: deferredPromise(),
      2: deferredPromise(),
    };

    useAssistantSettings.mockReturnValue({
      assistantId,
      assistant: ref(),
      fetchAssistant: vi.fn(() => requests[assistantId.value].promise),
      updateAssistant: vi.fn(),
    });

    const wrapper = await mountSystem();

    assistantId.value = 2;
    await flushPromises();
    requests[2].resolve(assistants[2]);
    await flushPromises();
    requests[1].resolve(assistants[1]);
    await flushPromises();

    expect(displayedAssistant(wrapper)).toEqual(assistants[2]);
  });

  it('keeps cached settings when the refresh fails', async () => {
    const assistantId = ref(1);
    const assistant = ref();
    useAssistantSettings.mockReturnValue({
      assistantId,
      assistant,
      fetchAssistant: vi.fn(() => Promise.reject(new Error('Network error'))),
      updateAssistant: vi.fn(),
    });

    const wrapper = await mountSystem();
    expect(wrapper.findComponent(AssistantSystemSettingsForm).exists()).toBe(
      false
    );

    assistant.value = assistants[1];
    await nextTick();

    expect(displayedAssistant(wrapper)).toEqual(assistants[1]);
    expect(useAlert).toHaveBeenCalledWith(
      'CAPTAIN.ASSISTANTS.SETTINGS.SYSTEM_SETTINGS.LOAD_ERROR'
    );
  });

  it('ignores a saved response after switching assistants', async () => {
    const assistantId = ref(1);
    const pendingUpdate = deferredPromise();

    useAssistantSettings.mockReturnValue({
      assistantId,
      assistant: ref(),
      fetchAssistant: vi.fn(() =>
        Promise.resolve(assistants[assistantId.value])
      ),
      updateAssistant: vi.fn(() => pendingUpdate.promise),
    });

    const wrapper = await mountSystem();

    wrapper
      .findComponent(AssistantSystemSettingsForm)
      .vm.$emit('submit', { config: {} });
    assistantId.value = 2;
    await flushPromises();
    pendingUpdate.resolve(assistants[1]);
    await flushPromises();

    expect(displayedAssistant(wrapper)).toEqual(assistants[2]);
  });
});
