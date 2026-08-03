import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { CONTENT_TYPES } from 'dashboard/components-next/message/constants';
import Modal from '../Modal.vue';

const mountComponent = (isInstagram, allowListType = false) =>
  shallowMount(Modal, {
    props: { show: true, isInstagram, allowListType },
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

  it('blocks sending buttons with an invalid header image on non-Instagram channels', async () => {
    const wrapper = mountComponent(false);
    wrapper.vm.selectedType = CONTENT_TYPES.INTERACTIVE_BUTTONS;
    wrapper.vm.buttonsForm = {
      bodyText: 'Choose an option',
      footerText: '',
      headerMediaUrl: 'https://example.com/broken.jpg',
      buttons: [{ id: 'btn_1', text: 'Option A' }],
    };
    wrapper.vm.isButtonsHeaderImageValid = false;
    await nextTick();

    wrapper.vm.onSend();

    expect(wrapper.emitted('onSend')).toBeUndefined();
  });

  it('allows sending buttons once the header image is confirmed valid on non-Instagram channels', async () => {
    const wrapper = mountComponent(false);
    wrapper.vm.selectedType = CONTENT_TYPES.INTERACTIVE_BUTTONS;
    wrapper.vm.buttonsForm = {
      bodyText: 'Choose an option',
      footerText: '',
      headerMediaUrl: 'https://example.com/header.jpg',
      buttons: [{ id: 'btn_1', text: 'Option A' }],
    };
    wrapper.vm.isButtonsHeaderImageValid = true;
    await nextTick();

    wrapper.vm.onSend();

    expect(wrapper.emitted('onSend')).toHaveLength(1);
  });

  it('blocks sending a list with a section title over the WhatsApp limit', async () => {
    const wrapper = mountComponent(false, true);
    wrapper.vm.selectedType = CONTENT_TYPES.INTERACTIVE_LIST;
    wrapper.vm.listForm = {
      bodyText: 'Pick an item',
      headerText: '',
      footerText: '',
      listButtonText: 'View options',
      sections: [
        {
          title: 'T'.repeat(25),
          rows: [{ title: 'Row A', description: '' }],
        },
      ],
    };
    await nextTick();

    wrapper.vm.onSend();

    expect(wrapper.emitted('onSend')).toBeUndefined();
  });

  it('allows sending a list with a section title within the WhatsApp limit', async () => {
    const wrapper = mountComponent(false, true);
    wrapper.vm.selectedType = CONTENT_TYPES.INTERACTIVE_LIST;
    wrapper.vm.listForm = {
      bodyText: 'Pick an item',
      headerText: '',
      footerText: '',
      listButtonText: 'View options',
      sections: [
        {
          title: 'T'.repeat(24),
          rows: [{ title: 'Row A', description: '' }],
        },
      ],
    };
    await nextTick();

    wrapper.vm.onSend();

    expect(wrapper.emitted('onSend')).toHaveLength(1);
  });

  it('resets away from interactive_list when the channel stops allowing it', async () => {
    const wrapper = mountComponent(false, true);
    wrapper.vm.selectedType = CONTENT_TYPES.INTERACTIVE_LIST;
    await nextTick();

    await wrapper.setProps({ allowListType: false });

    expect(wrapper.vm.selectedType).toBe(CONTENT_TYPES.CTA_URL);
  });

  it('keeps interactive_list selected while the channel still allows it', async () => {
    const wrapper = mountComponent(false, true);
    wrapper.vm.selectedType = CONTENT_TYPES.INTERACTIVE_LIST;
    await nextTick();

    await wrapper.setProps({ allowListType: true });

    expect(wrapper.vm.selectedType).toBe(CONTENT_TYPES.INTERACTIVE_LIST);
  });
});
