import types from '../../../mutation-types';
import { mutations } from '../../dashboardApps';
import { automationsList } from './fixtures';

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

  describe('#ADD_DASHBOARD_APP', () => {
    it('push newly created app to the store', () => {
      const state = { records: [automationsList[0]] };
      mutations[types.CREATE_DASHBOARD_APP](state, automationsList[1]);
      expect(state.records).toEqual([automationsList[0], automationsList[1]]);
    });
  });

  describe('#EDIT_DASHBOARD_APP', () => {
    it('update label record', () => {
      const state = { records: [automationsList[0]] };
      mutations[types.EDIT_DASHBOARD_APP](state, {
        id: 15,
        title: 'updated-title',
      });
      expect(state.records[0].title).toEqual('updated-title');
    });
  });

  describe('#DELETE_DASHBOARD_APP', () => {
    it('delete label record', () => {
      const state = { records: [automationsList[0]] };
      mutations[types.DELETE_DASHBOARD_APP](state, 15);
      expect(state.records).toEqual([]);
    });
  });
});
