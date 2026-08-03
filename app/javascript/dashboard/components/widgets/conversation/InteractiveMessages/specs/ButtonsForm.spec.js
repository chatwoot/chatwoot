import { mount } from '@vue/test-utils';
import ButtonsForm from '../ButtonsForm.vue';
import HeaderImageInput from '../HeaderImageInput.vue';

const mountComponent = (showHeaderImage, modelValue) =>
  mount(ButtonsForm, {
    props: {
      modelValue: modelValue || {
        bodyText: '',
        footerText: '',
        headerMediaUrl: '',
        buttons: [{ id: 'btn_1', text: '' }],
      },
      showHeaderImage,
    },
    global: {
      mocks: { $t: key => key },
    },
  });

describe('ButtonsForm', () => {
  it('hides the header image input when the channel does not support it', () => {
    expect(mountComponent(false).findComponent(HeaderImageInput).exists()).toBe(
      false
    );
  });

  it('shows the header image input when the channel supports it', () => {
    expect(mountComponent(true).findComponent(HeaderImageInput).exists()).toBe(
      true
    );
  });

  it('assigns a unique id to a new button after removing a non-final button', async () => {
    const wrapper = mountComponent(true, {
      bodyText: '',
      footerText: '',
      headerMediaUrl: '',
      buttons: [
        { id: 'btn_1', text: 'A' },
        { id: 'btn_2', text: 'B' },
        { id: 'btn_3', text: 'C' },
      ],
    });

    await wrapper.find('button[aria-label]').trigger('click');
    const afterRemoval = wrapper.emitted('update:modelValue').at(-1)[0];
    expect(afterRemoval.buttons.map(button => button.id)).toEqual([
      'btn_2',
      'btn_3',
    ]);

    await wrapper.setProps({ modelValue: afterRemoval });
    const addButton = wrapper
      .findAll('button')
      .find(candidate => !candidate.attributes('aria-label'));
    await addButton.trigger('click');

    const afterAdd = wrapper.emitted('update:modelValue').at(-1)[0];
    const ids = afterAdd.buttons.map(button => button.id);
    expect(ids).toEqual(['btn_2', 'btn_3', 'btn_4']);
    expect(new Set(ids).size).toBe(ids.length);
  });
});
