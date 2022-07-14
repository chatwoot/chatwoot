export default {
  helpCenters: {
    byId: {
      1: {
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
        localeIds: [],
      },
      2: {
        id: 1,
        color: 'green',
        custom_domain: 'campaign_for_help',
        header_text: 'Campaign Header',
        homepage_link: 'help-center',
        name: 'help name',
        page_title: 'campaign title',
        slug: 'campaign',
        archived: false,
        config: {
          allowed_locales: ['en'],
        },
        localeIds: [],
      },
    },
    allIds: [1, 2],
    uiFlags: {
      byId: {
        1: { isFetching: false, isUpdating: true, isDeleting: false },
      },
    },
    meta: {
      byId: {},
    },
  },
  uiFlags: {
    allFetched: false,
    isFetching: true,
  },
};
