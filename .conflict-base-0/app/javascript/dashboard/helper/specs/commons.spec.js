import {
  getTypingUsersText,
  createPendingMessage,
  convertToAttributeSlug,
  convertToCategorySlug,
  convertToPortalSlug,
  sanitizeVariableSearchKey,
  formatToTitleCase,
} from '../commons';

describe('#getTypingUsersText', () => {
  it('returns the correct text is there is only one typing user', () => {
    expect(getTypingUsersText([{ name: 'Pranav' }])).toEqual([
      'TYPING.ONE',
      { user: 'Pranav' },
    ]);
  });

  it('returns the correct text is there are two typing users', () => {
    expect(
      getTypingUsersText([{ name: 'Pranav' }, { name: 'Nithin' }])
    ).toEqual(['TYPING.TWO', { user: 'Pranav', secondUser: 'Nithin' }]);
  });

  it('returns the correct text is there are more than two users are typing', () => {
    expect(
      getTypingUsersText([
        { name: 'Pranav' },
        { name: 'Nithin' },
        { name: 'Subin' },
        { name: 'Sojan' },
      ])
    ).toEqual(['TYPING.MULTIPLE', { user: 'Pranav', count: 3 }]);
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

describe('sanitizeVariableSearchKey', () => {
  it('removes braces', () => {
    expect(sanitizeVariableSearchKey('{{contact.name}}')).toBe('contact.name');
  });

  it('removes right braces', () => {
    expect(sanitizeVariableSearchKey('contact.name}}')).toBe('contact.name');
  });

  it('removes braces, comma and whitespace', () => {
    expect(sanitizeVariableSearchKey(' {{contact.name }},')).toBe(
      'contact.name'
    );
  });

  it('trims whitespace', () => {
    expect(sanitizeVariableSearchKey('  contact.name  ')).toBe('contact.name');
  });

  it('handles multiple commas', () => {
    expect(sanitizeVariableSearchKey('{{contact.name}},,')).toBe(
      'contact.name'
    );
  });

  it('returns empty string when only braces/commas/whitespace', () => {
    expect(sanitizeVariableSearchKey(' {  }, , ')).toBe('');
  });

  it('returns empty string for undefined input', () => {
    expect(sanitizeVariableSearchKey()).toBe('');
  });
});

describe('formatToTitleCase', () => {
  it('converts underscore-separated string to title case', () => {
    expect(formatToTitleCase('round_robin')).toBe('Round Robin');
  });

  it('converts single word to title case', () => {
    expect(formatToTitleCase('priority')).toBe('Priority');
  });

  it('converts multiple underscores to title case', () => {
    expect(formatToTitleCase('auto_assignment_policy')).toBe(
      'Auto Assignment Policy'
    );
  });

  it('handles already capitalized words', () => {
    expect(formatToTitleCase('HIGH_PRIORITY')).toBe('HIGH PRIORITY');
  });

  it('handles mixed case with underscores', () => {
    expect(formatToTitleCase('first_Name_last')).toBe('First Name Last');
  });

  it('handles empty string', () => {
    expect(formatToTitleCase('')).toBe('');
  });

  it('handles null input', () => {
    expect(formatToTitleCase(null)).toBe('');
  });

  it('handles undefined input', () => {
    expect(formatToTitleCase(undefined)).toBe('');
  });

  it('handles string without underscores', () => {
    expect(formatToTitleCase('hello')).toBe('Hello');
  });

  it('handles string with numbers', () => {
    expect(formatToTitleCase('priority_1_high')).toBe('Priority 1 High');
  });

  it('handles leading and trailing underscores', () => {
    expect(formatToTitleCase('_leading_trailing_')).toBe('Leading Trailing');
  });
});
