import deprecate from 'util-deprecate';
import dedent from 'ts-dedent';
import { isStory } from '../lib/stories';
const warnDisabledDeprecated = deprecate(() => {}, dedent`
    Use 'parameters.key.disable' instead of 'parameters.key.disabled'.
    
    https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-disabled-parameter
  `);
export let types;

(function (types) {
  types["TAB"] = "tab";
  types["PANEL"] = "panel";
  types["TOOL"] = "tool";
  types["PREVIEW"] = "preview";
  types["NOTES_ELEMENT"] = "notes-element";
})(types || (types = {}));

export function ensurePanel(panels, selectedPanel, currentPanel) {
  const keys = Object.keys(panels);

  if (keys.indexOf(selectedPanel) >= 0) {
    return selectedPanel;
  }

  if (keys.length) {
    return keys[0];
  }

  return currentPanel;
}
export const init = ({
  provider,
  store,
  fullAPI
}) => {
  const api = {
    getElements: type => provider.getElements(type),
    getPanels: () => api.getElements(types.PANEL),
    getStoryPanels: () => {
      const allPanels = api.getPanels();
      const {
        storyId
      } = store.getState();
      const story = fullAPI.getData(storyId);

      if (!allPanels || !story || !isStory(story)) {
        return allPanels;
      }

      const {
        parameters
      } = story;
      const filteredPanels = {};
      Object.entries(allPanels).forEach(([id, panel]) => {
        const {
          paramKey
        } = panel;

        if (paramKey && parameters && parameters[paramKey] && (parameters[paramKey].disabled || parameters[paramKey].disable)) {
          if (parameters[paramKey].disabled) {
            warnDisabledDeprecated();
          }

          return;
        }

        filteredPanels[id] = panel;
      });
      return filteredPanels;
    },
    getSelectedPanel: () => {
      const {
        selectedPanel
      } = store.getState();
      return ensurePanel(api.getPanels(), selectedPanel, selectedPanel);
    },
    setSelectedPanel: panelName => {
      store.setState({
        selectedPanel: panelName
      }, {
        persistence: 'session'
      });
    },

    setAddonState(addonId, newStateOrMerger, options) {
      let nextState;
      const {
        addons: existing
      } = store.getState();

      if (typeof newStateOrMerger === 'function') {
        const merger = newStateOrMerger;
        nextState = merger(api.getAddonState(addonId));
      } else {
        nextState = newStateOrMerger;
      }

      return store.setState({
        addons: Object.assign({}, existing, {
          [addonId]: nextState
        })
      }, options).then(() => api.getAddonState(addonId));
    },

    getAddonState: addonId => {
      return store.getState().addons[addonId];
    }
  };
  return {
    api,
    state: {
      selectedPanel: ensurePanel(api.getPanels(), store.getState().selectedPanel),
      addons: {}
    }
  };
};