import { createWrapper } from '@vue/test-utils';
import webhookMixin from '../webhookMixin';
import Vue from 'vue';

describe('webhookMixin', () => {
  describe('#getEventLabel', () => {
    it('returns correct i18n translation:', () => {
      const Component = {
        render() {},
        title: 'WebhookComponent',
        mixins: [webhookMixin],
        methods: {
          $t(text) {
            return text;
          },
        },
      };
      const Constructor = Vue.extend(Component);
      const vm = new Constructor().$mount();
      const wrapper = createWrapper(vm);
      expect(wrapper.vm.getEventLabel('message_created')).toEqual(
        `INTEGRATION_SETTINGS.WEBHOOK.FORM.SUBSCRIPTIONS.EVENTS.MESSAGE_CREATED`
      );
    });
  });
});
