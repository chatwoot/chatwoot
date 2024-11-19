import { getters } from '../getters';
import articles from './fixtures';
describe('#getters', () => {
  let state = {};
  beforeEach(() => {
    state = articles;
  });
  it('uiFlags', () => {
    expect(getters.uiFlags(state)(1)).toEqual({
      isFetching: false,
      isUpdating: true,
      isDeleting: false,
    });
  });

  it('articleById', () => {
    expect(getters.articleById(state)(1)).toEqual({
      id: 1,
      category_id: 1,
      title: 'Documents are required to complete KYC',
      content:
        'The submission of the following documents is mandatory to complete registration, ID proof - PAN Card, Address proof',
      description: 'Documents are required to complete KYC',
      status: 'draft',
      account_id: 1,
      views: 122,
      author: {
        id: 5,
        account_id: 1,
        email: 'tom@furrent.com',
        available_name: 'Tom',
        name: 'Tom Jose',
      },
    });
  });

  it('articleStatus', () => {
    expect(getters.articleStatus(state)(1)).toEqual('draft');
  });

  it('isFetchingArticles', () => {
    expect(getters.isFetching(state)).toEqual(true);
  });
});
