import { mount } from '@vue/test-utils';
import Index from '../Index.vue';

vi.mock('dashboard/composables/useAdmin', () => ({
  useAdmin: () => ({
    isAdmin: { value: true },
  }),
}));

describe('ContextMenu/Index', () => {
  const mountMenu = (
    props = {},
    labels = [{ id: 1, title: 'test', color: '#000' }]
  ) =>
    mount(Index, {
      props: {
        chatId: 1,
        status: 'open',
        hasUnreadMessages: false,
        allowedOptions: ['label'],
        ...props,
      },
      global: {
        mocks: {
          $t: key => key,
          $store: {
            getters: {
              'labels/getLabels': labels,
              'inboxAssignableAgents/getAssignableAgents': () => [],
              'inboxAssignableAgents/getUiFlags': () => ({ isFetching: false }),
              'teams/getTeams': [],
            },
            dispatch: vi.fn(),
          },
        },
      },
    });

  it('defines focusLabelSearchInput and handleGlobalKeyDown methods', () => {
    const wrapper = mountMenu();
    expect(typeof wrapper.vm.focusLabelSearchInput).toBe('function');
    expect(typeof wrapper.vm.handleGlobalKeyDown).toBe('function');
  });

  it('focuses the label search input on focusLabelSearchInput call', async () => {
    const wrapper = mountMenu();
    const input = wrapper.find('input[type="search"]');
    expect(input.exists()).toBe(true);
    const focusSpy = vi.spyOn(input.element, 'focus');
    wrapper.vm.focusLabelSearchInput();
    await wrapper.vm.$nextTick();
    expect(focusSpy).toHaveBeenCalled();
  });

  it('handles global keydown and updates labelSearchQuery if input not focused', () => {
    const wrapper = mountMenu();
    wrapper.vm.isLabelSubmenuHovered = true;
    const event = {
      key: 'a',
      ctrlKey: false,
      metaKey: false,
      altKey: false,
      preventDefault: vi.fn(),
      target: document.body,
    };
    wrapper.vm.handleGlobalKeyDown(event);
    expect(wrapper.vm.labelSearchQuery).toBe('a');
  });
  it('navigates labels with arrow keys and selects with Enter', async () => {
    const labels = [
      { id: 1, title: 'label1', color: '#000' },
      { id: 2, title: 'label2', color: '#fff' },
    ];
    const wrapper = mountMenu({}, labels);

    expect(wrapper.vm.activeLabelIndex).toBe(0);
    wrapper.vm.moveActiveLabel(1);
    expect(wrapper.vm.activeLabelIndex).toBe(1);

    wrapper.vm.moveActiveLabel(1);
    expect(wrapper.vm.activeLabelIndex).toBe(0);

    wrapper.vm.moveActiveLabel(-1);
    expect(wrapper.vm.activeLabelIndex).toBe(1);

    const toggleSpy = vi.spyOn(wrapper.vm, 'toggleLabel');
    wrapper.vm.selectActiveLabel();
    expect(toggleSpy).toHaveBeenCalledWith(labels[1]);
  });

  it('filters labels based on labelSearchQuery', async () => {
    const labels = [
      { id: 1, title: 'Bug', color: '#000' },
      { id: 2, title: 'Feature', color: '#fff' },
    ];
    const wrapper = mountMenu({}, labels);

    expect(wrapper.vm.filteredLabels.length).toBe(2);

    wrapper.vm.labelSearchQuery = 'Bug';
    await wrapper.vm.$nextTick();

    expect(wrapper.vm.filteredLabels.length).toBe(1);
    expect(wrapper.vm.filteredLabels[0].title).toBe('Bug');
  });

  it('resets activeLabelIndex to 0 when labelSearchQuery changes', async () => {
    const labels = [
      { id: 1, title: 'Bug', color: '#000' },
      { id: 2, title: 'Feature', color: '#fff' },
    ];
    const wrapper = mountMenu({}, labels);

    wrapper.vm.moveActiveLabel(1);
    expect(wrapper.vm.activeLabelIndex).toBe(1);

    wrapper.vm.labelSearchQuery = 'Bug';
    await wrapper.vm.$nextTick();

    expect(wrapper.vm.activeLabelIndex).toBe(0);
  });
});
