import pickBy from 'lodash/pickBy';

const matches = (name, descriptor) => Array.isArray(descriptor) ? descriptor.includes(name) : name.match(descriptor);

export const filterArgTypes = (argTypes, include, exclude) => {
  if (!include && !exclude) {
    return argTypes;
  }

  return argTypes && pickBy(argTypes, (argType, key) => {
    const name = argType.name || key;
    return (!include || matches(name, include)) && (!exclude || !matches(name, exclude));
  });
};