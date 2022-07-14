import { getters } from '../getters';
import portal from './fixtures';
describe('#getters', () => {
  it('getUIFlagsIn', () => {
    const state = portal;
    expect(getters.uiFlagsIn(state)(1)).toEqual({
      isFetching: false,
      isUpdating: true,
      isDeleting: false,
    });
  });

  it('isFetchingHelpCenters', () => {
    const state = portal;
    expect(getters.isFetchingHelpCenters(state)).toEqual(true);
  });

  it('helpCenterById', () => {
    const state = portal;
    expect(getters.helpCenterById(state)(1)).toEqual({
      id: 1,
      color: 'red',
      custom_domain: 'domain_for_help',
      header_text: 'Domain Header',
      homepage_link: 'help-center',
      name: 'help name',
      page_title: 'page title',
      slug: 'domain',
      archived: false,
      config: {
        allowed_locales: ['en'],
      },
      locales: [],
      localeIds: [],
    });
  });
  it('totalHelpCentersCount', () => {
    const state = portal;
    expect(getters.totalHelpCentersCount(state)).toEqual(2);
  });
  it('allLocalesCountIn', () => {
    const state = portal;
    expect(getters.allLocalesCountIn(state)(1)).toEqual(0);
  });
});
