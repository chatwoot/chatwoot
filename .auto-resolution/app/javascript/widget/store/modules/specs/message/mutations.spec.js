import { mutations } from '../../message';

describe('#mutations', () => {
  describe('#toggleUpdateStatus', () => {
    it('set update flags', () => {
      const state = { uiFlags: { status: '' } };
      mutations.toggleUpdateStatus(state, 'sent');
      expect(state.uiFlags.isUpdating).toEqual('sent');
    });
  });
});
