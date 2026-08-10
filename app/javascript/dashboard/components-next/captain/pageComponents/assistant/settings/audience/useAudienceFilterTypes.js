import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useContactFilterContext } from 'dashboard/components-next/filter/contactProvider.js';
import { groupFilterTypes } from 'dashboard/components-next/filter/helper/filterAttributeIcons.js';
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

  // Contact attributes carry attributeModel 'standard' / 'customAttributes', so grouping them
  // alongside the conversation options lands them under the audience section titles.
  const filterTypes = computed(() =>
    groupFilterTypes(
      [...contactFilterTypes.value, ...conversationTypes.value],
      t,
      I18N_KEY
    )
  );

  return { filterTypes };
}
