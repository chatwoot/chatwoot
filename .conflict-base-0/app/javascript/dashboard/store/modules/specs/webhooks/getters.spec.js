import { getters } from '../../webhooks';
import webhooks from './fixtures';

describe('#getters', () => {
  it('getInboxes', () => {
    const state = {
      records: webhooks,
    };
    expect(getters.getWebhooks(state)).toEqual(webhooks);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        fetchingList: false,
        fetchingItem: false,
        creatingItem: false,
        updatingItem: false,
        deletingItem: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      fetchingList: false,
      fetchingItem: false,
      creatingItem: false,
      updatingItem: false,
      deletingItem: false,
    });
  });
});
