import { ref } from 'vue';
import { mount } from '@vue/test-utils';
import VariableList from '../VariableList.vue';
import CaretAnchoredPicker from 'dashboard/components-next/preview-picker/CaretAnchoredPicker.vue';
import { withFullI18n } from 'test-i18n';

withFullI18n();

const attributes = ref([
  {
    attribute_model: 'conversation_attribute',
    attribute_key: 'fechamento',
    attribute_display_name: 'Tabulação',
    attribute_description: 'Tabulação do lead',
  },
  {
    attribute_model: 'contact_attribute',
    attribute_key: 'cpf',
    attribute_display_name: 'CPF',
    attribute_description: 'CPF do contato',
  },
]);

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: () => attributes,
}));

vi.mock('dashboard/composables/useKeyboardEvents', () => ({
  useKeyboardEvents: vi.fn(),
}));

const mountList = (props = {}) =>
  mount(VariableList, {
    props: { searchKey: '', ...props },
    global: {
      stubs: { TeleportWithDirection: { template: '<div><slot /></div>' } },
    },
  });

const search = wrapper => wrapper.get('input');
const offeredKeys = wrapper =>
  wrapper
    .findComponent(CaretAnchoredPicker)
    .props('items')
    .map(item => item.key);

describe('VariableList', () => {
  describe('when the search stops matching', () => {
    it('hands back what was typed once no variable matches, and not before', async () => {
      const wrapper = mountList();

      await search(wrapper).setValue('contato');
      expect(wrapper.emitted('release')).toBeUndefined();

      await search(wrapper).setValue('contato.');
      expect(wrapper.emitted('release')).toEqual([[{ text: 'contato.' }]]);
    });

    it('hands back a known variable once its closing brace is typed', async () => {
      const wrapper = mountList();

      await search(wrapper).setValue('contact.name');
      expect(wrapper.emitted('release')).toBeUndefined();

      await search(wrapper).setValue('contact.name}');
      expect(wrapper.emitted('release')).toEqual([[{ text: 'contact.name}' }]]);
    });

    it('hands back a Liquid filter, spaces included', async () => {
      const wrapper = mountList({ automation: true });

      await search(wrapper).setValue(' conversation.assignee.name ');
      expect(wrapper.emitted('release')).toBeUndefined();

      await search(wrapper).setValue(' conversation.assignee.name |');
      expect(wrapper.emitted('release')).toEqual([
        [{ text: ' conversation.assignee.name |' }],
      ]);
    });

    it('hands back only what was typed after the text that came from the document', async () => {
      const wrapper = mountList({
        automation: true,
        searchKey: 'conversation.before.assignee.name}}',
      });

      await search(wrapper).setValue('conversation.before.assignee.name ok');

      expect(wrapper.emitted('release')).toEqual([[{ text: ' ok' }]]);
    });

    it('asks to replace the document text when the search was edited into it', async () => {
      const wrapper = mountList({ searchKey: 'contact.na' });

      await search(wrapper).setValue('contact.x');

      expect(wrapper.emitted('release')).toEqual([
        [{ text: 'contact.x', replace: true }],
      ]);
    });

    it('leaves the punctuation after the variable out of the search', async () => {
      const wrapper = mountList({ searchKey: 'contact.name}}.' });

      expect(search(wrapper).element.value).toBe('contact.name');
      expect(offeredKeys(wrapper)).toContain('contact.name');

      await search(wrapper).setValue('contact.nme');

      expect(wrapper.emitted('release')).toEqual([
        [{ text: 'contact.nme', replace: true }],
      ]);
    });
  });

  describe('variables offered', () => {
    it('offers the assignee and the state before the run in an automation', async () => {
      const wrapper = mountList({ automation: true });

      await search(wrapper).setValue('conversation.');

      expect(offeredKeys(wrapper).join('\n')).toContain(
        'conversation.assignee.name'
      );
      expect(offeredKeys(wrapper).join('\n')).toContain(
        'conversation.before.assignee.name'
      );
      expect(offeredKeys(wrapper).join('\n')).toContain(
        'conversation.before.custom_attribute.fechamento'
      );
      expect(offeredKeys(wrapper).join('\n')).not.toContain(
        'before.custom_attribute.cpf'
      );
    });

    it('offers nothing from the automation outside an automation', async () => {
      const wrapper = mountList();

      await search(wrapper).setValue('conversation.');

      expect(offeredKeys(wrapper).join('\n')).not.toContain(
        'conversation.before.'
      );
      expect(offeredKeys(wrapper).join('\n')).not.toContain(
        'conversation.assignee.name'
      );
      expect(offeredKeys(wrapper).join('\n')).toContain(
        'conversation.custom_attribute.fechamento'
      );
    });
  });
});
