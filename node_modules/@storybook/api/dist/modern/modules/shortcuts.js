import "core-js/modules/es.array.reduce.js";
import global from 'global';
import { PREVIEW_KEYDOWN } from '@storybook/core-events';
import { shortcutMatchesShortcut, eventToShortcut } from '../lib/shortcut';
import { focusableUIElements } from './layout';
const {
  navigator,
  document
} = global;
export const isMacLike = () => navigator && navigator.platform ? !!navigator.platform.match(/(Mac|iPhone|iPod|iPad)/i) : false;
export const controlOrMetaKey = () => isMacLike() ? 'meta' : 'control';
export function keys(o) {
  return Object.keys(o);
}
export const defaultShortcuts = Object.freeze({
  fullScreen: ['F'],
  togglePanel: ['A'],
  panelPosition: ['D'],
  toggleNav: ['S'],
  toolbar: ['T'],
  search: ['/'],
  focusNav: ['1'],
  focusIframe: ['2'],
  focusPanel: ['3'],
  prevComponent: ['alt', 'ArrowUp'],
  nextComponent: ['alt', 'ArrowDown'],
  prevStory: ['alt', 'ArrowLeft'],
  nextStory: ['alt', 'ArrowRight'],
  shortcutsPage: [controlOrMetaKey(), 'shift', ','],
  aboutPage: [','],
  escape: ['escape'],
  // This one is not customizable
  collapseAll: [controlOrMetaKey(), 'shift', 'ArrowUp'],
  expandAll: [controlOrMetaKey(), 'shift', 'ArrowDown']
});
const addonsShortcuts = {};

function focusInInput(event) {
  return /input|textarea/i.test(event.target.tagName) || event.target.getAttribute('contenteditable') !== null;
}

export const init = ({
  store,
  fullAPI
}) => {
  const api = {
    // Getting and setting shortcuts
    getShortcutKeys() {
      return store.getState().shortcuts;
    },

    getDefaultShortcuts() {
      return Object.assign({}, defaultShortcuts, api.getAddonsShortcutDefaults());
    },

    getAddonsShortcuts() {
      return addonsShortcuts;
    },

    getAddonsShortcutLabels() {
      const labels = {};
      Object.entries(api.getAddonsShortcuts()).forEach(([actionName, {
        label
      }]) => {
        labels[actionName] = label;
      });
      return labels;
    },

    getAddonsShortcutDefaults() {
      const defaults = {};
      Object.entries(api.getAddonsShortcuts()).forEach(([actionName, {
        defaultShortcut
      }]) => {
        defaults[actionName] = defaultShortcut;
      });
      return defaults;
    },

    async setShortcuts(shortcuts) {
      await store.setState({
        shortcuts
      }, {
        persistence: 'permanent'
      });
      return shortcuts;
    },

    async restoreAllDefaultShortcuts() {
      return api.setShortcuts(api.getDefaultShortcuts());
    },

    async setShortcut(action, value) {
      const shortcuts = api.getShortcutKeys();
      await api.setShortcuts(Object.assign({}, shortcuts, {
        [action]: value
      }));
      return value;
    },

    async setAddonShortcut(addon, shortcut) {
      const shortcuts = api.getShortcutKeys();
      await api.setShortcuts(Object.assign({}, shortcuts, {
        [`${addon}-${shortcut.actionName}`]: shortcut.defaultShortcut
      }));
      addonsShortcuts[`${addon}-${shortcut.actionName}`] = shortcut;
      return shortcut;
    },

    async restoreDefaultShortcut(action) {
      const defaultShortcut = api.getDefaultShortcuts()[action];
      return api.setShortcut(action, defaultShortcut);
    },

    // Listening to shortcut events
    handleKeydownEvent(event) {
      const shortcut = eventToShortcut(event);
      const shortcuts = api.getShortcutKeys();
      const actions = keys(shortcuts);
      const matchedFeature = actions.find(feature => shortcutMatchesShortcut(shortcut, shortcuts[feature]));

      if (matchedFeature) {
        // Event.prototype.preventDefault is missing when received from the MessageChannel.
        if (event !== null && event !== void 0 && event.preventDefault) event.preventDefault();
        api.handleShortcutFeature(matchedFeature);
      }
    },

    // warning: event might not have a full prototype chain because it may originate from the channel
    handleShortcutFeature(feature) {
      const {
        layout: {
          isFullscreen,
          showNav,
          showPanel
        },
        ui: {
          enableShortcuts
        }
      } = store.getState();

      if (!enableShortcuts) {
        return;
      }

      switch (feature) {
        case 'escape':
          {
            if (isFullscreen) {
              fullAPI.toggleFullscreen();
            } else if (!showNav) {
              fullAPI.toggleNav();
            }

            break;
          }

        case 'focusNav':
          {
            if (isFullscreen) {
              fullAPI.toggleFullscreen();
            }

            if (!showNav) {
              fullAPI.toggleNav();
            }

            fullAPI.focusOnUIElement(focusableUIElements.storyListMenu);
            break;
          }

        case 'search':
          {
            if (isFullscreen) {
              fullAPI.toggleFullscreen();
            }

            if (!showNav) {
              fullAPI.toggleNav();
            }

            setTimeout(() => {
              fullAPI.focusOnUIElement(focusableUIElements.storySearchField, true);
            }, 0);
            break;
          }

        case 'focusIframe':
          {
            const element = document.getElementById('storybook-preview-iframe');

            if (element) {
              try {
                // should be like a channel message and all that, but yolo for now
                element.contentWindow.focus();
              } catch (e) {//
              }
            }

            break;
          }

        case 'focusPanel':
          {
            if (isFullscreen) {
              fullAPI.toggleFullscreen();
            }

            if (!showPanel) {
              fullAPI.togglePanel();
            }

            fullAPI.focusOnUIElement(focusableUIElements.storyPanelRoot);
            break;
          }

        case 'nextStory':
          {
            fullAPI.jumpToStory(1);
            break;
          }

        case 'prevStory':
          {
            fullAPI.jumpToStory(-1);
            break;
          }

        case 'nextComponent':
          {
            fullAPI.jumpToComponent(1);
            break;
          }

        case 'prevComponent':
          {
            fullAPI.jumpToComponent(-1);
            break;
          }

        case 'fullScreen':
          {
            fullAPI.toggleFullscreen();
            break;
          }

        case 'togglePanel':
          {
            if (isFullscreen) {
              fullAPI.toggleFullscreen();
              fullAPI.resetLayout();
            }

            fullAPI.togglePanel();
            break;
          }

        case 'toggleNav':
          {
            if (isFullscreen) {
              fullAPI.toggleFullscreen();
              fullAPI.resetLayout();
            }

            fullAPI.toggleNav();
            break;
          }

        case 'toolbar':
          {
            fullAPI.toggleToolbar();
            break;
          }

        case 'panelPosition':
          {
            if (isFullscreen) {
              fullAPI.toggleFullscreen();
            }

            if (!showPanel) {
              fullAPI.togglePanel();
            }

            fullAPI.togglePanelPosition();
            break;
          }

        case 'aboutPage':
          {
            fullAPI.navigate('/settings/about');
            break;
          }

        case 'shortcutsPage':
          {
            fullAPI.navigate('/settings/shortcuts');
            break;
          }

        case 'collapseAll':
          {
            fullAPI.collapseAll();
            break;
          }

        case 'expandAll':
          {
            fullAPI.expandAll();
            break;
          }

        default:
          addonsShortcuts[feature].action();
          break;
      }
    }

  };
  const {
    shortcuts: persistedShortcuts = defaultShortcuts
  } = store.getState();
  const state = {
    // Any saved shortcuts that are still in our set of defaults
    shortcuts: keys(defaultShortcuts).reduce((acc, key) => Object.assign({}, acc, {
      [key]: persistedShortcuts[key] || defaultShortcuts[key]
    }), defaultShortcuts)
  };

  const initModule = () => {
    // Listen for keydown events in the manager
    document.addEventListener('keydown', event => {
      if (!focusInInput(event)) {
        fullAPI.handleKeydownEvent(event);
      }
    }); // Also listen to keydown events sent over the channel

    fullAPI.on(PREVIEW_KEYDOWN, data => {
      fullAPI.handleKeydownEvent(data.event);
    });
  };

  return {
    api,
    state,
    init: initModule
  };
};