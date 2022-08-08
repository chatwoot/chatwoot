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

  it('isFetchingPortals', () => {
    const state = portal;
    expect(getters.isFetchingPortals(state)).toEqual(true);
  });

  it('portalById', () => {
    const state = portal;
    expect(getters.portalById(state)(1)).toEqual({
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
    });
  });

  it('allPortals', () => {
    const state = portal;
    expect(getters.allPortals(state, getters).length).toEqual(2);
  });
  it('count', () => {
    const state = portal;
    expect(getters.count(state)).toEqual(2);
  });

  it('getMeta', () => {
    const state = portal;
    expect(getters.getMeta(state)).toEqual({ count: 0, currentPage: 1 });
  });
});
