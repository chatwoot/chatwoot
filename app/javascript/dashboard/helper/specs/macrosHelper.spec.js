import {
  emptyMacro,
  resolveActionName,
  resolveLabels,
  resolveTeamIds,
  getFileName,
  resolveAgents,
} from '../../routes/dashboard/settings/macros/macroHelper';
import { MACRO_ACTION_TYPES } from '../../routes/dashboard/settings/macros/constants';
import { teams, labels, files, agents } from './macrosFixtures';

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

describe('#resolveActionName', () => {
  it('resolve action name from key and return the correct label', () => {
    expect(resolveActionName(MACRO_ACTION_TYPES[0].key)).toEqual(
      MACRO_ACTION_TYPES[0].label
    );
    expect(resolveActionName(MACRO_ACTION_TYPES[1].key)).toEqual(
      MACRO_ACTION_TYPES[1].label
    );
    expect(resolveActionName(MACRO_ACTION_TYPES[1].key)).not.toEqual(
      MACRO_ACTION_TYPES[0].label
    );
    expect(resolveActionName('change_priority')).toEqual('Change Priority');
  });
});

describe('#resolveTeamIds', () => {
  it('resolves team names from ids, and returns a joined string', () => {
    const resolvedTeams = '⚙️ sales team, 🤷‍♂️ fayaz';
    expect(resolveTeamIds(teams, [1, 2])).toEqual(resolvedTeams);
  });
});

describe('#resolveLabels', () => {
  it('resolves labels names from ids and returns a joined string', () => {
    const resolvedLabels = 'sales, billing';
    expect(resolveLabels(labels, ['sales', 'billing'])).toEqual(resolvedLabels);
  });
});

describe('#resolveAgents', () => {
  it('resolves agents names from ids and returns a joined string', () => {
    const resolvedAgents = 'John Doe';
    expect(resolveAgents(agents, [1])).toEqual(resolvedAgents);
  });
});

describe('#getFileName', () => {
  it('returns the correct file name from the list of files', () => {
    expect(getFileName(files[0].blob_id, 'send_attachment', files)).toEqual(
      files[0].filename
    );
    expect(getFileName(files[1].blob_id, 'send_attachment', files)).toEqual(
      files[1].filename
    );
    expect(getFileName(files[0].blob_id, 'wrong_action', files)).toEqual('');
    expect(getFileName(null, 'send_attachment', files)).toEqual('');
    expect(getFileName(files[0].blob_id, 'send_attachment', [])).toEqual('');
  });
});
