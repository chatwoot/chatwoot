import { getters } from '../../automations';
import automations from './fixtures';
describe('#getters', () => {
  it('getAutomations', () => {
    const state = { records: automations };
    expect(getters.getAutomations(state)).toEqual(automations);
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
