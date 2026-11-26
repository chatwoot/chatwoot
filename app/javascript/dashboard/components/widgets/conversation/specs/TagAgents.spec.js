import { flushPromises, mount } from '@vue/test-utils';
import { domPurifyConfig } from 'shared/helpers/HTMLSanitizer';
import VueDOMPurifyHTML from 'vue-dompurify-html';
import { createStore } from 'vuex';
import TagAgents from '../TagAgents.vue';

const agents = [
  { id: 1, name: 'Amara Okafor', email: 'amara@example.com' },
  { id: 2, name: 'Lucas Meyer', email: 'lucas@example.com' },
  { id: 3, name: 'Priya Nair', email: 'priya@example.com' },
  { id: 4, name: 'Tomas Novak', email: 'tomas@example.com' },
  { id: 5, name: 'Hana Sato', email: 'hana@example.com' },
  { id: 6, name: 'Elena Marin', email: 'elena@example.com' },
  { id: 7, name: 'Noah Fischer', email: 'noah@example.com' },
  { id: 8, name: 'Maya Chen', email: 'maya@example.com' },
];
const teams = [
  { id: 1, name: 'Billing', description: 'Invoices and refunds' },
  { id: 2, name: 'Mobile', description: 'iOS and Android apps' },
  { id: 3, name: 'Enterprise', description: 'Contracts and SSO' },
  { id: 4, name: 'Self-hosted', description: 'Installs and upgrades' },
  { id: 5, name: 'Support', description: 'First line' },
  { id: 6, name: 'Design', description: 'Product design' },
  { id: 7, name: 'Product', description: 'Roadmap questions' },
  { id: 8, name: 'Refunds', description: 'Disputes and chargebacks' },
];

let mountedList = null;

afterEach(() => {
  mountedList.unmount();
  localStorage.clear();
});

const mountList = (searchKey = '') => {
  const store = createStore({
    getters: {
      'agents/getVerifiedAgents': () => agents,
      'teams/getTeams': () => teams,
      'accounts/isRTL': () => false,
    },
  });

  mountedList = mount(TagAgents, {
    props: { searchKey },
    global: {
      plugins: [store, [VueDOMPurifyHTML, domPurifyConfig]],
      stubs: { teleport: true },
    },
  });
  return mountedList;
};

const optionTexts = wrapper =>
  wrapper.findAll('[role="option"]').map(option => option.text());

const pressKey = key => {
  const event = new KeyboardEvent('keydown', {
    key,
    code: key,
    bubbles: true,
    cancelable: true,
  });
  document.dispatchEvent(event);
  return event;
};

describe('TagAgents', () => {
  it('follows the name typed after @ in the editor', async () => {
    const wrapper = mountList('ama');
    expect(optionTexts(wrapper)).toEqual([
      expect.stringContaining('Amara Okafor'),
    ]);

    await wrapper.setProps({ searchKey: 'bill' });
    expect(optionTexts(wrapper)).toEqual([expect.stringContaining('Billing')]);
  });

  it('shows six agents and six teams until something is typed', async () => {
    const wrapper = mountList();
    expect(optionTexts(wrapper)).toHaveLength(12);

    await wrapper.setProps({ searchKey: 'a' });
    expect(optionTexts(wrapper)).toHaveLength(8);
  });

  it('lists the people picked most often first', async () => {
    mountList('may');
    await flushPromises();
    pressKey('Tab');
    mountedList.unmount();

    expect(optionTexts(mountList())[0]).toContain('Maya Chen');
  });

  it('has no search field of its own', () => {
    expect(mountList().find('input').exists()).toBe(false);
  });

  it('reads out the highlighted person to screen readers', () => {
    const announcement = mountList('ama').find('[aria-live="polite"]');

    expect(announcement.text()).toContain('Amara Okafor');
  });

  it('shows no list when nobody matches', () => {
    expect(mountList('zzz').find('[role="listbox"]').exists()).toBe(false);
  });

  it('tells the editor whether anybody matches', async () => {
    const wrapper = mountList('ama');
    expect(wrapper.emitted('update:hasMatches').at(-1)).toEqual([true]);

    await wrapper.setProps({ searchKey: 'zzz' });
    expect(wrapper.emitted('update:hasMatches').at(-1)).toEqual([false]);
  });

  it('picks the highlighted person on Tab', async () => {
    const wrapper = mountList('ama');
    await flushPromises();
    pressKey('Tab');

    expect(wrapper.emitted('selectAgent')[0][0]).toMatchObject({
      id: 1,
      type: 'user',
    });
  });

  it('leaves Backspace to the editor', async () => {
    mountList('ama');
    await flushPromises();

    expect(pressKey('Backspace').defaultPrevented).toBe(false);
  });
});
