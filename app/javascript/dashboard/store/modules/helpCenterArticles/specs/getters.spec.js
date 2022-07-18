import { getters } from '../getters';
import articles from './fixtures';
describe('#getters', () => {
  it('uiFlagsIn', () => {
    const state = articles;
    expect(getters.uiFlagsIn(state)(1)).toEqual({
      isFetching: false,
      isUpdating: true,
      isDeleting: false,
    });
  });

  // it('allHelpCenterArticles', () => {
  //   const state = articles;
  //   expect(getters.allHelpCenterArticles(state)).toEqual([
  //     {
  //       id: 1,
  //       category_id: 1,
  //       title: 'Documents are required to complete KYC',
  //       content:
  //         'The submission of the following documents is mandatory to complete registration, ID proof - PAN Card, Address proof',
  //       description: 'Documents are required to complete KYC',
  //       status: 'draft',
  //       account_id: 1,
  //       views: 122,
  //       author: {
  //         id: 5,
  //         account_id: 1,
  //         email: 'tom@furrent.com',
  //         available_name: 'Tom',
  //         name: 'Tom Jose',
  //       },
  //     },
  //   ]);
  // });

  // it('helpCenterArticleById', () => {
  //   const state = articles;
  //   expect(getters.helpCenterArticleById(state)(1)).toEqual({
  //     id: 1,
  //     category_id: 1,
  //     title: 'Documents are required to complete KYC',
  //     content:
  //       'The submission of the following documents is mandatory to complete registration, ID proof - PAN Card, Address proof',
  //     description: 'Documents are required to complete KYC',
  //     status: 'draft',
  //     account_id: 1,
  //     views: 122,
  //     author: {
  //       id: 5,
  //       account_id: 1,
  //       email: 'tom@furrent.com',
  //       available_name: 'Tom',
  //       name: 'Tom Jose',
  //     },
  //   });
  // });

  it('isFetchingHelpCenters', () => {
    const state = articles;
    expect(getters.isFetchingHelpCenterArticles(state)).toEqual(true);
  });
});
