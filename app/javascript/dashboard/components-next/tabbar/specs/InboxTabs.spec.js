import { mount } from '@vue/test-utils';
import InboxTabs from '../InboxTabs.vue';

const items = [
  { key: 'me', name: 'Mine', count: 3 },
  { key: 'unassigned', name: 'Unassigned', count: 0 },
  { key: 'all', name: 'All', count: 12 },
];

describe('InboxTabs', () => {
  it('marks only the active tab as selected', () => {
    const wrapper = mount(InboxTabs, {
      props: { items, activeTab: 'unassigned' },
    });
    const tabs = wrapper.findAll('[role="tab"]');

    expect(tabs.map(tab => tab.attributes('aria-selected'))).toEqual([
      'false',
      'true',
      'false',
    ]);
  });

  it('shows counts only when they are greater than zero', () => {
    const wrapper = mount(InboxTabs, {
      props: { items, activeTab: 'me' },
    });

    expect(wrapper.text()).toContain('3');
    expect(wrapper.text()).toContain('12');
    expect(wrapper.findAll('[role="tab"]')[1].text()).toBe('Unassigned');
  });

  it('emits change with the key of the clicked tab', async () => {
    const wrapper = mount(InboxTabs, {
      props: { items, activeTab: 'me' },
    });

    await wrapper.findAll('[role="tab"]')[2].trigger('click');

    expect(wrapper.emitted('change')).toEqual([['all']]);
  });

  it('does not emit when the active tab is clicked again', async () => {
    const wrapper = mount(InboxTabs, {
      props: { items, activeTab: 'me' },
    });

    await wrapper.findAll('[role="tab"]')[0].trigger('click');

    expect(wrapper.emitted('change')).toBeUndefined();
  });
});
