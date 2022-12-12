import { ADDON_ID } from '../constants';
export const registerShortcuts = async (api, id, shortcuts) => {
  if (shortcuts && shortcuts.next) {
    await api.setAddonShortcut(ADDON_ID, {
      label: shortcuts.next.label,
      defaultShortcut: shortcuts.next.keys,
      actionName: `${id}:next`,
      action: shortcuts.next.action
    });
  }

  if (shortcuts && shortcuts.previous) {
    await api.setAddonShortcut(ADDON_ID, {
      label: shortcuts.previous.label,
      defaultShortcut: shortcuts.previous.keys,
      actionName: `${id}:previous`,
      action: shortcuts.previous.action
    });
  }

  if (shortcuts && shortcuts.reset) {
    await api.setAddonShortcut(ADDON_ID, {
      label: shortcuts.reset.label,
      defaultShortcut: shortcuts.reset.keys,
      actionName: `${id}:reset`,
      action: shortcuts.reset.action
    });
  }
};