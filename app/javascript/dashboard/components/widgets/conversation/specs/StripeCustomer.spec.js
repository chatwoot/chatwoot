import { mount, flushPromises } from '@vue/test-utils';
import StripeCustomer from '../StripeCustomer.vue';
import StripeAPI from 'dashboard/api/integrations/stripe';

vi.mock('dashboard/api/integrations/stripe', () => ({
  default: { customer: vi.fn() },
}));

describe('StripeCustomer', () => {
  const customer = {
    id: 'cus_alfred',
    name: 'Alfred',
    email: 'alfred@example.com',
  };
  const data = {
    customers: [customer],
    customer,
    subscriptions: [{ id: 'sub_test', status: 'active' }],
    invoices: [
      {
        id: 'in_test',
        number: 'INV-001',
        total: 1000,
        currency: 'usd',
        status: 'paid',
        created: 1788998400,
      },
    ],
  };
  let wrapper;

  afterEach(() => wrapper?.unmount());

  it('renders customer billing details without a refresh button', async () => {
    StripeAPI.customer.mockResolvedValue({ data });
    wrapper = mount(StripeCustomer, { props: { conversationId: 1 } });
    await flushPromises();
    expect(wrapper.text()).toContain('Alfred');
    expect(wrapper.text()).toContain('INV-001');
    expect(wrapper.text()).toContain('$10.00');
    expect(wrapper.text()).toContain('paid');
    expect(wrapper.find('button').exists()).toBe(false);
  });

  it('shows the no-email state', async () => {
    StripeAPI.customer.mockResolvedValue({
      data: { customers: [], missing_email: true },
    });
    wrapper = mount(StripeCustomer, { props: { conversationId: 1 } });
    await flushPromises();
    expect(wrapper.text()).toContain('STRIPE_INTEGRATION.NO_EMAIL');
  });

  it('lets the agent select between customers sharing the same email', async () => {
    StripeAPI.customer.mockResolvedValueOnce({
      data: { customers: [customer, { ...customer, id: 'cus_second' }] },
    });
    wrapper = mount(StripeCustomer, { props: { conversationId: 1 } });
    await flushPromises();
    StripeAPI.customer.mockResolvedValueOnce({ data });
    await wrapper.get('select').setValue('cus_alfred');
    await flushPromises();
    expect(StripeAPI.customer).toHaveBeenLastCalledWith(
      1,
      'cus_alfred',
      expect.any(AbortSignal)
    );
    expect(wrapper.text()).toContain('INV-001');
  });

  it('clears the previous customer when switching to an unmatched conversation', async () => {
    StripeAPI.customer.mockResolvedValueOnce({ data });
    wrapper = mount(StripeCustomer, { props: { conversationId: 1 } });
    await flushPromises();
    StripeAPI.customer.mockResolvedValueOnce({ data: { customers: [] } });
    await wrapper.setProps({ conversationId: 2 });
    await flushPromises();
    expect(StripeAPI.customer).toHaveBeenLastCalledWith(
      2,
      undefined,
      expect.any(AbortSignal)
    );
    expect(wrapper.text()).not.toContain('Alfred');
    expect(wrapper.text()).toContain('STRIPE_INTEGRATION.EMPTY');
  });

  it('shows an error without exposing the previous customer', async () => {
    StripeAPI.customer.mockResolvedValueOnce({ data });
    wrapper = mount(StripeCustomer, { props: { conversationId: 1 } });
    await flushPromises();
    StripeAPI.customer.mockRejectedValueOnce(
      new Error('private provider error')
    );
    await wrapper.setProps({ conversationId: 2 });
    await flushPromises();
    expect(wrapper.get('[role="alert"]').text()).toContain(
      'STRIPE_INTEGRATION.ERROR'
    );
    expect(wrapper.text()).not.toContain('Alfred');
    expect(wrapper.text()).not.toContain('private provider error');
  });

  it.each([
    ['jpy', 1000, '1,000'],
    ['isk', 1000, '10'],
  ])('formats %s using Stripe minor units', async (currency, total, amount) => {
    StripeAPI.customer.mockResolvedValue({
      data: { ...data, invoices: [{ ...data.invoices[0], currency, total }] },
    });
    wrapper = mount(StripeCustomer, { props: { conversationId: 1 } });
    await flushPromises();
    expect(wrapper.get('.tabular-nums').text()).toContain(amount);
  });
});
