import { ref } from 'vue';
import { mount, RouterLinkStub } from '@vue/test-utils';
import { withFullI18n } from 'test-i18n';
import CopilotApprovalMessage from '../CopilotApprovalMessage.vue';
import Label from 'dashboard/components-next/label/Label.vue';

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch: vi.fn() }),
  useMapGetter: () => ref([{ title: 'sign-in', color: '#e54666' }]),
}));

withFullI18n();

const targets = [
  { label: '#12', url: '/app/accounts/1/conversations/12' },
  { label: '#13', url: '/app/accounts/1/conversations/13' },
];

const mountCard = approval =>
  mount(CopilotApprovalMessage, {
    props: { message: { run_id: 1, approval } },
    global: { stubs: { RouterLink: RouterLinkStub } },
  });

describe('CopilotApprovalMessage', () => {
  it('shows a reply in full with its warning before the agent sends it', () => {
    const wrapper = mountCard({
      status: 'awaiting_approval',
      action: 'send_reply',
      summary: 'SEND_REPLY',
      count: 5,
      targets,
      content: 'The sign-in problem is fixed.',
      warning: 'SEND_REPLY',
    });

    expect(wrapper.text()).toContain('Send this reply to 5 conversations:');
    expect(wrapper.text()).toContain('The sign-in problem is fixed.');
    expect(wrapper.text()).toContain(
      "5 customers get this reply, and it can't be unsent."
    );
    expect(wrapper.text()).toContain('and 3 more');
    expect(wrapper.findAll('button')[0].text()).toBe('Send reply');
  });

  it('shows labels as chips inside the change sentence', () => {
    const wrapper = mountCard({
      status: 'awaiting_approval',
      action: 'add_labels',
      summary: 'ADD_LABELS',
      values: { labels: ['sign-in'] },
      count: 2,
      targets,
    });

    expect(wrapper.findComponent(Label).text()).toBe('sign-in');
    expect(wrapper.text()).toContain('Add sign-in to 2 conversations');
  });

  it('keeps linking the records after a change applies to all of them', () => {
    const wrapper = mountCard({
      status: 'approved',
      action: 'add_labels',
      summary: 'ADD_LABELS',
      values: { labels: ['sign-in'] },
      count: 17,
      targets,
      progress: {
        finished: true,
        stopped: false,
        done: 17,
        total: 17,
        applied: 17,
        not_changed: 0,
      },
    });

    expect(wrapper.text()).toContain('Applied to 17');
    expect(
      wrapper.findAllComponents(RouterLinkStub).map(link => link.props('to'))
    ).toEqual(targets.map(target => target.url));
    expect(wrapper.text()).toContain('and 15 more');
  });

  it('links the records a finished change could not change', () => {
    const wrapper = mountCard({
      status: 'approved',
      action: 'add_labels',
      summary: 'ADD_LABELS',
      values: { labels: ['sign-in'] },
      count: 60,
      targets,
      progress: {
        finished: true,
        stopped: false,
        done: 60,
        total: 60,
        applied: 59,
        not_changed: 1,
        not_changed_targets: [targets[1]],
      },
    });

    expect(wrapper.text()).toContain('Applied to 59 of 60');
    expect(wrapper.text()).toContain('1 not changed');
    expect(
      wrapper.findAllComponents(RouterLinkStub).map(link => link.props('to'))
    ).toEqual([targets[1].url]);
    expect(wrapper.find('button').exists()).toBe(false);
  });
});
