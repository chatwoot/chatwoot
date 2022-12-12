import { addons, types } from '@storybook/addons';
import { ADDON_ID, PANEL_ID } from './shared';
addons.register(ADDON_ID, () => {
  addons.add(PANEL_ID, {
    type: types.TAB,
    title: 'Docs',
    route: ({
      storyId,
      refId
    }) => refId ? `/docs/${refId}_${storyId}` : `/docs/${storyId}`,
    match: ({
      viewMode
    }) => viewMode === 'docs',
    render: () => null
  });
});