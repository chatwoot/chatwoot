import types from '../../../mutation-types';
import { mutations } from '../../dashboardApps';

describe('#mutations', () => {
  describe('#SET_DASHBOARD_APPS_UI_FLAG', () => {
    it('set dashboard app ui flags', () => {
      const state = { uiFlags: { isCreating: false, isUpdating: false } };
      mutations[types.SET_DASHBOARD_APPS_UI_FLAG](state, { isUpdating: true });
      expect(state.uiFlags).toEqual({ isCreating: false, isUpdating: true });
    });
  });

  describe('#SET_DASHBOARD_APPS', () => {
    it('set dashboard records', () => {
      const state = { records: [{ title: 'Title 0' }] };
      mutations[types.SET_DASHBOARD_APPS](state, [{ title: 'Title 1' }]);
      expect(state.records).toEqual([{ title: 'Title 1' }]);
    });
  });
});
