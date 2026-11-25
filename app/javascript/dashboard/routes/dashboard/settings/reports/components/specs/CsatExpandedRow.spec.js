import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import CsatExpandedRow from '../CsatExpandedRow.vue';

const { alert } = vi.hoisted(() => ({ alert: vi.fn() }));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key, te: () => false, locale: { value: 'en' } }),
}));

// Without this the component renders the paywall instead of the editor, and the save button this
// is about never exists.
vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({
    isCloudFeatureEnabled: () => true,
    isOnChatwootCloud: { value: false },
  }),
}));

vi.mock('dashboard/composables', () => ({ useAlert: alert }));

describe('CsatExpandedRow', () => {
  // The save call is held open on purpose: `isSaving` is internal and only true between the
  // dispatch and its resolution, so the in-flight state is unreachable unless the test owns when
  // the promise settles.
  const mountRow = () => {
    let settle;
    const update = vi.fn().mockImplementation(
      () =>
        new Promise(resolve => {
          settle = resolve;
        })
    );
    const store = createStore({
      modules: {
        csat: { namespaced: true, actions: { update } },
      },
    });

    const wrapper = mount(CsatExpandedRow, {
      props: { response: { id: 7, csat_review_notes: '' } },
      global: {
        plugins: [store],
        mocks: { $t: key => key },
        directives: { dompurifyHtml: () => {} },
      },
    });

    return { wrapper, settle: () => settle(), update };
  };

  // `hasChanges` gates the click, so the note has to actually differ from what the response
  // carries before the button will do anything.
  const typeANote = async wrapper => {
    await wrapper
      .findComponent(Editor)
      .vm.$emit('update:modelValue', 'The agent fixed it on the first reply');
  };

  const saveButton = wrapper =>
    wrapper
      .findAll('button')
      .find(candidate =>
        candidate.text().includes('CSAT_REPORTS.REVIEW_NOTES.SAVE')
      );

  it('draws the spinner on the save button while the write is in flight', async () => {
    const { wrapper } = mountRow();
    await typeANote(wrapper);

    expect(saveButton(wrapper)).toBeDefined();
    expect(saveButton(wrapper).find('svg.animate-spin').exists()).toBe(false);

    await saveButton(wrapper).trigger('click');

    // Scoped to the button rather than to the tree. Only one button renders here today, so the
    // two are equivalent right now; they stop being equivalent the moment a second one appears,
    // and a tree-wide lookup would then pass with the spinner on the wrong one.
    expect(saveButton(wrapper).find('svg.animate-spin').exists()).toBe(true);
  });

  it('takes the spinner away once the write comes back', async () => {
    const { wrapper, settle } = mountRow();
    await typeANote(wrapper);
    await saveButton(wrapper).trigger('click');

    expect(saveButton(wrapper).find('svg.animate-spin').exists()).toBe(true);

    settle();
    await new Promise(resolve => {
      setTimeout(resolve, 0);
    });
    await wrapper.vm.$nextTick();

    expect(saveButton(wrapper).find('svg.animate-spin').exists()).toBe(false);
  });

  // The loading state used to arrive as `loading`, which is not declared on the component and not
  // excluded from the attribute fallthrough, so it landed on the `<button>` element, where the
  // browser ignores it. It shows in both states, because a bound `false` renders as the string
  // "false" on an undeclared attribute.
  it('never leaves the loading state on the element as an inert attribute', async () => {
    const { wrapper } = mountRow();
    await typeANote(wrapper);

    expect(saveButton(wrapper).attributes('loading')).toBeUndefined();

    await saveButton(wrapper).trigger('click');

    expect(saveButton(wrapper).attributes('loading')).toBeUndefined();
  });

  it('still disables the button while saving, which is the half that already worked', async () => {
    const { wrapper } = mountRow();
    await typeANote(wrapper);
    await saveButton(wrapper).trigger('click');

    expect(saveButton(wrapper).attributes('disabled')).toBeDefined();
  });
});
