import { MESSAGE_VARIABLES } from 'shared/constants/messages';

/**
 * Build Liquid variable catalog for message editors / campaign templates.
 * @param {Array} customAttributes - Vuex attributes/getAttributes records
 * @param {'campaign'|'message'} context
 * @returns {{ key: string, label: string, description: string }[]}
 */
export const buildLiquidVariables = (
  customAttributes = [],
  context = 'message'
) => {
  const isCampaign = context === 'campaign';

  const standardVariables = MESSAGE_VARIABLES.filter(variable => {
    if (isCampaign && variable.key.startsWith('conversation.')) {
      return false;
    }
    return true;
  }).map(variable => ({
    key: variable.key,
    label: variable.label,
    description: variable.label,
  }));

  const customVariables = (customAttributes || [])
    .filter(attribute => {
      if (attribute.attribute_model === 'conversation_attribute') {
        return !isCampaign;
      }
      // contact (and any non-conversation) custom attrs stay available
      return true;
    })
    .map(attribute => {
      const attributePrefix =
        attribute.attribute_model === 'conversation_attribute'
          ? 'conversation'
          : 'contact';
      const key = `${attributePrefix}.custom_attribute.${attribute.attribute_key}`;

      return {
        key,
        label: attribute.attribute_display_name || attribute.attribute_key,
        description:
          attribute.attribute_description ||
          attribute.attribute_display_name ||
          attribute.attribute_key,
      };
    });

  return [...standardVariables, ...customVariables];
};

/** Liquid tag with spaces: `{{ contact.first_name }}` */
export const formatLiquidVariable = key => `{{ ${key} }}`;
