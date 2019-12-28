import * as types from '../../../mutation-types';
import { mutations } from '../../inboxes';
import inboxList from './fixtures';

describe('#mutations', () => {
  describe('#SET_INBOXES', () => {
    it('set inbox records', () => {
      const state = { records: [] };
      mutations[types.default.SET_INBOXES](state, inboxList);
      expect(state.records).toEqual(inboxList);
    });
  });

  describe('#SET_INBOXES_ITEM', () => {
    it('push inbox if inbox doesnot exist to the store', () => {
      const state = {
        records: [],
      };
      mutations[types.default.SET_INBOXES_ITEM](state, inboxList[0]);
      expect(state.records).toEqual([inboxList[0]]);
    });

    it('update inbox if it exists to the store', () => {
      const state = {
        records: [
          {
            id: 1,
            channel_id: 1,
            name: 'Test FacebookPage',
            channel_type: 'Channel::FacebookPage',
            avatar_url: 'random_image1.png',
            page_id: '1235',
            widget_color: null,
            website_token: null,
          },
        ],
      };
      mutations[types.default.SET_INBOXES_ITEM](state, inboxList[0]);
      expect(state.records).toEqual([inboxList[0]]);
    });
  });

  describe('#ADD_INBOXES', () => {
    it('push new record in the inbox store', () => {
      const state = {
        records: [],
      };
      mutations[types.default.ADD_INBOXES](state, inboxList[0]);
      expect(state.records).toEqual([inboxList[0]]);
    });
  });
  describe('#EDIT_INBOXES', () => {
    it('update inbox in the store', () => {
      const state = {
        records: [
          {
            id: 1,
            channel_id: 1,
            name: 'Test FacebookPage',
            channel_type: 'Channel::FacebookPage',
            avatar_url: 'random_image1.png',
            page_id: '1235',
            widget_color: null,
            website_token: null,
          },
        ],
      };
      mutations[types.default.EDIT_INBOXES](state, inboxList[0]);
      expect(state.records).toEqual([inboxList[0]]);
    });
  });

  describe('#DELETE_INBOXES', () => {
    it('delete inbox from store', () => {
      const state = {
        records: [inboxList[0]],
      };
      mutations[types.default.DELETE_INBOXES](state, 1);
      expect(state.records).toEqual([]);
    });
  });

  describe('#DELETE_INBOXES', () => {
    it('delete inbox from store', () => {
      const state = {
        uiFlags: { isFetchingItem: false },
      };
      mutations[types.default.SET_INBOXES_UI_FLAG](state, {
        isFetchingItem: true,
      });
      expect(state.uiFlags).toEqual({ isFetchingItem: true });
    });
  });
});
