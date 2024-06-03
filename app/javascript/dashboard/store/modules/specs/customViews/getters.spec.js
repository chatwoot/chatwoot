import { getters } from '../../customViews';
import { customViewList } from './fixtures';

describe('#getters', () => {
  it('getCustomViews', () => {
    const state = { records: customViewList };
    expect(getters.getCustomViews(state)).toEqual([
      {
        name: 'Custom view',
        filter_type: 0,
        query: {
          payload: [
            {
              attribute_key: 'assignee_id',
              filter_operator: 'equal_to',
              values: [45],
              query_operator: 'and',
            },
            {
              attribute_key: 'inbox_id',
              filter_operator: 'equal_to',
              values: [144],
              query_operator: 'and',
            },
          ],
        },
      },
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

  it('getCustomViewsByFilterType', () => {
    const state = { records: customViewList };
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
