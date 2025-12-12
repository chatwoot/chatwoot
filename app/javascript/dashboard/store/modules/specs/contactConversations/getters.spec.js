import { getters } from '../../contactConversations';

describe('#getters', () => {
  it('getContactConversation', () => {
    const state = {
      records: { 1: [{ id: 1, contact_id: 1, message: 'Hello' }] },
    };
    expect(getters.getContactConversation(state)(1)).toEqual([
      { id: 1, contact_id: 1, message: 'Hello' },
    ]);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
    });
  });

  it('getAllConversationsByContactId converts keys to camelCase', () => {
    const state = {
      records: {
        1: [
          {
            id: 1,
            contact_id: 1,
            message: 'Hello',
            conversation_type: 1,
            additional_attributes: {
              whatsapp_group_name: 'Test Group',
            },
          },
        ],
      },
    };
    const result = getters.getAllConversationsByContactId(state)(1);
    expect(result).toEqual([
      {
        id: 1,
        contactId: 1,
        message: 'Hello',
        conversationType: 1,
        additionalAttributes: {
          whatsappGroupName: 'Test Group',
        },
      },
    ]);
  });

  it('getAllConversationsByContactId returns empty array for non-existent contact', () => {
    const state = {
      records: {},
    };
    const result = getters.getAllConversationsByContactId(state)(999);
    expect(result).toEqual([]);
  });
});
