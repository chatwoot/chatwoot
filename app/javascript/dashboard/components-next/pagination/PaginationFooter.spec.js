import { mount } from '@vue/test-utils';
import PaginationFooter from './PaginationFooter.vue';

const createWrapper = (props = {}) =>
  mount(PaginationFooter, {
    props: {
      currentPage: 1,
      totalItems: 100,
      itemsPerPage: 15,
      ...props,
    },
  });

describe('PaginationFooter', () => {
  describe('pagination info', () => {
    it('shows the correct item range for the first page', () => {
      const wrapper = createWrapper({
        currentPage: 1,
        totalItems: 100,
        itemsPerPage: 15,
      });
      expect(wrapper.text()).toContain('1');
      expect(wrapper.text()).toContain('15');
      expect(wrapper.text()).toContain('100');
    });

    it('shows the correct item range for a mid page', () => {
      const wrapper = createWrapper({
        currentPage: 2,
        totalItems: 100,
        itemsPerPage: 15,
      });
      expect(wrapper.text()).toContain('16');
      expect(wrapper.text()).toContain('30');
    });

    it('caps the end item at totalItems on the last page', () => {
      const wrapper = createWrapper({
        currentPage: 7,
        totalItems: 100,
        itemsPerPage: 15,
      });
      expect(wrapper.text()).toContain('100');
    });
  });

  describe('page navigation', () => {
    it('disables first/prev buttons on the first page', () => {
      const wrapper = createWrapper({ currentPage: 1, totalItems: 50 });
      const buttons = wrapper.findAll('button');
      expect(buttons[0].element.disabled).toBe(true);
      expect(buttons[1].element.disabled).toBe(true);
    });

    it('disables next/last buttons on the last page', () => {
      const wrapper = createWrapper({
        currentPage: 4,
        totalItems: 50,
        itemsPerPage: 15,
      });
      const buttons = wrapper.findAll('button');
      expect(buttons[2].element.disabled).toBe(true);
      expect(buttons[3].element.disabled).toBe(true);
    });

    it('emits update:currentPage when a navigation button is clicked', async () => {
      const wrapper = createWrapper({ currentPage: 2, totalItems: 50 });
      const buttons = wrapper.findAllComponents({ name: 'Button' });
      await buttons[1].trigger('click'); // prev
      expect(wrapper.emitted('update:currentPage')).toBeTruthy();
      expect(wrapper.emitted('update:currentPage')[0]).toEqual([1]);
    });

    it('does not emit update:currentPage when already on first page and prev is clicked', async () => {
      const wrapper = createWrapper({ currentPage: 1, totalItems: 50 });
      const buttons = wrapper.findAllComponents({ name: 'Button' });
      await buttons[1].trigger('click');
      expect(wrapper.emitted('update:currentPage')).toBeFalsy();
    });
  });

  describe('page size selector', () => {
    it('does not render the selector by default', () => {
      const wrapper = createWrapper();
      expect(wrapper.find('select').exists()).toBe(false);
    });

    it('renders the selector when showPageSizeSelector is true', () => {
      const wrapper = createWrapper({ showPageSizeSelector: true });
      expect(wrapper.find('select').exists()).toBe(true);
    });

    it('shows all allowed page size options', () => {
      const wrapper = createWrapper({ showPageSizeSelector: true });
      const options = wrapper.findAll('option');
      expect(options.map(o => Number(o.element.value))).toEqual([
        15, 50, 100, 250, 500,
      ]);
    });

    it('reflects the current itemsPerPage as the selected option', () => {
      const wrapper = createWrapper({
        showPageSizeSelector: true,
        itemsPerPage: 50,
      });
      expect(wrapper.find('select').element.value).toBe('50');
    });

    it('emits update:itemsPerPage when a different size is selected', async () => {
      const wrapper = createWrapper({
        showPageSizeSelector: true,
        itemsPerPage: 15,
      });
      const select = wrapper.find('select');
      await select.setValue('50');
      expect(wrapper.emitted('update:itemsPerPage')).toBeTruthy();
      expect(wrapper.emitted('update:itemsPerPage')[0]).toEqual([50]);
    });

    it('does not emit update:itemsPerPage when the same size is selected', async () => {
      const wrapper = createWrapper({
        showPageSizeSelector: true,
        itemsPerPage: 15,
      });
      const select = wrapper.find('select');
      await select.setValue('15');
      expect(wrapper.emitted('update:itemsPerPage')).toBeFalsy();
    });
  });
});
