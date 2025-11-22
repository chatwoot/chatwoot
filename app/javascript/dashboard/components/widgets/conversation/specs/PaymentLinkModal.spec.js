import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import PaymentLinkModal from '../PaymentLinkModal.vue';
import WootModal from 'dashboard/components/Modal.vue';
import WootModalHeader from 'dashboard/components/ModalHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const mockCurrentChat = {
  id: 1,
  display_id: 123,
  meta: {
    sender: {
      id: 10,
      name: 'John Doe',
      email: 'john@example.com',
      phone_number: '+96512345678',
    },
  },
};

const store = createStore({
  modules: {
    auth: {
      namespaced: false,
      getters: {
        getCurrentAccountId: () => 1,
        getCurrentUser: () => ({ id: 1, name: 'Agent' }),
      },
    },
  },
});

describe('PaymentLinkModal', () => {
  let wrapper = null;

  const createWrapper = (props = {}) => {
    return mount(PaymentLinkModal, {
      global: {
        plugins: [store],
        components: {
          'woot-modal': WootModal,
          'woot-modal-header': WootModalHeader,
          'next-button': NextButton,
        },
        stubs: {
          WootModalHeader: false,
        },
      },
      props: {
        show: true,
        currentChat: mockCurrentChat,
        isSubmitting: false,
        ...props,
      },
    });
  };

  beforeEach(() => {
    wrapper = createWrapper();
  });

  afterEach(() => {
    wrapper.unmount();
  });

  it('renders modal with correct title', () => {
    const headerComponent = wrapper.findComponent(WootModalHeader);
    const title = headerComponent.find('[data-test-id="modal-header-title"]');
    expect(title.text()).toBe('Generate Payment Link');
  });

  it('pre-fills customer information from currentChat', async () => {
    await wrapper.vm.$nextTick();

    expect(wrapper.vm.customerName).toBe('John Doe');
    expect(wrapper.vm.customerEmail).toBe('john@example.com');
    expect(wrapper.vm.customerPhone).toBe('+96512345678');
  });

  it('handles missing contact data gracefully', async () => {
    const wrapperNoContact = createWrapper({
      currentChat: { id: 1, meta: {} },
    });

    await wrapperNoContact.vm.$nextTick();

    expect(wrapperNoContact.vm.customerName).toBe('');
    expect(wrapperNoContact.vm.customerEmail).toBe('');
    expect(wrapperNoContact.vm.customerPhone).toBe('');

    wrapperNoContact.unmount();
  });

  it('validates amount field is required', async () => {
    const amountInput = wrapper.find('input[type="number"]');
    await amountInput.setValue('');
    await amountInput.trigger('input');

    expect(wrapper.vm.v$.amount.$error).toBe(true);
    expect(wrapper.vm.isFormValid).toBe(false);
  });

  it('validates amount must be positive', async () => {
    const amountInput = wrapper.find('input[type="number"]');
    await amountInput.setValue('-10');
    await amountInput.trigger('input');

    expect(wrapper.vm.v$.amount.$error).toBe(true);
    expect(wrapper.vm.isFormValid).toBe(false);
  });

  it('has correct currency options', () => {
    expect(wrapper.vm.currencies).toEqual([
      { value: 'KWD', label: 'KWD - Kuwaiti Dinar' },
      { value: 'USD', label: 'USD - US Dollar' },
      { value: 'SAR', label: 'SAR - Saudi Riyal' },
      { value: 'AED', label: 'AED - UAE Dirham' },
      { value: 'EUR', label: 'EUR - Euro' },
      { value: 'GBP', label: 'GBP - British Pound' },
    ]);
  });

  it('defaults currency to KWD', () => {
    expect(wrapper.vm.currency).toBe('KWD');
  });

  it('emits submit event with correct data structure', async () => {
    await wrapper.vm.$nextTick();

    wrapper.vm.amount = '100.50';
    wrapper.vm.currency = 'USD';
    wrapper.vm.customerName = 'John Doe';
    wrapper.vm.customerEmail = 'john@example.com';
    wrapper.vm.customerPhone = '+96512345678';

    await wrapper.vm.onSubmit();

    expect(wrapper.emitted('submit')).toBeTruthy();
    expect(wrapper.emitted('submit')[0]).toEqual([
      {
        amount: 100.5,
        currency: 'USD',
        customer: {
          name: 'John Doe',
          email: 'john@example.com',
          phone: '+96512345678',
        },
      },
    ]);
  });

  it('does not submit when form is invalid', async () => {
    wrapper.vm.amount = '';
    await wrapper.vm.$nextTick();

    await wrapper.vm.onSubmit();

    expect(wrapper.emitted('submit')).toBeFalsy();
  });

  it('emits cancel event and resets form', async () => {
    wrapper.vm.amount = '50';
    wrapper.vm.currency = 'SAR';

    await wrapper.vm.onCancel();

    expect(wrapper.emitted('cancel')).toBeTruthy();
    expect(wrapper.vm.amount).toBe('');
    expect(wrapper.vm.currency).toBe('KWD');
  });

  it('updates customer info when currentChat changes', async () => {
    const newChat = {
      ...mockCurrentChat,
      meta: {
        sender: {
          id: 20,
          name: 'Jane Smith',
          email: 'jane@example.com',
          phone_number: '+96587654321',
        },
      },
    };

    await wrapper.setProps({ currentChat: newChat });
    await wrapper.vm.$nextTick();

    expect(wrapper.vm.customerName).toBe('Jane Smith');
    expect(wrapper.vm.customerEmail).toBe('jane@example.com');
    expect(wrapper.vm.customerPhone).toBe('+96587654321');
  });
});
