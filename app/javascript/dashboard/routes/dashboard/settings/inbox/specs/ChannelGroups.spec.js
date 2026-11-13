import { shallowMount, flushPromises } from '@vue/test-utils';
import ChannelGroups from '../ChannelGroups.vue';

const { dispatch } = vi.hoisted(() => ({ dispatch: vi.fn() }));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/composables/store', async () => {
  const { ref } = await import('vue');
  return { useStore: () => ({ dispatch }), useMapGetter: () => ref([]) };
});
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));

const mountPage = () =>
  shallowMount(ChannelGroups, {
    global: {
      stubs: {
        SettingsLayout: { template: '<div><slot /><slot name="body" /></div>' },
      },
    },
  });

describe('channel group loading', () => {
  it('shows the retry state when inbox loading resolves to false', async () => {
    dispatch.mockImplementation(action =>
      Promise.resolve(action === 'inboxes/get' ? false : [])
    );
    const wrapper = mountPage();
    await flushPromises();
    expect(wrapper.text()).toContain('CHANNEL_GROUPS.LOAD_ERROR');
    wrapper.unmount();
  });

  it('loads the editor when both requests succeed', async () => {
    dispatch.mockResolvedValue([]);
    const wrapper = mountPage();
    await flushPromises();
    expect(wrapper.text()).not.toContain('CHANNEL_GROUPS.LOAD_ERROR');
    wrapper.unmount();
  });
});
