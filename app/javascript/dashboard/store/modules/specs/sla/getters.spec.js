import { getters } from '../../sla';
import SLAs from './fixtures';

describe('#getters', () => {
  it('getSLA', () => {
    const state = { records: SLAs };
    expect(getters.getSLA(state)).toEqual(SLAs);
  });

  it('getSLAById', () => {
    const state = { records: SLAs };
    expect(getters.getSLAById(state)(1)).toEqual(SLAs[0]);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
        isCreating: false,
        isUpdating: false,
        isDeleting: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
      isCreating: false,
      isUpdating: false,
      isDeleting: false,
    });
  });
});
