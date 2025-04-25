import { ref } from 'vue';
import {
  useUISettings,
  DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER,
  DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER,
} from 'dashboard/composables/useUISettings';

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

describe('useUISettings', () => {
  beforeEach(() => {
    mockDispatch.mockClear();
  });

  it('returns uiSettings', () => {
    const { uiSettings } = useUISettings();
    expect(uiSettings.value).toEqual({
      is_ct_labels_open: true,
      conversation_sidebar_items_order:
        DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER,
      contact_sidebar_items_order: DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER,
      editor_message_key: 'enter',
    });
  });

  it('updates UI settings correctly', () => {
    const { updateUISettings } = useUISettings();
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
    const { toggleSidebarUIState } = useUISettings();
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
    const { conversationSidebarItemsOrder } = useUISettings();
    expect(conversationSidebarItemsOrder.value).toEqual(
      DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER
    );
  });

  it('returns correct contact sidebar items order', () => {
    const { contactSidebarItemsOrder } = useUISettings();
    expect(contactSidebarItemsOrder.value).toEqual(
      DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER
    );
  });

  it('returns correct value for isContactSidebarItemOpen', () => {
    const { isContactSidebarItemOpen } = useUISettings();
    expect(isContactSidebarItemOpen('is_ct_labels_open')).toBe(true);
    expect(isContactSidebarItemOpen('non_existent_key')).toBe(false);
  });

  it('sets signature flag for inbox correctly', () => {
    const { setSignatureFlagForInbox } = useUISettings();
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
    const { fetchSignatureFlagFromUISettings } = useUISettings();
    expect(fetchSignatureFlagFromUISettings('email')).toBe(undefined);
  });

  it('returns correct value for isEditorHotKeyEnabled when editor_message_key is configured', () => {
    getUISettingsMock.value.enter_to_send_enabled = false;
    const { isEditorHotKeyEnabled } = useUISettings();
    expect(isEditorHotKeyEnabled('enter')).toBe(true);
    expect(isEditorHotKeyEnabled('cmd_enter')).toBe(false);
  });

  it('returns correct value for isEditorHotKeyEnabled when editor_message_key is not configured', () => {
    getUISettingsMock.value.editor_message_key = undefined;
    const { isEditorHotKeyEnabled } = useUISettings();
    expect(isEditorHotKeyEnabled('enter')).toBe(true);
    expect(isEditorHotKeyEnabled('cmd_enter')).toBe(false);
  });

  it('handles non-existent keys', () => {
    const {
      isContactSidebarItemOpen,
      fetchSignatureFlagFromUISettings,
      isEditorHotKeyEnabled,
    } = useUISettings();
    expect(isContactSidebarItemOpen('non_existent_key')).toBe(false);
    expect(fetchSignatureFlagFromUISettings('non_existent_key')).toBe(
      undefined
    );
    expect(isEditorHotKeyEnabled('non_existent_key')).toBe(false);
  });
});
