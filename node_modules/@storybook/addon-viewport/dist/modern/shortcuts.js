import { ADDON_ID } from './constants';

const getCurrentViewportIndex = (viewportsKeys, current) => viewportsKeys.indexOf(current);

const getNextViewport = (viewportsKeys, current) => {
  const currentViewportIndex = getCurrentViewportIndex(viewportsKeys, current);
  return currentViewportIndex === viewportsKeys.length - 1 ? viewportsKeys[0] : viewportsKeys[currentViewportIndex + 1];
};

const getPreviousViewport = (viewportsKeys, current) => {
  const currentViewportIndex = getCurrentViewportIndex(viewportsKeys, current);
  return currentViewportIndex < 1 ? viewportsKeys[viewportsKeys.length - 1] : viewportsKeys[currentViewportIndex - 1];
};

export const registerShortcuts = async (api, setState, viewportsKeys) => {
  await api.setAddonShortcut(ADDON_ID, {
    label: 'Previous viewport',
    defaultShortcut: ['shift', 'V'],
    actionName: 'previous',
    action: () => {
      const {
        selected,
        isRotated
      } = api.getAddonState(ADDON_ID);
      setState({
        selected: getPreviousViewport(viewportsKeys, selected),
        isRotated
      });
    }
  });
  await api.setAddonShortcut(ADDON_ID, {
    label: 'Next viewport',
    defaultShortcut: ['V'],
    actionName: 'next',
    action: () => {
      const {
        selected,
        isRotated
      } = api.getAddonState(ADDON_ID);
      setState({
        selected: getNextViewport(viewportsKeys, selected),
        isRotated
      });
    }
  });
  await api.setAddonShortcut(ADDON_ID, {
    label: 'Reset viewport',
    defaultShortcut: ['alt', 'V'],
    actionName: 'reset',
    action: () => {
      const {
        isRotated
      } = api.getAddonState(ADDON_ID);
      setState({
        selected: 'reset',
        isRotated
      });
    }
  });
};