import automationMixin from '../automationMixin';
import { shallowMount } from '@vue/test-utils';
import MockComponent from './MockComponent.vue';

describe('Automation Mixin function', () => {
  const wrapper = shallowMount(MockComponent, {
    mixins: [automationMixin],
  });

  it('customAttributeInputType should be defined', () => {
    expect(wrapper.vm.customAttributeInputType).toBeTruthy();
  });
  it('onEventChange should be defined', () => {
    expect(wrapper.vm.onEventChange).toBeTruthy();
  });
  it('getAttributes should be defined', () => {
    expect(wrapper.vm.getAttributes).toBeTruthy();
  });
  it('isACustomAttribute should be defined', () => {
    expect(wrapper.vm.isACustomAttribute).toBeTruthy();
  });
  it('getOperators should be defined', () => {
    expect(wrapper.vm.getOperators).toBeTruthy();
  });
  it('getConditionDropdownValues should be defined', () => {
    expect(wrapper.vm.getConditionDropdownValues).toBeTruthy();
  });
  it('appendNewCondition should be defined', () => {
    expect(wrapper.vm.appendNewCondition).toBeTruthy();
  });
  it('appendNewAction should be defined', () => {
    expect(wrapper.vm.appendNewAction).toBeTruthy();
  });
  it('removeFilter should be defined', () => {
    expect(wrapper.vm.removeFilter).toBeTruthy();
  });
  it('removeAction should be defined', () => {
    expect(wrapper.vm.removeAction).toBeTruthy();
  });
  it('submitAutomation should be defined', () => {
    expect(wrapper.vm.submitAutomation).toBeTruthy();
  });
  it('resetFilter should be defined', () => {
    expect(wrapper.vm.resetFilter).toBeTruthy();
  });
  it('showUserInput should be defined', () => {
    expect(wrapper.vm.showUserInput).toBeTruthy();
  });
  it('showActionInput should be defined', () => {
    expect(wrapper.vm.showActionInput).toBeTruthy();
  });
  it('resetAction should be defined', () => {
    expect(wrapper.vm.resetAction).toBeTruthy();
  });
  it('formatAutomation should be defined', () => {
    expect(wrapper.vm.formatAutomation).toBeTruthy();
  });
  it('getOperatorTypes should be defined', () => {
    expect(wrapper.vm.getOperatorTypes).toBeTruthy();
  });
  it('getFileName should be defined', () => {
    expect(wrapper.vm.getFileName).toBeTruthy();
  });
  it('getActionDropdownValues should be defined', () => {
    expect(wrapper.vm.getActionDropdownValues).toBeTruthy();
  });
  it('manifestCustomAttributes should be defined', () => {
    expect(wrapper.vm.manifestCustomAttributes).toBeTruthy();
  });
});
