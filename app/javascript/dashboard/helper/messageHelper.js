const MESSAGE_VARIABLES_REGEX = /{{(.*?)}}/g;
export const replaceVariablesInMessage = ({ message, variables }) => {
  return message.replace(MESSAGE_VARIABLES_REGEX, (match, replace) => {
    return variables[replace.trim()]
      ? variables[replace.trim().toLowerCase()]
      : '';
  });
};

const skipCodeBlocks = str => str.replace(/```(?:.|\n)+?```/g, '');

export const getFirstName = ({ user }) => {
  return user?.name ? user.name.split(' ').shift() : '';
};

export const getLastName = ({ user }) => {
  if (user && user.name) {
    return user.name.split(' ').length > 1 ? user.name.split(' ').pop() : '';
  }
  return '';
};

export const getMessageVariables = ({ conversation }) => {
  const {
    meta: { assignee = {}, sender = {} },
    id,
  } = conversation;

  return {
    'contact.name': sender?.name,
    'contact.first_name': getFirstName({ user: sender }),
    'contact.last_name': getLastName({ user: sender }),
    'contact.email': sender?.email,
    'contact.phone': sender?.phone_number,
    'contact.id': sender?.id,
    'conversation.id': id,
    'agent.name': assignee?.name ? assignee?.name : '',
    'agent.first_name': getFirstName({ user: assignee }),
    'agent.last_name': getLastName({ user: assignee }),
    'agent.email': assignee?.email ?? '',
  };
};

export const getUndefinedVariablesInMessage = ({ message, variables }) => {
  const messageWithOutCodeBlocks = skipCodeBlocks(message);
  const matches = messageWithOutCodeBlocks.match(MESSAGE_VARIABLES_REGEX);
  if (!matches) return [];

  return matches
    .map(match => {
      return match
        .replace('{{', '')
        .replace('}}', '')
        .trim();
    })
    .filter(variable => {
      return !variables[variable];
    });
};
