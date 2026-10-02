import { picoSearch } from '@chatwoot/pico-search';

// "Olá" → "Ola". Recomposing afterwards keeps every character at its original index, so a
// match found in the stripped text can be sliced out of the original.
export const removeAccents = text =>
  text
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .normalize('NFC');

const fold = text => removeAccents(text).toLowerCase();

const foldFields = (record, fields) =>
  Object.fromEntries(
    fields.map(field => {
      const value = record[field];
      return [field, typeof value === 'string' ? removeAccents(value) : value];
    })
  );

// Drop-in for `picoSearch` that ignores accents, so "ola" finds "Olá" and "olá" finds "Hola".
// Takes the same arguments and returns the original records in picoSearch's order.
export const searchIgnoringAccents = (records, term, keys, options) => {
  const fields = keys.map(key => (typeof key === 'string' ? key : key.name));
  // picoSearch returns the objects it was given, so each folded copy maps back to its record
  const recordsByCopy = new Map(
    records.map(record => [foldFields(record, fields), record])
  );

  return picoSearch(
    [...recordsByCopy.keys()],
    removeAccents(term),
    keys,
    options
  ).map(copy => recordsByCopy.get(copy));
};

// Position of `term` in `text`, ignoring accents and case
export const indexOfIgnoringAccents = (text, term) =>
  fold(text).indexOf(fold(term));
