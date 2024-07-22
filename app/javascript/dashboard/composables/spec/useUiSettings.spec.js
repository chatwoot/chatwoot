import { ref } from 'vue';
import {
  useUiSettings,
  DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER,
  DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER,
} from '../useUiSettings';

// Mocking the store composables
const mockDispatch = vi.fn();

const getUISettingsMock = ref({
  is_ct_labels_open: true,
  conversation_sidebar_items_order: DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER,
  contact_sidebar_items_order: DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER,
  editor_message_key: 'enter',
});

vi.mock('dashboard/composables/store', () => ({
  useStoreGetters: () => ({
    getUISettings: getUISettingsMock,
  }),
  useStore: () => ({
    dispatch: mockDispatch,
  }),
}));

describe('useUiSettings', () => {
  beforeEach(() => {
    mockDispatch.mockClear();
  });

  it('returns uiSettings', () => {
    const { uiSettings } = useUiSettings();
    expect(uiSettings.value).toEqual({
      is_ct_labels_open: true,
      conversation_sidebar_items_order:
        DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER,
      contact_sidebar_items_order: DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER,
      editor_message_key: 'enter',
    });
  });

  it('updates UI settings correctly', () => {
    const { updateUISettings } = useUiSettings();
    updateUISettings({ enter_to_send_enabled: true });
    expect(mockDispatch).toHaveBeenCalledWith('updateUISettings', {
      uiSettings: {
        enter_to_send_enabled: true,
        is_ct_labels_open: true,
        conversation_sidebar_items_order:
          DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER,
        contact_sidebar_items_order: DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER,
        editor_message_key: 'enter',
      },
    });
  });

  it('toggles sidebar UI state correctly', () => {
    const { toggleSidebarUIState } = useUiSettings();
    toggleSidebarUIState('is_ct_labels_open');
    expect(mockDispatch).toHaveBeenCalledWith('updateUISettings', {
      uiSettings: {
        is_ct_labels_open: false,
        conversation_sidebar_items_order:
          DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER,
        contact_sidebar_items_order: DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER,
        editor_message_key: 'enter',
      },
    });
  });

  it('returns correct conversation sidebar items order', () => {
    const { conversationSidebarItemsOrder } = useUiSettings();
    expect(conversationSidebarItemsOrder.value).toEqual(
      DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER
    );
  });

  it('returns correct contact sidebar items order', () => {
    const { contactSidebarItemsOrder } = useUiSettings();
    expect(contactSidebarItemsOrder.value).toEqual(
      DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER
    );
  });

  it('returns correct value for isContactSidebarItemOpen', () => {
    const { isContactSidebarItemOpen } = useUiSettings();
    expect(isContactSidebarItemOpen('is_ct_labels_open')).toBe(true);
    expect(isContactSidebarItemOpen('non_existent_key')).toBe(false);
  });

  it('sets signature flag for inbox correctly', () => {
    const { setSignatureFlagForInbox } = useUiSettings();
    setSignatureFlagForInbox('email', true);
    expect(mockDispatch).toHaveBeenCalledWith('updateUISettings', {
      uiSettings: {
        is_ct_labels_open: true,
        conversation_sidebar_items_order:
          DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER,
        contact_sidebar_items_order: DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER,
        email_signature_enabled: true,
        editor_message_key: 'enter',
      },
    });
  });

  it('fetches signature flag from UI settings correctly', () => {
    const { fetchSignatureFlagFromUiSettings } = useUiSettings();
    expect(fetchSignatureFlagFromUiSettings('email')).toBe(undefined);
  });

  it('returns correct value for isEditorHotKeyEnabled when editor_message_key is configured', () => {
    getUISettingsMock.value.enter_to_send_enabled = false;
    const { isEditorHotKeyEnabled } = useUiSettings();
    expect(isEditorHotKeyEnabled('enter')).toBe(true);
    expect(isEditorHotKeyEnabled('cmd_enter')).toBe(false);
  });

  it('returns correct value for isEditorHotKeyEnabled when editor_message_key is not configured', () => {
    getUISettingsMock.value.editor_message_key = undefined;
    const { isEditorHotKeyEnabled } = useUiSettings();
    expect(isEditorHotKeyEnabled('enter')).toBe(false);
    expect(isEditorHotKeyEnabled('cmd_enter')).toBe(true);
  });

  it('handles non-existent keys', () => {
    const {
      isContactSidebarItemOpen,
      fetchSignatureFlagFromUiSettings,
      isEditorHotKeyEnabled,
    } = useUiSettings();
    expect(isContactSidebarItemOpen('non_existent_key')).toBe(false);
    expect(fetchSignatureFlagFromUiSettings('non_existent_key')).toBe(
      undefined
    );
    expect(isEditorHotKeyEnabled('non_existent_key')).toBe(false);
  });
});
