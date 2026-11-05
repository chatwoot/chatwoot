import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import HeadersConfig from './HeadersConfig.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

const mountHeaders = (headers = {}) =>
  mount(HeadersConfig, {
    props: {
      headers,
      'onUpdate:headers': value => value,
    },
  });

const lastEmittedHeaders = wrapper =>
  wrapper.emitted('update:headers').at(-1)[0];

describe('HeadersConfig', () => {
  it('renders a row for each existing header', () => {
    const wrapper = mountHeaders({
      Accept: 'application/json',
      'X-Tenant': 'acme',
    });

    const inputs = wrapper.findAll('input');
    expect(inputs.map(input => input.element.value)).toEqual([
      'Accept',
      'application/json',
      'X-Tenant',
      'acme',
    ]);
  });

  it('emits headers as an object when a row is added and filled', async () => {
    const wrapper = mountHeaders();

    await wrapper.find('[data-test="add-header"]').trigger('click');
    const [name, value] = wrapper.findAll('input');
    await name.setValue(' X-Tenant ');
    await value.setValue('acme');

    expect(lastEmittedHeaders(wrapper)).toEqual({ 'X-Tenant': 'acme' });
  });

  it('removes a header', async () => {
    const wrapper = mountHeaders({
      Accept: 'application/json',
      'X-Tenant': 'acme',
    });

    await wrapper.findAll('[data-test="remove-header"]')[0].trigger('click');

    expect(lastEmittedHeaders(wrapper)).toEqual({ 'X-Tenant': 'acme' });
  });

  it('only marks the name invalid after a failed validation', async () => {
    const wrapper = mountHeaders();

    await wrapper.find('[data-test="add-header"]').trigger('click');
    const nameInput = () => wrapper.findAll('input')[0];
    expect(nameInput().classes()).not.toContain('error');

    await wrapper.findAll('input')[1].setValue('orphan');
    wrapper.vm.validate();
    await nextTick();
    expect(nameInput().classes()).toContain('error');

    await nameInput().setValue('hello-world');
    expect(nameInput().classes()).not.toContain('error');
  });

  it('flags header names that repeat, ignoring case', async () => {
    const wrapper = mountHeaders();

    await wrapper.find('[data-test="add-header"]').trigger('click');
    await wrapper.find('[data-test="add-header"]').trigger('click');
    const inputs = wrapper.findAll('input');
    await inputs[0].setValue('X-Tenant');
    await inputs[1].setValue('a');
    await inputs[2].setValue(' x-tenant ');
    await inputs[3].setValue('b');

    expect(wrapper.vm.validate()).toBe(false);
    await nextTick();
    expect(wrapper.text().match(/NAME_DUPLICATE/g)).toHaveLength(2);
  });

  it('ignores empty rows and flags a value without a name', async () => {
    const wrapper = mountHeaders();

    await wrapper.find('[data-test="add-header"]').trigger('click');
    expect(wrapper.vm.validate()).toBe(true);

    await wrapper.findAll('input')[1].setValue('orphan');
    await nextTick();

    expect(lastEmittedHeaders(wrapper)).toEqual({});
    expect(wrapper.vm.validate()).toBe(false);
  });
});
