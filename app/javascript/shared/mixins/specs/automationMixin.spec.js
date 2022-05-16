import methodsMixin from '../../../dashboard/mixins/automations/methodsMixin';
import { action, files, automation } from './automationFixtures';
import { createWrapper } from '@vue/test-utils';
import Vue from 'vue';

const createComponent = ({ mixins, data }) => {
  const Component = {
    render() {},
    mixins,
    data,
  };
  const Constructor = Vue.extend(Component);
  const vm = new Constructor().$mount();
  return createWrapper(vm);
};

describe('automationMixin', () => {
  it('getFileName returns the correct file name', () => {
    const wrapper = createComponent([methodsMixin]);
    expect(wrapper.vm.getFileName(action, files)).toEqual(files[0].filename);
  });

  it('onEventChange returns the correct file name', () => {
    const data = () => {
      return {
        automation,
      };
    };
    const wrapper = createComponent([methodsMixin], data);
    expect(wrapper.vm.getFileName(action, files)).toEqual(files[0].filename);
  });
});
