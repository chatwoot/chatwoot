import { flushPromises, mount } from '@vue/test-utils';
import { reactive } from 'vue';
import Index from './Index.vue';

const state = vi.hoisted(() => ({ config: null, store: null }));

vi.mock('dashboard/composables/store', () => ({
  useStore: () => state.store,
}));
vi.mock('dashboard/store/captain/preferences', () => ({
  useCaptainConfigStore: () => state.config,
}));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('vue-i18n', async importOriginal => ({
  ...(await importOriginal()),
  useI18n: () => ({ t: key => key }),
}));

const mountSettings = async ({ assistantId, tools }) => {
  state.config = reactive({
    copilotAssistantId: assistantId,
    copilotTools: tools,
    fetch: vi.fn().mockResolvedValue(),
    updatePreferences: vi.fn(),
  });
  state.store = {
    getters: { 'captainAssistants/getRecords': [{ id: 1, name: 'Support' }] },
    dispatch: vi.fn().mockResolvedValue(),
  };

  const wrapper = mount(Index, {
    global: {
      stubs: {
        SettingsLayout: {
          template: '<div><slot name="header" /><slot name="body" /></div>',
        },
        SectionLayout: {
          template: '<section><slot name="headerActions" /><slot /></section>',
        },
        BaseSettingsHeader: true,
        Icon: true,
      },
    },
  });
  await flushPromises();
  return wrapper;
};

describe('Copilot settings', () => {
  it('keeps the existing assistant selection as the default', async () => {
    const wrapper = await mountSettings({
      assistantId: null,
      tools: [{ name: 'search_documentation', available: true }],
    });

    expect(wrapper.text()).toContain('COPILOT_SETTINGS.GROUPS.ASSISTANT');
    expect(wrapper.find('#copilot-assistant').element.value).toBe('automatic');
    expect(wrapper.find('[role="switch"]').exists()).toBe(false);
  });

  it('saves each assistant change without a button', async () => {
    const wrapper = await mountSettings({
      assistantId: null,
      tools: [{ name: 'search_documentation', available: true }],
    });

    expect(wrapper.find('button').exists()).toBe(false);

    await wrapper.find('#copilot-assistant').setValue('1');
    await flushPromises();
    expect(state.config.updatePreferences).toHaveBeenCalledWith({
      copilot_assistant_id: 1,
    });

    await wrapper.find('#copilot-assistant').setValue('automatic');
    await flushPromises();
    expect(state.config.updatePreferences).toHaveBeenLastCalledWith({
      copilot_assistant_id: null,
    });
  });

  it('restores the saved assistant if automatic saving fails', async () => {
    const wrapper = await mountSettings({ assistantId: null, tools: [] });
    state.config.updatePreferences.mockRejectedValueOnce(new Error('Failed'));

    await wrapper.find('#copilot-assistant').setValue('1');
    await flushPromises();

    expect(wrapper.find('#copilot-assistant').element.value).toBe('automatic');
  });

  it('shows Linear search only when this account can use it', async () => {
    const wrapper = await mountSettings({ assistantId: null, tools: [] });
    expect(wrapper.text()).not.toContain('COPILOT_SETTINGS.GROUPS.LINEAR');

    state.config.copilotTools = [
      { name: 'search_linear_issues', available: true },
    ];
    await flushPromises();
    expect(wrapper.text()).toContain('COPILOT_SETTINGS.GROUPS.LINEAR');
    expect(wrapper.text()).toContain('COPILOT_SETTINGS.SCOPES.SEARCH');
  });

  it('shows one source with read and search scopes', async () => {
    const wrapper = await mountSettings({
      assistantId: null,
      tools: [
        { name: 'get_conversation', available: true },
        { name: 'search_conversations', available: true },
      ],
    });

    expect(wrapper.text()).toContain('COPILOT_SETTINGS.GROUPS.CONVERSATIONS');
    expect(wrapper.text()).toContain('COPILOT_SETTINGS.SCOPES.READ');
    expect(wrapper.text()).toContain('COPILOT_SETTINGS.SCOPES.SEARCH');
  });
});
