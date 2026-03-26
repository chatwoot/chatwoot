/* eslint-disable vue/one-component-per-file, vue/no-reserved-component-names, vue/no-unused-properties, vue/no-unused-emit-declarations */
import { defineComponent, h, ref } from 'vue';
import { flushPromises, shallowMount } from '@vue/test-utils';
import { describe, expect, it, vi, beforeEach } from 'vitest';
import VoiceCallButton from '../VoiceCallButton.vue';

const mocks = vi.hoisted(() => {
  const useStore = vi.fn();
  const useMapGetter = vi.fn();
  const useAlert = vi.fn();
  const useCallsStore = vi.fn();
  const useRoute = vi.fn();
  const useRouter = vi.fn();
  const useI18n = vi.fn();

  return {
    useStore,
    useMapGetter,
    useAlert,
    useCallsStore,
    useRoute,
    useRouter,
    useI18n,
  };
});

const dialogOpen = vi.fn();
const dialogClose = vi.fn();

const ButtonStub = defineComponent({
  name: 'Button',
  props: {
    label: { type: String, default: '' },
    disabled: { type: Boolean, default: false },
    isLoading: { type: Boolean, default: false },
  },
  emits: ['click'],
  template:
    '<button type="button" data-test-id="voice-call-button" :disabled="disabled" @click="$emit(\'click\')">{{ label }}</button>',
});

const DialogStub = defineComponent({
  name: 'Dialog',
  setup(_, { expose, slots }) {
    expose({
      open: dialogOpen,
      close: dialogClose,
    });

    return () =>
      h('div', { 'data-test-id': 'voice-call-dialog' }, slots.default?.());
  },
});

vi.mock('dashboard/composables/store', () => ({
  useStore: mocks.useStore,
  useMapGetter: mocks.useMapGetter,
}));

vi.mock('dashboard/composables', () => ({
  useAlert: mocks.useAlert,
}));

vi.mock('dashboard/stores/calls', () => ({
  useCallsStore: mocks.useCallsStore,
}));

vi.mock('vue-router', () => ({
  useRoute: mocks.useRoute,
  useRouter: mocks.useRouter,
}));

vi.mock('vue-i18n', () => ({
  useI18n: mocks.useI18n,
}));

describe('VoiceCallButton.vue', () => {
  const store = {
    dispatch: vi.fn(),
  };
  const router = {
    push: vi.fn(),
  };
  const callsStore = {
    addCall: vi.fn(),
  };

  const mountSubject = ({
    phone = '+15555550100',
    contactId = 41,
    fixedInboxId = null,
    navigateOnSuccess = true,
    inboxes = [
      { id: 7, channel_type: 'Channel::Voice', name: 'Voice 1' },
      { id: 8, channel_type: 'Channel::Voice', name: 'Voice 2' },
    ],
    isInitiatingCall = false,
  } = {}) => {
    mocks.useStore.mockReturnValue(store);
    mocks.useMapGetter.mockImplementation(key => {
      if (key === 'inboxes/getInboxes') {
        return ref(inboxes);
      }
      if (key === 'contacts/getUIFlags') {
        return ref({ isInitiatingCall });
      }
      return ref(null);
    });
    mocks.useRoute.mockReturnValue({ params: { accountId: 99 } });
    mocks.useRouter.mockReturnValue(router);
    mocks.useCallsStore.mockReturnValue(callsStore);
    mocks.useAlert.mockImplementation(() => {});
    mocks.useI18n.mockReturnValue({ t: key => key });
    router.push.mockReset();
    callsStore.addCall.mockReset();
    dialogOpen.mockReset();
    dialogClose.mockReset();

    return shallowMount(VoiceCallButton, {
      props: {
        phone,
        contactId,
        label: 'Call',
        fixedInboxId,
        navigateOnSuccess,
      },
      global: {
        stubs: {
          Button: ButtonStub,
          Dialog: DialogStub,
        },
      },
    });
  };

  beforeEach(() => {
    vi.clearAllMocks();
    store.dispatch.mockResolvedValue({
      call_sid: 'CS-123',
      conversation_id: 77,
    });
  });

  it('dispatches the fixed inbox call directly and skips the picker', async () => {
    const wrapper = mountSubject({
      fixedInboxId: 12,
      navigateOnSuccess: false,
    });

    await wrapper.find('[data-test-id="voice-call-button"]').trigger('click');
    await flushPromises();

    expect(store.dispatch).toHaveBeenCalledWith('contacts/initiateCall', {
      contactId: 41,
      inboxId: 12,
    });
    expect(dialogOpen).not.toHaveBeenCalled();
    expect(callsStore.addCall).toHaveBeenCalledWith({
      callSid: 'CS-123',
      conversationId: 77,
      inboxId: 12,
      callDirection: 'outbound',
    });
    expect(router.push).not.toHaveBeenCalled();
  });

  it('keeps the loading state wired to the button', () => {
    const wrapper = mountSubject({ isInitiatingCall: true });

    const button = wrapper.find('[data-test-id="voice-call-button"]');
    expect(button.attributes('disabled')).toBeDefined();
  });
});
