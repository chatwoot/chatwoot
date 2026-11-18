import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import TranslationToggle from '../TranslationToggle.vue';
import { provideMessageContext } from '../provider.js';
import { MESSAGE_TYPES } from '../constants';

const translation = vi.hoisted(() => ({ present: false }));
const storeGetters = vi.hoisted(() => ({}));

vi.mock('dashboard/composables/store', async () => {
  const { computed } = await import('vue');
  return { useMapGetter: key => computed(() => storeGetters[key]) };
});
vi.mock('dashboard/composables/useTranslations', async () => {
  const { ref: makeRef } = await import('vue');
  return {
    useTranslations: () => ({
      hasTranslations: makeRef(translation.present),
      translationContent: makeRef(''),
    }),
  };
});

const mountToggle = ({
  messageType = MESSAGE_TYPES.INCOMING,
  contactSide = messageType === MESSAGE_TYPES.INCOMING,
  hasTranslations = false,
  language = 'French',
  state = {},
  showingOriginal = false,
} = {}) => {
  translation.present = hasTranslations;
  Object.assign(storeGetters, {
    getAutoTranslate: { language, agentLanguage: 'English' },
    getMessageTranslationState: () => ({
      pending: false,
      sameLanguage: false,
      ...state,
    }),
    getSelectedChatAttachments: [],
  });
  const Host = defineComponent({
    components: { TranslationToggle },
    setup() {
      provideMessageContext({
        id: ref(1),
        contentAttributes: ref({}),
        messageType: ref(messageType),
        contactSide: ref(contactSide),
      });
    },
    template: `<TranslationToggle :showing-original="${showingOriginal}" />`,
  });

  return mount(Host, {
    global: { stubs: { Icon: { template: '<i data-icon />' } } },
  });
};

describe('TranslationToggle', () => {
  it('offers the original text for a translated incoming message', () => {
    const wrapper = mountToggle({ hasTranslations: true });

    expect(wrapper.text()).toBe('CONVERSATION.VIEW_ORIGINAL_IN');
    expect(wrapper.find('[data-icon]').exists()).toBe(true);
  });

  it('offers the translation once the original is shown', () => {
    const wrapper = mountToggle({
      hasTranslations: true,
      showingOriginal: true,
    });

    expect(wrapper.text()).toBe('CONVERSATION.VIEW_TRANSLATED_IN');
  });

  it('reads a bot reply in the contact direction', () => {
    const wrapper = mountToggle({
      hasTranslations: true,
      messageType: MESSAGE_TYPES.OUTGOING,
      contactSide: true,
      state: { sourceLanguage: 'French' },
    });

    expect(wrapper.text()).toBe('CONVERSATION.VIEW_ORIGINAL_IN');
  });

  it('describes a reply that went out translated', () => {
    const wrapper = mountToggle({
      hasTranslations: true,
      messageType: MESSAGE_TYPES.OUTGOING,
    });

    expect(wrapper.text()).toBe('CONVERSATION.VIEW_TRANSLATED_IN');
  });

  it('shows the in-progress label instead of the toggle', () => {
    const incoming = mountToggle({ state: { pending: true } });
    const outgoing = mountToggle({
      state: { pending: true },
      messageType: MESSAGE_TYPES.OUTGOING,
    });

    expect(incoming.text()).toContain('CONVERSATION.TRANSLATING');
    expect(incoming.text()).not.toContain('CONVERSATION.VIEW_ORIGINAL');
    expect(outgoing.text()).toContain('CONVERSATION.TRANSLATING_TO');
  });

  it('shows nothing for a message already in the agent language', () => {
    const wrapper = mountToggle({
      hasTranslations: true,
      state: { sameLanguage: true },
    });

    expect(wrapper.find('span').exists()).toBe(false);
  });

  it('warns when a reply could not be translated', () => {
    const wrapper = mountToggle({
      messageType: MESSAGE_TYPES.OUTGOING,
      state: { failed: true },
    });

    expect(wrapper.text()).toBe('CONVERSATION.TRANSLATION_FAILED');
  });

  it('keeps the plain toggle when auto translate is off', () => {
    const wrapper = mountToggle({ hasTranslations: true, language: '' });

    expect(wrapper.text()).toBe('CONVERSATION.VIEW_ORIGINAL');
    expect(wrapper.find('[data-icon]').exists()).toBe(false);
  });

  it('renders nothing for an untranslated message', () => {
    expect(mountToggle().find('span').exists()).toBe(false);
  });

  it('emits toggle when the action is clicked', async () => {
    const wrapper = mountToggle({ hasTranslations: true });

    await wrapper.find('.cursor-pointer').trigger('click');

    expect(
      wrapper.findComponent(TranslationToggle).emitted('toggle')
    ).toHaveLength(1);
  });
});
