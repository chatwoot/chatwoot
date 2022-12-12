import { combineParameters } from '@storybook/store';
export const enhanceArgTypes = context => {
  const {
    component,
    argTypes: userArgTypes,
    parameters: {
      docs = {}
    }
  } = context;
  const {
    extractArgTypes
  } = docs;
  const extractedArgTypes = extractArgTypes && component ? extractArgTypes(component) : {};
  const withExtractedTypes = extractedArgTypes ? combineParameters(extractedArgTypes, userArgTypes) : userArgTypes;
  return withExtractedTypes;
};