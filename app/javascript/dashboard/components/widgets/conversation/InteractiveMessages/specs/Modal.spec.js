import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { CONTENT_TYPES } from 'dashboard/components-next/message/constants';
import Modal from '../Modal.vue';

const mountComponent = isInstagram =>
  shallowMount(Modal, {
    props: { show: true, isInstagram },
    global: {
      mocks: { $t: key => key },
    },
  });

describe('InteractiveMessagesModal', () => {
  it('omits a residual header image from Instagram quick reply payloads', async () => {
    const wrapper = mountComponent(true);
    wrapper.vm.selectedType = CONTENT_TYPES.INTERACTIVE_BUTTONS;
    wrapper.vm.buttonsForm = {
      bodyText: 'Choose an option',
      footerText: '',
      headerMediaUrl: 'https://example.com/header.jpg',
      buttons: [{ id: 'btn_1', text: 'Option A' }],
    };
    await nextTick();

    wrapper.vm.onSend();

    expect(
      wrapper.emitted('onSend')[0][0].contentAttributes.header
    ).toBeUndefined();
  });

  it('keeps the header image in Instagram CTA URL payloads', () => {
    const wrapper = mountComponent(true);
    wrapper.vm.ctaUrlForm = {
      bodyText: 'Visit our site',
      footerText: '',
      headerMediaUrl: 'https://example.com/header.jpg',
      buttonText: 'Visit',
      buttonUrl: 'https://example.com',
    };

    wrapper.vm.onSend();

    expect(wrapper.emitted('onSend')[0][0].contentAttributes.header).toEqual({
      type: 'image',
      media_url: 'https://example.com/header.jpg',
    });
  });
});
