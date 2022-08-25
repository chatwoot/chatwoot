export const categoriesPayload = {
  payload: [
    {
      id: 1,
      name: 'FAQs',
      slug: 'faq',
      locale: 'en',
      description: 'This category is for FAQs',
      position: 0,
      account_id: 1,
      meta: {
        articles_count: 1,
      },
    },
    {
      id: 2,
      name: 'Product updates',
      slug: 'product-updates',
      locale: 'en',
      description: 'This category is for product updates',
      position: 0,
      account_id: 1,
      meta: {
        articles_count: 0,
      },
    },
  ],
  meta: {
    current_page: 1,
    categories_count: 2,
  },
};

export const categoriesState = {
  meta: {
    count: 123,
    currentPage: 1,
  },
  categories: {
    byId: {
      1: {
        id: 1,
        name: 'FAQs',
        slug: 'faq',
        locale: 'en',
        description: 'This category is for FAQs',
        position: 0,
        account_id: 1,
        meta: {
          articles_count: 1,
        },
      },
      2: {
        id: 2,
        name: 'Product updates',
        slug: 'product-updates',
        locale: 'en',
        description: 'This category is for product updates',
        position: 0,
        account_id: 1,
        meta: {
          articles_count: 0,
        },
      },
    },
    allIds: [1, 2],
    uiFlags: {
      byId: {
        1: { isFetching: false, isUpdating: true, isDeleting: false },
      },
    },
  },
  uiFlags: {
    allFetched: false,
    isFetching: true,
  },
};
