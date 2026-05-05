import { defineComponent, h, nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import ContactNoteItem from '../ContactNoteItem.vue';

vi.mock('shared/helpers/timeHelper', () => ({
  dynamicTime: vi.fn(timestamp => `time:${timestamp}`),
}));

vi.mock('shared/composables/useMessageFormatter', () => ({
  useMessageFormatter: () => ({
    formatMessage: message => message,
  }),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: key => key,
  }),
}));

const EditorStub = defineComponent({
  name: 'Editor',
  props: {
    modelValue: {
      type: String,
      default: '',
    },
  },
  emits: ['update:modelValue'],
  setup(props, { emit, slots }) {
    return () =>
      h('div', [
        h('textarea', {
          value: props.modelValue,
          onInput: event => emit('update:modelValue', event.target.value),
        }),
        slots.actions?.(),
      ]);
  },
});

const buildWrapper = (props = {}) =>
  shallowMount(ContactNoteItem, {
    props: {
      note: {
        id: 1,
        content: 'Original note',
        createdAt: 1730786556,
        updatedAt: 1730787556,
        updatedBy: {
          id: 2,
          name: 'Diana',
        },
        user: {
          id: 1,
          name: 'Bruce',
        },
      },
      writtenBy: 'Bruce',
      allowEdit: true,
      ...props,
    },
    global: {
      directives: {
        dompurifyHtml: {},
      },
      stubs: {
        Avatar: true,
        Button: true,
        Editor: EditorStub,
      },
    },
  });

describe('ContactNoteItem', () => {
  it('does not render updated metadata for a newly created note', () => {
    const wrapper = buildWrapper({
      note: {
        id: 1,
        content: 'Original note',
        createdAt: 1730786556,
        updatedAt: 1730786556,
        updatedBy: {
          id: 1,
          name: 'Bruce',
        },
        user: {
          id: 1,
          name: 'Bruce',
        },
      },
    });

    expect(wrapper.text()).not.toContain(
      'CONTACTS_LAYOUT.SIDEBAR.NOTES.UPDATED'
    );
  });

  it('renders updated metadata when a note has been edited', () => {
    const wrapper = buildWrapper();

    expect(wrapper.text()).toContain('CONTACTS_LAYOUT.SIDEBAR.NOTES.UPDATED');
    expect(wrapper.text()).toContain('Diana');
    expect(wrapper.text()).toContain('time:1730787556');
  });

  it('adds an accessible label to the edit button', () => {
    const wrapper = buildWrapper();

    expect(
      wrapper.find('[data-test-id="contact-note-edit"]').attributes()
    ).toMatchObject({
      'aria-label': 'CONTACTS_LAYOUT.SIDEBAR.NOTES.EDIT',
    });
    expect(
      wrapper.find('[data-test-id="contact-note-edit"]').classes()
    ).toEqual(
      expect.arrayContaining([
        'focus:opacity-100',
        'group-focus-within/note:opacity-100',
      ])
    );
  });

  it('emits update with edited note content', async () => {
    const wrapper = buildWrapper();

    await wrapper.find('[data-test-id="contact-note-edit"]').trigger('click');
    await wrapper.find('textarea').setValue('Edited note');
    await wrapper.find('[data-test-id="contact-note-save"]').trigger('click');

    expect(wrapper.emitted('update')).toEqual([
      [{ noteId: 1, content: 'Edited note' }],
    ]);
  });

  it('cancels editing without emitting update and resets draft content', async () => {
    const wrapper = buildWrapper();

    await wrapper.find('[data-test-id="contact-note-edit"]').trigger('click');
    await wrapper.find('textarea').setValue('Edited note');
    await wrapper.find('[data-test-id="contact-note-cancel"]').trigger('click');

    expect(wrapper.emitted('update')).toBeUndefined();
    expect(wrapper.find('textarea').exists()).toBe(false);

    await wrapper.find('[data-test-id="contact-note-edit"]').trigger('click');

    expect(wrapper.find('textarea').element.value).toBe('Original note');
  });

  it('recomputes collapse state after note content changes', async () => {
    let contentHeight = 10;
    const clientHeight = vi
      .spyOn(HTMLElement.prototype, 'clientHeight', 'get')
      .mockImplementation(() => contentHeight);
    try {
      const wrapper = buildWrapper({
        collapsible: true,
        note: {
          id: 1,
          content: 'Short note',
          createdAt: 1730786556,
          updatedAt: 1730786556,
          updatedBy: {
            id: 1,
            name: 'Bruce',
          },
          user: {
            id: 1,
            name: 'Bruce',
          },
        },
      });

      expect(wrapper.find('[icon="i-lucide-chevron-down"]').exists()).toBe(
        false
      );

      contentHeight = 100;
      await wrapper.setProps({
        note: {
          id: 1,
          content:
            'Long note with enough content to require the collapsed display state',
          createdAt: 1730786556,
          updatedAt: 1730787556,
          updatedBy: {
            id: 1,
            name: 'Bruce',
          },
          user: {
            id: 1,
            name: 'Bruce',
          },
        },
      });
      await nextTick();

      expect(wrapper.find('[icon="i-lucide-chevron-down"]').exists()).toBe(
        true
      );
    } finally {
      clientHeight.mockRestore();
    }
  });
});
