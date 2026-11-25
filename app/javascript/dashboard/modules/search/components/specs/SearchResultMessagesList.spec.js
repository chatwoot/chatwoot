import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import { withFullI18n } from 'test-i18n';
import SearchResultMessagesList from '../SearchResultMessagesList.vue';

withFullI18n();

const HINT = 'Type at least 3 characters to search messages.';

const mountList = ({ query, minimum }) => {
  const store = createStore({
    getters: { getCurrentAccountId: () => 1 },
    modules: {
      globalConfig: {
        namespaced: true,
        getters: { get: () => ({ messageSearchMinQueryLength: minimum }) },
      },
    },
  });
  return mount(SearchResultMessagesList, {
    props: { messages: [], query, isFetching: false },
    global: { plugins: [store] },
  });
};

describe('SearchResultMessagesList minimum term length hint', () => {
  it('tells the agent the minimum when the term is shorter', () => {
    const wrapper = mountList({ query: '16', minimum: 3 });

    expect(wrapper.text()).toContain(HINT);
    expect(wrapper.text()).not.toContain('No messages found');
  });

  it('shows the regular empty state when the term reaches the minimum', () => {
    const wrapper = mountList({ query: '169', minimum: 3 });

    expect(wrapper.text()).not.toContain(HINT);
    expect(wrapper.text()).toContain("No messages found for query '169'");
  });

  it('shows no hint when there is no minimum', () => {
    const wrapper = mountList({ query: '1', minimum: 0 });

    expect(wrapper.text()).not.toContain('characters to search messages');
  });
});
