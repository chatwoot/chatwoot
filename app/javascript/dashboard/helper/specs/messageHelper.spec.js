import {
  replaceVariablesInMessage,
  getFirstName,
  getLastName,
  getMessageVariables,
  getUndefinedVariablesInMessage,
} from '../messageHelper';

const variables = {
  'contact.name': 'John Doe',
  'contact.first_name': 'John',
  'contact.last_name': 'Doe',
  'contact.email': 'john.p@example.com',
  'contact.phone': '1234567890',
  'conversation.id': 1,
  'agent.first_name': 'Samuel',
  'agent.last_name': 'Smith',
  'agent.email': 'samuel@gmail.com',
};

describe('#replaceVariablesInMessage', () => {
  it('returns the message with variable name', () => {
    const message =
      'No issues. Hey {{contact.first_name}}, we will send the reset instructions to your email {{ contact.email}}. The {{ agent.first_name }} {{ agent.last_name }} will take care of everything. Your conversation id is {{ conversation.id }}.';
    expect(replaceVariablesInMessage({ message, variables })).toBe(
      'No issues. Hey John, we will send the reset instructions to your email john.p@example.com. The Samuel Smith will take care of everything. Your conversation id is 1.'
    );
  });

  it('returns the message with variable name having white space', () => {
    const message = 'hey {{contact.name}} how may I help you?';
    expect(replaceVariablesInMessage({ message, variables })).toBe(
      'hey John Doe how may I help you?'
    );
  });

  it('returns the message with variable email', () => {
    const message =
      'No issues. We will send the reset instructions to your email at {{contact.email}}';
    expect(replaceVariablesInMessage({ message, variables })).toBe(
      'No issues. We will send the reset instructions to your email at john.p@example.com'
    );
  });

  it('returns the message with multiple variables', () => {
    const message =
      'hey {{ contact.name }}, no issues. We will send the reset instructions to your email at {{contact.email}}';
    expect(replaceVariablesInMessage({ message, variables })).toBe(
      'hey John Doe, no issues. We will send the reset instructions to your email at john.p@example.com'
    );
  });

  it('returns the message if the variable is not present in variables', () => {
    const message = 'Please dm me at {{contact.twitter}}';
    expect(replaceVariablesInMessage({ message, variables })).toBe(
      'Please dm me at '
    );
  });
});

describe('#getFirstName', () => {
  it('returns the first name of the contact', () => {
    const assignee = { name: 'John Doe' };
    expect(getFirstName({ user: assignee })).toBe('John');
  });

  it('returns the first name of the contact with multiple names', () => {
    const assignee = { name: 'John Doe Smith' };
    expect(getFirstName({ user: assignee })).toBe('John');
  });
});

describe('#getLastName', () => {
  it('returns the last name of the contact', () => {
    const assignee = { name: 'John Doe' };
    expect(getLastName({ user: assignee })).toBe('Doe');
  });

  it('returns the last name of the contact with multiple names', () => {
    const assignee = { name: 'John Doe Smith' };
    expect(getLastName({ user: assignee })).toBe('Smith');
  });
});

describe('#getMessageVariables', () => {
  it('returns the variables', () => {
    const conversation = {
      meta: {
        assignee: {
          name: 'Samuel Smith',
          email: 'samuel@example.com',
        },
        sender: {
          name: 'John Doe',
          email: 'john.doe@gmail.com',
          phone_number: '1234567890',
        },
      },
      id: 1,
    };
    expect(getMessageVariables({ conversation })).toEqual({
      'contact.name': 'John Doe',
      'contact.first_name': 'John',
      'contact.last_name': 'Doe',
      'contact.email': 'john.doe@gmail.com',
      'contact.phone': '1234567890',
      'conversation.id': 1,
      'agent.name': 'Samuel Smith',
      'agent.first_name': 'Samuel',
      'agent.last_name': 'Smith',
      'agent.email': 'samuel@example.com',
    });
  });
});

describe('#getUndefinedVariablesInMessage', () => {
  it('returns the undefined variables', () => {
    const message = 'Please dm me at {{contact.twitter}}';
    expect(
      getUndefinedVariablesInMessage({ message, variables }).length
    ).toEqual(1);
    expect(getUndefinedVariablesInMessage({ message, variables })).toEqual(
      expect.arrayContaining(['contact.twitter'])
    );
  });
  it('skip variables in string with code blocks', () => {
    const message =
      'hey {{contact_name}} how are you? ``` code: {{contact_name}} ```';
    const undefinedVariables = getUndefinedVariablesInMessage({
      message,
      variables,
    });
    expect(undefinedVariables.length).toEqual(1);
    expect(undefinedVariables).toEqual(
      expect.arrayContaining(['contact_name'])
    );
  });
});
