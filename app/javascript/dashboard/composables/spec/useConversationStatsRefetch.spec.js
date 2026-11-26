import { shallowMount } from '@vue/test-utils';
import { defineComponent, nextTick, ref } from 'vue';
import { emitter } from 'shared/helpers/mitt';
import { useConversationStatsRefetch } from '../chatlist/useConversationStatsRefetch';

const documentVisibility = ref('visible');
const dispatch = vi.fn();

vi.mock('@vueuse/core', () => ({
  useDocumentVisibility: () => documentVisibility,
}));

vi.mock('vuex', () => ({
  useStore: () => ({ dispatch }),
}));

describe('useConversationStatsRefetch', () => {
  const filters = ref({ status: 'open', assigneeType: 'me' });
  const isDisabled = ref(false);
  let wrapper;

  const TestComponent = defineComponent({
    setup() {
      useConversationStatsRefetch({ filters, isDisabled });
    },
    template: '<div />',
  });

  const requestRefetch = () => emitter.emit('fetch_conversation_stats');

  const showTab = async () => {
    documentVisibility.value = 'visible';
    await nextTick();
  };

  const hideTab = async () => {
    documentVisibility.value = 'hidden';
    await nextTick();
  };

  beforeEach(() => {
    documentVisibility.value = 'visible';
    isDisabled.value = false;
    wrapper = shallowMount(TestComponent);
  });

  afterEach(() => {
    wrapper.unmount();
    vi.clearAllMocks();
  });

  it('refetches the counts for the current filters in a visible tab', () => {
    requestRefetch();

    expect(dispatch).toHaveBeenCalledWith(
      'conversationStats/get',
      filters.value
    );
  });

  it('does not refetch when it is disabled', () => {
    isDisabled.value = true;

    requestRefetch();

    expect(dispatch).not.toHaveBeenCalled();
  });

  it('does not refetch in a hidden tab', async () => {
    await hideTab();

    requestRefetch();

    expect(dispatch).not.toHaveBeenCalled();
  });

  it('refetches once when a tab that skipped refetches becomes visible', async () => {
    await hideTab();
    requestRefetch();
    requestRefetch();

    await showTab();

    expect(dispatch).toHaveBeenCalledTimes(1);
    expect(dispatch).toHaveBeenCalledWith(
      'conversationStats/get',
      filters.value
    );
  });

  it('does not refetch on return when the tab skipped nothing', async () => {
    await hideTab();

    await showTab();

    expect(dispatch).not.toHaveBeenCalled();
  });

  it('keeps the disabled check for the refetch on return', async () => {
    await hideTab();
    requestRefetch();
    isDisabled.value = true;

    await showTab();

    expect(dispatch).not.toHaveBeenCalled();
  });

  it('does not refetch after the component is unmounted', () => {
    wrapper.unmount();

    requestRefetch();

    expect(dispatch).not.toHaveBeenCalled();
  });
});
