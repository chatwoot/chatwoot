import { ref } from 'vue';
import { mount } from '@vue/test-utils';
import CannedResponse from '../CannedResponse.vue';
import { withFullI18n } from 'test-i18n';

withFullI18n();

const cannedResponses = ref([
  { id: 1, short_code: 'saudacao', content: 'Olá, tudo bem?' },
]);
const uiFlags = ref({ fetchingList: false });

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch: vi.fn() }),
  useMapGetter: name =>
    name === 'getCannedResponses' ? cannedResponses : uiFlags,
}));

vi.mock('dashboard/composables/useKeyboardEvents', () => ({
  useKeyboardEvents: vi.fn(),
}));

const mountList = () =>
  mount(CannedResponse, {
    props: { searchKey: '' },
    global: {
      stubs: { TeleportWithDirection: { template: '<div><slot /></div>' } },
      directives: { dompurifyHtml: {} },
    },
  });

describe('CannedResponse', () => {
  it('hands back a sentence that only used a slash as punctuation', async () => {
    const wrapper = mountList();
    const search = wrapper.get('input');

    await search.setValue('sau');
    expect(wrapper.emitted('release')).toBeUndefined();

    await search.setValue(' Agora com: {{');
    expect(wrapper.emitted('release')).toEqual([[{ text: ' Agora com: {{' }]]);
  });
});
