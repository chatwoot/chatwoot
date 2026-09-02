import { shallowMount } from '@vue/test-utils';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import ResponseForm from './ResponseForm.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: () => ({ value: { creatingItem: false } }),
}));

describe('ResponseForm', () => {
  it('prefills a new FAQ answer when initial playground knowledge is supplied', () => {
    const wrapper = shallowMount(ResponseForm, {
      props: {
        mode: 'create',
        response: {
          question: '',
          answer: 'Temporary playground knowledge',
        },
      },
    });

    expect(wrapper.findComponent(Editor).props('modelValue')).toBe(
      'Temporary playground knowledge'
    );
  });
});
