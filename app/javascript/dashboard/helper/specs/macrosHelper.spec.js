import {
  emptyMacro,
  resolveActionName,
  getFileName,
} from '../../routes/dashboard/settings/macros/macroHelper';
import { MACRO_ACTION_TYPES } from '../../routes/dashboard/settings/macros/constants';
import { files } from './macrosFixtures';

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
    expect(resolveActionName('change_priority')).toEqual('CHANGE_PRIORITY'); // Translated
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
