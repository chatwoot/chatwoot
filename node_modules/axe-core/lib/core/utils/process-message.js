import { incompleteFallbackMessage } from '../reporters/helpers';

const dataRegex = /\$\{\s?data\s?\}/g;

/**
 * Replace a placeholder with the value of a data string or object
 * @param {String} str
 * @param {String|Object} data
 */
function substitute(str, data) {
  // replace all instances of ${ data } with the value of the string
  if (typeof data === 'string') {
    return str.replace(dataRegex, data);
  }

  // replace all instances of ${ data[prop] } with the value of the property
  for (const prop in data) {
    if (data.hasOwnProperty(prop)) {
      const regex = new RegExp('\\${\\s?data\\.' + prop + '\\s?}', 'g');
      const replace =
        typeof data[prop] === 'undefined' ? '' : String(data[prop]);
      str = str.replace(regex, replace);
    }
  }

  return str;
}

/**
 * Process a metadata message.
 * @param {String|Object} message
 * @param {Object} data
 * @return {String}
 */
function processMessage(message, data) {
  if (!message) {
    return;
  }

  // data as array
  if (Array.isArray(data)) {
    data.values = data.join(', ');

    if (
      typeof message.singular === 'string' &&
      typeof message.plural === 'string'
    ) {
      const str = data.length === 1 ? message.singular : message.plural;
      return substitute(str, data);
    }

    // no singular/plural message so just pass data
    return substitute(message, data);
  }

  // message is a string that uses data as a string or object properties
  if (typeof message === 'string') {
    return substitute(message, data);
  }

  // message is an object that uses value of data to determine message
  if (typeof data === 'string') {
    const str = message[data];
    return substitute(str, data);
  }

  // message uses value of data property to determine message
  let str = message.default || incompleteFallbackMessage();

  if (data && data.messageKey && message[data.messageKey]) {
    str = message[data.messageKey];
  }

  return processMessage(str, data);
}

export default processMessage;
