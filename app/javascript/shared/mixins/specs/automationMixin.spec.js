import methodsMixin from '../../../dashboard/mixins/automations/methodsMixin';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import AddAutomationRule from '../../../dashboard/routes/dashboard/settings/automation/AddAutomationRule.vue';
import { action, files, customAttributes } from './automationFixtures';
import VueI18n from 'vue-i18n';
import Vuex from 'vuex';
import i18n from 'dashboard/i18n';
const localVue = createLocalVue();

localVue.use(VueI18n);
localVue.use(Vuex);

const i18nConfig = new VueI18n({
  locale: 'en',
  messages: i18n,
});

describe('Automation Mixin function', () => {
  let addAutomationRule = null;
  let getters = null;
  let store = null;

  beforeEach(() => {
    getters = {
      'attributes/getAttributesByModel': () => customAttributes,
    };
    store = new Vuex.Store({
      getters,
    });

    addAutomationRule = shallowMount(AddAutomationRule, {
      localVue,
      i18n: i18nConfig,
      mixins: [methodsMixin],
      store,
    });
  });

  it('getFileName returns the correct file name', () => {
    expect(addAutomationRule.vm.getFileName(action, files)).toBeTruthy();
  });
});
