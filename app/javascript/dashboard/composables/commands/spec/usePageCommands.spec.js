import { flushPromises, mount } from '@vue/test-utils';
import { useCommandBar } from '@bysivin/jumpbar';
import { KeepAlive, defineComponent, h, nextTick, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { recordCommands, usePageCommands } from '../usePageCommands';

vi.mock('vue-i18n');

describe('usePageCommands', () => {
  const bar = useCommandBar();
  const run = vi.fn();
  const Page = defineComponent({
    setup() {
      usePageCommands(() => [{ id: 'add_agent', title: 'Add agent', run }]);
      return () => h('div');
    },
  });

  beforeEach(() => {
    useI18n.mockReturnValue({ t: key => key });
  });

  afterEach(() => {
    bar.dispose();
  });

  it('offers the page actions first while the page is mounted', async () => {
    bar.register({
      id: 'other',
      commands: () => [{ id: 'goto', title: 'Go somewhere', scopes: ['page'] }],
    });
    const wrapper = mount(Page);
    bar.open();
    await flushPromises();

    expect(bar.visible.value[0]).toEqual(
      expect.objectContaining({
        id: 'add_agent',
        section: 'COMMAND_BAR.SECTIONS.PAGE',
        icon: 'i-lucide-plus',
      })
    );

    bar.close();
    wrapper.unmount();
    bar.open();
    await flushPromises();
    expect(bar.visible.value.map(item => item.id)).toEqual(['goto']);
  });

  it('withdraws the page actions while the page is kept alive but hidden', async () => {
    const show = ref(true);
    const wrapper = mount(
      defineComponent({
        setup: () => () =>
          h(KeepAlive, null, { default: () => (show.value ? h(Page) : null) }),
      })
    );

    show.value = false;
    await nextTick();
    bar.open();
    await flushPromises();
    expect(bar.visible.value).toEqual([]);

    bar.close();
    show.value = true;
    await nextTick();
    bar.open();
    await flushPromises();
    expect(bar.visible.value.map(item => item.id)).toEqual(['add_agent']);
    wrapper.unmount();
  });

  it('builds a page of per-record actions', () => {
    const edit = vi.fn();
    const [page, child] = recordCommands({
      id: 'edit_agent',
      title: 'Edit agent',
      icon: 'i-lucide-pencil',
      records: [{ id: 4, name: 'Sarah' }],
      label: agent => agent.name,
      run: edit,
    });

    expect(page).toEqual({
      id: 'edit_agent',
      title: 'Edit agent',
      icon: 'i-lucide-pencil',
      page: true,
    });
    expect(child).toEqual(
      expect.objectContaining({
        id: 'edit_agent-4',
        title: 'Sarah',
        parent: 'edit_agent',
      })
    );
    child.run();
    expect(edit).toHaveBeenCalledWith({ id: 4, name: 'Sarah' });
  });
});
