import {
  getTypingUsersText,
  createPendingMessage,
  convertToAttributeSlug,
  convertToCategorySlug,
  convertToPortalSlug,
} from '../commons';

describe('#getTypingUsersText', () => {
  it('returns the correct text is there is only one typing user', () => {
    expect(getTypingUsersText([{ name: 'Pranav' }])).toEqual(
      'Pranav is typing'
    );
  });

  it('returns the correct text is there are two typing users', () => {
    expect(
      getTypingUsersText([{ name: 'Pranav' }, { name: 'Nithin' }])
    ).toEqual('Pranav and Nithin are typing');
  });

  it('returns the correct text is there are more than two users are typing', () => {
    expect(
      getTypingUsersText([
        { name: 'Pranav' },
        { name: 'Nithin' },
        { name: 'Subin' },
        { name: 'Sojan' },
      ])
    ).toEqual('Pranav and 3 others are typing');
  });
});

describe('#createPendingMessage', () => {
  const message = {
    message: 'hi',
  };
  it('returns the pending message with expected new keys', () => {
    expect(createPendingMessage(message)).toMatchObject({
      content: expect.anything(),
      id: expect.anything(),
      status: expect.anything(),
      echo_id: expect.anything(),
      created_at: expect.anything(),
      message_type: expect.anything(),
    });
  });

  it('returns the pending message with status progress', () => {
    expect(createPendingMessage(message)).toMatchObject({
      status: 'progress',
    });
  });

  it('returns the pending message with same id and echo_id', () => {
    const pending = createPendingMessage(message);
    expect(pending).toMatchObject({
      echo_id: pending.id,
    });
  });

  it('returns the pending message with attachment key if file is passed', () => {
    const messageWithFile = {
      message: 'hi',
      file: {},
    };
    expect(createPendingMessage(messageWithFile)).toMatchObject({
      content: expect.anything(),
      id: expect.anything(),
      status: expect.anything(),
      echo_id: expect.anything(),
      created_at: expect.anything(),
      message_type: expect.anything(),
      attachments: [{ id: expect.anything() }],
    });
  });

  it('returns the pending message to have one attachment', () => {
    const messageWithFile = {
      message: 'hi',
      file: {},
    };
    const pending = createPendingMessage(messageWithFile);
    expect(pending.attachments.length).toBe(1);
  });
});

describe('convertToAttributeSlug', () => {
  it('should convert to slug', () => {
    expect(convertToAttributeSlug('Test@%^&*(){}>.!@`~_ ing')).toBe(
      'test__ing'
    );
  });
});

describe('convertToCategorySlug', () => {
  it('should convert to slug', () => {
    expect(convertToCategorySlug('User profile guide')).toBe(
      'user-profile-guide'
    );
  });
});

describe('convertToPortalSlug', () => {
  it('should convert to slug', () => {
    expect(convertToPortalSlug('Room rental')).toBe('room-rental');
  });
});
