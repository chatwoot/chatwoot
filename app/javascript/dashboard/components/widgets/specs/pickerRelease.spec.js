import { ref } from 'vue';
import { mount } from '@vue/test-utils';
import { withFullI18n } from 'test-i18n';
import CaretAnchoredPicker from 'dashboard/components-next/preview-picker/CaretAnchoredPicker.vue';
import TagAgents from '../conversation/TagAgents.vue';
import CannedResponse from '../conversation/CannedResponse.vue';
import VariableList from '../conversation/VariableList.vue';
import MacroList from '../conversation/MacroList.vue';
import KeyboardEmojiSelector from '../WootWriter/keyboardEmojiSelector.vue';

withFullI18n();

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch: vi.fn(), getters: {} }),
  useStoreGetters: () => new Proxy({}, { get: () => ref([]) }),
  useMapGetter: () => ref([]),
}));

vi.mock('dashboard/composables/useKeyboardEvents', () => ({
  useKeyboardEvents: vi.fn(),
}));

// Every picker the editor opens hands a search it gave up on back to the editor.
describe.each([
  ['TagAgents', TagAgents],
  ['CannedResponse', CannedResponse],
  ['VariableList', VariableList],
  ['MacroList', MacroList],
  ['KeyboardEmojiSelector', KeyboardEmojiSelector],
])('%s', (_, Picker) => {
  it('passes on what its search hands back', () => {
    const wrapper = mount(Picker, {
      props: { searchKey: '' },
      global: {
        stubs: { TeleportWithDirection: { template: '<div><slot /></div>' } },
        directives: { dompurifyHtml: {} },
      },
    });

    wrapper
      .findComponent(CaretAnchoredPicker)
      .vm.$emit('release', { text: ' / fim' });

    expect(wrapper.emitted('release')).toEqual([[{ text: ' / fim' }]]);
  });
});
