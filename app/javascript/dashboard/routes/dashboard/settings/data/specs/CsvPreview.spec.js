import { mount } from '@vue/test-utils';
import CsvPreview from '../CsvPreview.vue';

const csv = contents =>
  new File([contents], 'contacts.csv', { type: 'text/csv' });

describe('CsvPreview', () => {
  it('previews five logical records and replaces them when a different file is selected', async () => {
    const file = csv(
      'name,email\n"Doe, Jane",a@example.com\n"Two\nlines",b@example.com\nC,c@example.com\nD,d@example.com\nE,e@example.com\nF,f@example.com'
    );
    const wrapper = mount(CsvPreview, {
      props: { file },
      global: { mocks: { $t: key => key } },
    });
    await vi.waitFor(() => expect(wrapper.findAll('tbody tr')).toHaveLength(5));
    expect(wrapper.findAll('tbody tr')[0].text()).toContain('Doe, Jane');
    expect(wrapper.findAll('tbody tr')[1].text()).toContain('Two\nlines');
    expect(wrapper.text()).not.toContain('f@example.com');

    await wrapper.setProps({ file: csv('name\nReplacement') });
    await vi.waitFor(() => expect(wrapper.findAll('tbody tr')).toHaveLength(1));
    expect(wrapper.text()).toContain('Replacement');
    wrapper.unmount();
  });
});
