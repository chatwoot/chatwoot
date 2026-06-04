import { describe, it, expect, vi } from 'vitest';
import { mount } from '@vue/test-utils';
import TagGroupMembers from '../TagGroupMembers.vue';
import { useStoreGetters } from 'dashboard/composables/store';

vi.mock('dashboard/composables/store');
vi.mock('dashboard/composables/useKeyboardNavigableList', () => ({
  useKeyboardNavigableList: vi.fn(),
}));

const MEMBERS = [
  {
    id: 1,
    is_active: true,
    contact: {
      id: 10,
      name: 'Alice Silva',
      phone_number: '+5511999990001',
      thumbnail: 'alice.jpg',
    },
  },
  {
    id: 2,
    is_active: true,
    contact: {
      id: 20,
      name: 'Bob Santos',
      phone_number: '+5511999990002',
      thumbnail: 'bob.jpg',
    },
  },
  {
    id: 3,
    is_active: false,
    contact: {
      id: 30,
      name: 'Charlie Inactive',
      phone_number: '+5511999990003',
      thumbnail: '',
    },
  },
];

const mountComponent = (props = {}) => {
  const getGroupMembersFn = vi.fn(contactId => {
    if (contactId === 100) return MEMBERS;
    return [];
  });

  useStoreGetters.mockReturnValue({
    'groupMembers/getGroupMembers': { value: getGroupMembersFn },
  });

  return mount(TagGroupMembers, {
    props: {
      groupContactId: 100,
      searchKey: '',
      ...props,
    },
    global: {
      stubs: { Avatar: true },
    },
  });
};

describe('TagGroupMembers', () => {
  it('does not include an @all/everyone item in the list', () => {
    const wrapper = mountComponent();

    const listItems = wrapper.findAll('[role="option"]');
    const names = listItems.map(el => el.text());
    const hasEveryone = names.some(
      n => n.includes('all') && !n.includes('Alice')
    );

    expect(hasEveryone).toBe(false);
  });

  it('renders only active members excluding the inbox phone number', () => {
    const wrapper = mountComponent({
      excludePhoneNumber: '+5511999990001',
    });

    const listItems = wrapper.findAll('[role="option"]');

    expect(listItems).toHaveLength(1);
    expect(listItems[0].text()).toContain('Bob Santos');
  });

  it('filters members by search key matching name', () => {
    const wrapper = mountComponent({ searchKey: 'alice' });

    const listItems = wrapper.findAll('[role="option"]');

    expect(listItems).toHaveLength(1);
    expect(listItems[0].text()).toContain('Alice Silva');
  });

  it('filters members by search key matching phone number', () => {
    const wrapper = mountComponent({ searchKey: '0002' });

    const listItems = wrapper.findAll('[role="option"]');

    expect(listItems).toHaveLength(1);
    expect(listItems[0].text()).toContain('Bob Santos');
  });

  it('shows no dropdown when no members match the search', () => {
    const wrapper = mountComponent({ searchKey: 'nonexistent' });

    const list = wrapper.find('ul');

    expect(list.exists()).toBe(false);
  });

  it('emits selectAgent with the correct member on click', async () => {
    const wrapper = mountComponent();

    const firstOption = wrapper.findAll('[role="option"]')[0];
    await firstOption.trigger('click');

    expect(wrapper.emitted('selectAgent')).toBeTruthy();
    expect(wrapper.emitted('selectAgent')[0][0]).toMatchObject({
      id: 10,
      type: 'contact',
      name: 'Alice Silva',
    });
  });

  it('renders a section header', () => {
    const wrapper = mountComponent();

    const header = wrapper.find(
      '.text-xs.font-medium.tracking-wide.capitalize'
    );

    expect(header.exists()).toBe(true);
  });
});
