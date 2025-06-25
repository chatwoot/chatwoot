import { createWrapper } from '@vue/test-utils';
import macrosMixin from '../macrosMixin';
import Vue from 'vue';
import { teams, labels, agents } from '../../helper/specs/macrosFixtures';
import { PRIORITY_CONDITION_VALUES } from 'dashboard/helper/automationHelper.js';
describe('webhookMixin', () => {
  describe('#getEventLabel', () => {
    it('returns correct i18n translation:', () => {
      const Component = {
        render() {},
        title: 'MyComponent',
        mixins: [macrosMixin],
        data: () => {
          return {
            teams,
            labels,
            agents,
          };
        },
        methods: {
          $t(text) {
            return text;
          },
        },
      };

      const resolvedLabels = labels.map(i => {
        return {
          id: i.title,
          name: i.title,
        };
      });

      const Constructor = Vue.extend(Component);
      const vm = new Constructor().$mount();
      const wrapper = createWrapper(vm);
      expect(wrapper.vm.getDropdownValues('assign_team')).toEqual(teams);
      expect(wrapper.vm.getDropdownValues('send_email_to_team')).toEqual(teams);
      expect(wrapper.vm.getDropdownValues('add_label')).toEqual(resolvedLabels);
      expect(wrapper.vm.getDropdownValues('assign_agent')).toEqual(agents);
      expect(wrapper.vm.getDropdownValues('change_priority')).toEqual(
        PRIORITY_CONDITION_VALUES
      );
      expect(wrapper.vm.getDropdownValues()).toEqual([]);
    });
  });
});
