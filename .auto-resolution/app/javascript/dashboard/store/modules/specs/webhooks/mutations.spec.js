import * as types from '../../../mutation-types';
import { mutations } from '../../webhooks';
import webhooks from './fixtures';

describe('#mutations', () => {
  describe('#SET_WEBHOOK', () => {
    it('set webhook records', () => {
      const state = { records: [] };
      mutations[types.default.SET_WEBHOOK](state, webhooks);
      expect(state.records).toEqual(webhooks);
    });
  });

  describe('#ADD_WEBHOOK', () => {
    it('push newly created webhook data to the store', () => {
      const state = {
        records: [],
      };
      mutations[types.default.ADD_WEBHOOK](state, webhooks[0]);
      expect(state.records).toEqual([webhooks[0]]);
    });
  });

  describe('#DELETE_WEBHOOK', () => {
    it('delete webhook record', () => {
      const state = {
        records: [webhooks[0]],
      };
      mutations[types.default.DELETE_WEBHOOK](state, webhooks[0].id);
      expect(state.records).toEqual([]);
    });
  });

  describe('#UPDATE_WEBHOOK', () => {
    it('update webhook ', () => {
      const state = {
        records: [webhooks[0]],
      };
      mutations[types.default.UPDATE_WEBHOOK](state, webhooks[0]);
      expect(state.records[0].url).toEqual('https://1.chatwoot.com');
    });
  });
});
