import { getters } from '../../customViews';
import { contactViewList, customViewList } from './fixtures';

describe('#getters', () => {
  it('getCustomViewsByFilterType', () => {
    const state = { contact: { records: contactViewList } };
    expect(getters.getCustomViewsByFilterType(state)(1)).toEqual([
      {
        name: 'Custom view 1',
        filter_type: 1,
        query: {
          payload: [
            {
              attribute_key: 'name',
              filter_operator: 'equal_to',
              values: ['john doe'],
              query_operator: null,
            },
          ],
        },
      },
    ]);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
        isCreating: false,
        isDeleting: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
      isCreating: false,
      isDeleting: false,
    });
  });

  it('getActiveConversationFolder', () => {
    const state = { activeConversationFolder: customViewList[0] };
    expect(getters.getActiveConversationFolder(state)).toEqual(
      customViewList[0]
    );
  });
});
