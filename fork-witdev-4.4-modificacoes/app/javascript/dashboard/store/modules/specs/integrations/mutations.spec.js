import types from '../../../mutation-types';
import { mutations } from '../../integrations';

describe('#mutations', () => {
  describe('#GET_INTEGRATIONS', () => {
    it('set integrations records', () => {
      const state = { records: [] };
      mutations[types.SET_INTEGRATIONS](state, [
        {
          id: 1,
          name: 'test1',
          logo: 'test',
          enabled: true,
        },
      ]);
      expect(state.records).toEqual([
        {
          id: 1,
          name: 'test1',
          logo: 'test',
          enabled: true,
        },
      ]);
    });
  });

  describe('#ADD_INTEGRATION_HOOKS', () => {
    it('set integrations hook records', () => {
      const state = { records: [{ id: 'dialogflow', hooks: [] }] };
      const hookRecord = {
        id: 1,
        app_id: 'dialogflow',
        status: false,
        inbox: { id: 1, name: 'Chatwoot' },
        account_id: 1,
        hook_type: 'inbox',
        settings: { project_id: 'test', credentials: {} },
      };
      mutations[types.ADD_INTEGRATION_HOOKS](state, hookRecord);
      expect(state.records).toEqual([
        {
          id: 'dialogflow',
          hooks: [hookRecord],
        },
      ]);
    });
  });

  describe('#DELETE_INTEGRATION_HOOKS', () => {
    it('delete integrations hook record', () => {
      const state = {
        records: [
          {
            id: 'dialogflow',
            hooks: [
              {
                id: 1,
                app_id: 'dialogflow',
                status: false,
                inbox: { id: 1, name: 'Chatwoot' },
                account_id: 1,
                hook_type: 'inbox',
                settings: { project_id: 'test', credentials: {} },
              },
            ],
          },
        ],
      };
      mutations[types.DELETE_INTEGRATION_HOOKS](state, {
        appId: 'dialogflow',
        hookId: 1,
      });
      expect(state.records).toEqual([
        {
          id: 'dialogflow',
          hooks: [],
        },
      ]);
    });
  });
});
