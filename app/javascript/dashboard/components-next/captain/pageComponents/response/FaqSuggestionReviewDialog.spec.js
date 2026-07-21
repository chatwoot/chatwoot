import { flushPromises, shallowMount } from '@vue/test-utils';
import FaqSuggestionReviewDialog from './FaqSuggestionReviewDialog.vue';

const { dispatch, uiFlags } = vi.hoisted(() => ({
  dispatch: vi.fn(),
  uiFlags: {
    value: {
      fetchingItem: false,
      updatingItem: false,
      deletingItem: false,
    },
  },
}));

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch }),
  useMapGetter: () => uiFlags,
}));

vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('vue-router', () => ({
  useRouter: () => ({ push: vi.fn() }),
}));

const DialogStub = {
  template: `
    <div>
      <slot name="description" />
      <slot />
      <slot name="footer" />
    </div>
  `,
};

describe('FaqSuggestionReviewDialog', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('keeps a visible error when source conversations fail to load', async () => {
    dispatch.mockRejectedValueOnce(new Error('Request failed'));

    const wrapper = shallowMount(FaqSuggestionReviewDialog, {
      props: {
        suggestion: {
          id: 1,
          question: 'How do I enable the feature?',
          answer: 'Turn it on in settings.',
          source_count: 2,
          assistant: { name: 'Support assistant' },
          language: 'en',
        },
      },
      global: {
        mocks: { $t: key => key },
        stubs: { Dialog: DialogStub },
      },
    });

    await flushPromises();

    expect(wrapper.get('[role="alert"]').text()).toContain(
      'CAPTAIN.FAQ_SUGGESTIONS.ERRORS.LOAD_DETAILS'
    );
    expect(wrapper.text()).not.toContain(
      'CAPTAIN.FAQ_SUGGESTIONS.DETAILS.NO_SOURCES'
    );
  });
});
