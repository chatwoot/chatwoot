import { emptyMacro } from '../../routes/dashboard/settings/macros/macroHelper';

describe('#emptyMacro', () => {
  const defaultMacro = {
    name: '',
    actions: [
      {
        action_name: 'assign_team',
        action_params: [],
      },
    ],
    visibility: 'global',
  };
  it('returns the default macro', () => {
    expect(emptyMacro).toEqual(defaultMacro);
  });
});
