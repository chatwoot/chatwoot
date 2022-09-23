import { getters } from '../../macros';
import macros from './fixtures';
describe('#getters', () => {
  it('getMacros', () => {
    const state = { records: macros };
    expect(getters.getMacros(state)).toEqual(macros);
  });

  it('getMacro', () => {
    const state = { records: macros };
    expect(getters.getMacro(state)(22)).toEqual(macros[0]);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
        isCreating: false,
        isUpdating: false,
        isDeleting: false,
        isExecuting: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
      isCreating: false,
      isUpdating: false,
      isDeleting: false,
      isExecuting: false,
    });
  });
});
