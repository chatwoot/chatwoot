import { shallowMount, createLocalVue } from '@vue/test-utils';
import aiMixin from '../aiMixin';
import Vuex from 'vuex';
import OpenAPI from '../../api/integrations/openapi';
import { LocalStorage } from '../../../shared/helpers/localStorage';

jest.mock('../../api/integrations/openapi');
jest.mock('../../../shared/helpers/localStorage');

const localVue = createLocalVue();
localVue.use(Vuex);

describe('aiMixin', () => {
  let wrapper;
  let getters;
  let emptyGetters;
  let component;
  let actions;

  beforeEach(() => {
    OpenAPI.processEvent = jest.fn();
    LocalStorage.set = jest.fn();
    LocalStorage.get = jest.fn();

    actions = {
      ['integrations/get']: jest.fn(),
    };

    getters = {
      ['integrations/getAppIntegrations']: () => [
        {
          id: 'openai',
          hooks: [{ id: 'hook1' }],
        },
      ],
    };

    component = {
      render() {},
      title: 'TestComponent',
      mixins: [aiMixin],
    };

    wrapper = shallowMount(component, {
      store: new Vuex.Store({
        getters: getters,
        actions,
      }),
      localVue,
    });

    emptyGetters = {
      ['integrations/getAppIntegrations']: () => [],
    };
  });

  it('fetches integrations if required', async () => {
    wrapper = shallowMount(component, {
      store: new Vuex.Store({
        getters: emptyGetters,
        actions,
      }),
      localVue,
    });

    const dispatchSpy = jest.spyOn(wrapper.vm.$store, 'dispatch');
    await wrapper.vm.fetchIntegrationsIfRequired();
    expect(dispatchSpy).toHaveBeenCalledWith('integrations/get');
  });

  it('does not fetch integrations', async () => {
    const dispatchSpy = jest.spyOn(wrapper.vm.$store, 'dispatch');
    await wrapper.vm.fetchIntegrationsIfRequired();
    expect(dispatchSpy).not.toHaveBeenCalledWith('integrations/get');
    expect(wrapper.vm.isAIIntegrationEnabled).toBeTruthy();
  });

  it('fetches label suggestions', async () => {
    const processEventSpy = jest.spyOn(OpenAPI, 'processEvent');
    await wrapper.vm.fetchLabelSuggestions({
      conversationId: '123',
    });

    expect(processEventSpy).toHaveBeenCalledWith({
      type: 'label_suggestion',
      hookId: 'hook1',
      conversationId: '123',
    });
  });

  it('gets dismissed conversations', () => {
    const getSpy = jest.spyOn(LocalStorage, 'get');
    const setSpy = jest.spyOn(LocalStorage, 'set');

    const accountId = 123;
    const valueFromStorage = { [accountId]: ['conv1', 'conv2'] };

    // in case key is not initialized
    getSpy.mockReturnValueOnce(null);
    wrapper.vm.getDismissedConversations(accountId);

    expect(getSpy).toHaveBeenCalledWith('dismissedLabelSuggestions');
    expect(setSpy).toHaveBeenCalledWith('dismissedLabelSuggestions', {
      [accountId]: [],
    });

    // rest spy
    getSpy.mockReset();
    setSpy.mockReset();

    // in case we get the value from storage
    getSpy.mockReturnValueOnce(valueFromStorage);
    const result = wrapper.vm.getDismissedConversations(accountId);
    expect(result).toEqual(valueFromStorage);
    expect(getSpy).toHaveBeenCalledWith('dismissedLabelSuggestions');
    expect(setSpy).not.toHaveBeenCalled();

    // rest spy
    getSpy.mockReset();
    setSpy.mockReset();

    // in case we get the value from storage but accountId is not present
    getSpy.mockReturnValueOnce(valueFromStorage);
    wrapper.vm.getDismissedConversations(234);
    expect(getSpy).toHaveBeenCalledWith('dismissedLabelSuggestions');
    expect(setSpy).toHaveBeenCalledWith('dismissedLabelSuggestions', {
      ...valueFromStorage,
      234: [],
    });
  });

  it('cleans labels', () => {
    const labels = 'label1, label2, label1';
    expect(wrapper.vm.cleanLabels(labels)).toEqual(['label1', 'label2']);
  });
});
