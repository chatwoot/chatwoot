import { mount } from '@vue/test-utils';
import CannedResponse from '../CannedResponse.vue';

const { cannedResponses } = vi.hoisted(() => ({
  cannedResponses: { value: [] },
}));

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch: () => {} }),
  useMapGetter: key =>
    key === 'getCannedResponses'
      ? cannedResponses
      : { value: { fetchingList: false } },
}));

const PickerStub = {
  name: 'CaretAnchoredPicker',
  props: ['items'],
  template: '<div><slot name="preview" :item="items[0]" /></div>',
};

const global = {
  stubs: { CaretAnchoredPicker: PickerStub },
  directives: {
    dompurifyHtml: (element, binding) => {
      element.innerHTML = binding.value;
    },
  },
};

// Responses that also match "ola", so the accented ones have to compete for a place
const COMPETING_RESPONSES = [
  { id: 11, short_code: 'hola', content: 'Hola, como estas' },
  { id: 12, short_code: 'solar', content: 'Solar panel order status' },
  { id: 13, short_code: 'colab', content: 'Collaboration request' },
  { id: 14, short_code: 'spanish', content: 'Hola!' },
];

describe('CannedResponse', () => {
  describe('when the search has no accents', () => {
    beforeEach(() => {
      cannedResponses.value = [
        { id: 1, short_code: 'olá', content: 'Hi there' },
        { id: 2, short_code: 'saudacao', content: 'Olá, tudo bem?' },
        {
          id: 3,
          short_code: 'later',
          content: 'Thanks for waiting, we will reply promptly. Olá!',
        },
        ...COMPETING_RESPONSES,
      ];
    });

    it('returns responses with an accented shortcode or body', () => {
      const wrapper = mount(CannedResponse, {
        props: { searchKey: 'ola' },
        global,
      });
      const items = wrapper.findComponent(PickerStub).props('items');

      expect(items.map(item => item.id)).toEqual(
        expect.arrayContaining([1, 2, 3])
      );
    });

    it('highlights the match with its original spelling', () => {
      const wrapper = mount(CannedResponse, {
        props: { searchKey: 'ola' },
        global,
      });
      const items = wrapper.findComponent(PickerStub).props('items');

      expect(items.find(item => item.id === 1).title.trim()).toBe(
        '/<span class="text-n-blue-text">olá</span>'
      );
      expect(items.find(item => item.id === 2).subtitle.trim()).toBe(
        '<span class="text-n-blue-text">Olá</span>, tudo bem?'
      );
    });

    it('moves the snippet to the match and keeps its original spelling', () => {
      const wrapper = mount(CannedResponse, {
        props: { searchKey: 'ola' },
        global,
      });
      const items = wrapper.findComponent(PickerStub).props('items');

      expect(items.find(item => item.id === 3).subtitle.trim()).toBe(
        '…we will reply promptly. <span class="text-n-blue-text">Olá</span>!'
      );
    });
  });

  describe('when a response contains a variable', () => {
    beforeEach(() => {
      cannedResponses.value = [
        { id: 1, short_code: 'greet', content: 'Olá, {{contact.name}}' },
        ...COMPETING_RESPONSES,
      ];
    });

    it('does not match on the current contact name', () => {
      const wrapper = mount(CannedResponse, {
        props: { searchKey: 'maria', variables: { 'contact.name': 'Maria' } },
        global,
      });
      const items = wrapper.findComponent(PickerStub).props('items');

      expect(items).toEqual([]);
    });

    it('ranks the results the same for every contact', () => {
      const forMaria = mount(CannedResponse, {
        props: { searchKey: 'ola', variables: { 'contact.name': 'Maria' } },
        global,
      });
      const forOlavo = mount(CannedResponse, {
        props: { searchKey: 'ola', variables: { 'contact.name': 'Olavo' } },
        global,
      });
      const idsFor = wrapper =>
        wrapper
          .findComponent(PickerStub)
          .props('items')
          .map(item => item.id);

      expect(idsFor(forMaria)).toContain(1);
      expect(idsFor(forMaria)).toEqual(idsFor(forOlavo));
    });

    it('resolves the variable in the preview only', () => {
      const wrapper = mount(CannedResponse, {
        props: { searchKey: 'greet', variables: { 'contact.name': 'Maria' } },
        global,
      });
      const items = wrapper.findComponent(PickerStub).props('items');

      expect(items[0].subtitle.trim()).toBe('Olá, {{contact.name}}');
      expect(wrapper.text()).toContain('Olá, Maria');
    });
  });
});
