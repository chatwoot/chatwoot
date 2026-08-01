import { mount } from '@vue/test-utils';
import ButtonsForm from '../ButtonsForm.vue';
import HeaderImageInput from '../HeaderImageInput.vue';

const mountComponent = showHeaderImage =>
  mount(ButtonsForm, {
    props: {
      modelValue: {
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
});
