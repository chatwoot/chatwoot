import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useContactFilterContext } from 'dashboard/components-next/filter/contactProvider.js';
import {
  sectionHeader,
  withAttributeIcons,
} from 'dashboard/components-next/filter/helper/filterAttributeIcons.js';
import { useOperators } from 'dashboard/components-next/filter/operators.js';
import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages.js';

const I18N_KEY = 'CAPTAIN.ASSISTANTS.FORM.AUDIENCE';

export function useAudienceFilterTypes() {
  const { t } = useI18n();
  const { filterTypes: contactFilterTypes } = useContactFilterContext();
  const { equalityOperators } = useOperators();

  const conversationOption = (key, label, options) => ({
    attributeKey: key,
    value: key,
    attributeName: label,
    label,
    inputType: 'searchSelect',
    options,
    dataType: 'text',
    filterOperators: equalityOperators.value,
    attributeModel: 'additional',
  });

  const conversationTypes = computed(() => [
    conversationOption('hmac_verified', t(`${I18N_KEY}.LOGGED_IN`), [
      { id: 'true', name: t(`${I18N_KEY}.LOGGED_IN_TRUE`) },
      { id: 'false', name: t(`${I18N_KEY}.LOGGED_IN_FALSE`) },
    ]),
    conversationOption(
      'browser_language',
      t(`${I18N_KEY}.BROWSER_LANGUAGE`),
      languages
    ),
  ]);

  // The audience picker sections by where an attribute comes from, not by attributeModel, so
  // every contact attribute stays together regardless of how the contact filter groups it.
  const contactTypes = computed(() =>
    contactFilterTypes.value.filter(
      type => type.attributeModel !== 'customAttributes'
    )
  );

  const customTypes = computed(() =>
    contactFilterTypes.value.filter(
      type => type.attributeModel === 'customAttributes'
    )
  );

  const filterTypes = computed(() => [
    sectionHeader('contact', t(`${I18N_KEY}.GROUP_CONTACT`)),
    ...withAttributeIcons(contactTypes.value),
    sectionHeader('conversation', t(`${I18N_KEY}.GROUP_CONVERSATION`)),
    ...withAttributeIcons(conversationTypes.value),
    ...(customTypes.value.length
      ? [
          sectionHeader('custom', t(`${I18N_KEY}.GROUP_CUSTOM`)),
          ...withAttributeIcons(customTypes.value),
        ]
      : []),
  ]);

  return { filterTypes };
}
