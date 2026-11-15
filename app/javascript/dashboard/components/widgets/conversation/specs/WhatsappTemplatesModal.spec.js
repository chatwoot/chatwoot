import { shallowMount } from '@vue/test-utils';
import WhatsappTemplates from '../WhatsappTemplates/Modal.vue';

const TEMPLATE = { name: 'follow_up', components: [] };

const mountModal = (props = {}) =>
  shallowMount(WhatsappTemplates, {
    props: { show: true, inboxId: 1, ...props },
    global: { mocks: { $t: key => key } },
  });

describe('WhatsappTemplates modal', () => {
  it('keeps the selected template when the modal is closed and reopened', async () => {
    const wrapper = mountModal();
    wrapper.vm.pickTemplate(TEMPLATE);

    await wrapper.setProps({ show: false });
    await wrapper.setProps({ show: true });

    expect(wrapper.vm.selectedWaTemplate).toEqual(TEMPLATE);
  });

  it('clears the selected template when the inbox changes', async () => {
    const wrapper = mountModal();
    wrapper.vm.pickTemplate(TEMPLATE);

    await wrapper.setProps({ inboxId: 2 });

    expect(wrapper.vm.selectedWaTemplate).toBeNull();
  });

  it('clears the selected template when switching to contact info requests', async () => {
    const wrapper = mountModal();
    wrapper.vm.pickTemplate(TEMPLATE);

    await wrapper.setProps({ requestContactInfoOnly: true });

    expect(wrapper.vm.selectedWaTemplate).toBeNull();
  });
});
