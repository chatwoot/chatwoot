import { getters } from '../../labels';
import labels from './fixtures';
describe('#getters', () => {
  it('getLabels', () => {
    const state = { records: labels };
    expect(getters.getLabels(state)).toEqual(labels);
  });

  it('getLabelsOnSidebar', () => {
    const state = { records: labels };
    expect(getters.getLabelsOnSidebar(state)).toEqual([labels[0]]);
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
