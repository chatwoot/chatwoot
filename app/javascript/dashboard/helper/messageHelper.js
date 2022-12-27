const MESSAGE_VARIABLES_REGEX = /{{(.*?)}}/g;
export const replaceVariablesInMessage = ({ message, variables }) => {
  return message.replace(MESSAGE_VARIABLES_REGEX, (match, replace) => {
    return variables[replace.trim()]
      ? variables[replace.trim().toLowerCase()]
      : '';
  });
};

const skipCodeBlocks = str => str.replace(/```(?:.|\n)+?```/g, '');

export const getFirstName = ({ name }) => {
  return name.split(' ')[0];
};

export const getLastName = ({ name }) => {
  return name.split(' ').length > 1
    ? name.split(' ')[name.split(' ').length - 1]
    : '';
};

export const getMessageVariables = ({ conversation }) => {
  const {
    meta: { assignee = {}, sender = {} },
    id,
  } = conversation;

  return {
    'contact.name': sender?.name,
    'contact.first_name': getFirstName({ name: sender?.name }),
    'contact.last_name': getLastName({ name: sender?.name }),
    'contact.email': sender?.email,
    'contact.phone': sender?.phone_number,
    'conversation.id': id,
    'agent.name': assignee?.name ? assignee?.name : '',
    'agent.first_name': assignee?.name
      ? getFirstName({ name: assignee?.name })
      : '',
    'agent.last_name': assignee?.name
      ? getLastName({ name: assignee?.name })
      : '',
    'agent.email': assignee?.email ? assignee?.email : '',
  };
};

export const getUndefinedVariablesInMessage = ({ message, variables }) => {
  const messageWithOutCodeBlocks = skipCodeBlocks(message);
  const matches = messageWithOutCodeBlocks.match(MESSAGE_VARIABLES_REGEX);
  const undefinedVariables = [];
  if (!matches) {
    return [];
  }
  matches.forEach(match => {
    const variable = match
      .replace('{{', '')
      .replace('}}', '')
      .trim();
    if (!variables[variable]) {
      undefinedVariables.push(match);
    }
  });
  return undefinedVariables;
};
