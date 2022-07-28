export default {
  articles: {
    byId: {
      1: {
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
      },
      2: {
        id: 2,
        category_id: 1,
        title:
          'How do I change my registered email address and/or phone number?',
        content:
          'Kindly login to your Furrent account to chat with us or submit a request and we would be glad to help you update the contact details on your account.',
        description: 'Change my registered email address and/or phone number',
        status: 'draft',
        account_id: 1,
        views: 121,
        author: {
          id: 5,
          account_id: 1,
          email: 'tom@furrent.com',
          available_name: 'Tom',
          name: 'Tom Jose',
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
