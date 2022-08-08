export default {
  meta: {
    count: 0,
    currentPage: 1,
  },
  portals: {
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
      },
      2: {
        id: 2,
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
      },
    },
    allIds: [1, 2],
    uiFlags: {
      byId: {
        1: { isFetching: false, isUpdating: true, isDeleting: false },
      },
    },
    selectedPortalId: 1,
  },
  uiFlags: {
    allFetched: false,
    isFetching: true,
  },
};

export const apiResponse = {
  payload: [
    {
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
    },
    {
      id: 2,
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
    },
  ],
  meta: {
    current_page: 1,
    portals_count: 1,
  },
};
