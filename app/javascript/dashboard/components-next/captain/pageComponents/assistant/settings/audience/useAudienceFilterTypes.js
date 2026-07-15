import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useContactFilterContext } from 'dashboard/components-next/filter/contactProvider.js';
import { useOperators } from 'dashboard/components-next/filter/operators.js';
import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages.js';

const STANDARD_ICONS = {
  name: 'i-lucide-user',
  email: 'i-lucide-mail',
  phone_number: 'i-lucide-phone',
  identifier: 'i-lucide-fingerprint',
  country_code: 'i-lucide-flag',
  city: 'i-lucide-map-pin',
  company_name: 'i-lucide-building-2',
  created_at: 'i-lucide-calendar',
  last_activity_at: 'i-lucide-activity',
  blocked: 'i-lucide-ban',
  labels: 'i-lucide-tags',
  hmac_verified: 'i-lucide-user-check',
  browser_language: 'i-lucide-globe',
  conversation_language: 'i-lucide-languages',
};

const CUSTOM_TYPE_ICONS = {
  text: 'i-lucide-type',
  number: 'i-lucide-hash',
  currency: 'i-lucide-banknote',
  percent: 'i-lucide-percent',
  link: 'i-lucide-link',
  date: 'i-lucide-calendar',
  list: 'i-lucide-list',
  checkbox: 'i-lucide-square-check',
};

const DEFAULT_ICON = 'i-lucide-tag';

/**
 * Filter types for a Captain assistant audience: contact attributes (reused from the contact
 * segment builder) plus conversation-scoped fields, grouped via disabled header options.
 */
export function useAudienceFilterTypes() {
  const { t } = useI18n();
  const { filterTypes: contactFilterTypes } = useContactFilterContext();
  const { equalityOperators } = useOperators();
  const contactAttributes = useMapGetter('attributes/getContactAttributes');

  const customTypeByKey = computed(() =>
    Object.fromEntries(
      (contactAttributes.value || []).map(attr => [
        attr.attributeKey,
        attr.attributeDisplayType,
      ])
    )
  );

  const conversationOption = (key, label, options) => ({
    attributeKey: key,
    value: key,
    attributeName: label,
    label,
    icon: STANDARD_ICONS[key],
    inputType: 'searchSelect',
    options,
    dataType: 'text',
    filterOperators: equalityOperators.value,
    attributeModel: 'additional',
  });

  const conversationFilterTypes = computed(() => [
    conversationOption(
      'hmac_verified',
      t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.LOGGED_IN'),
      [
        {
          id: 'true',
          name: t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.LOGGED_IN_TRUE'),
        },
        {
          id: 'false',
          name: t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.LOGGED_IN_FALSE'),
        },
      ]
    ),
    conversationOption(
      'browser_language',
      t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.BROWSER_LANGUAGE'),
      languages
    ),
    conversationOption(
      'conversation_language',
      t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.CONVERSATION_LANGUAGE'),
      languages
    ),
  ]);

  const header = (id, label) => ({
    value: `__group_${id}`,
    label,
    disabled: true,
  });

  const filterTypes = computed(() => {
    const standard = contactFilterTypes.value
      .filter(type => type.attributeModel !== 'customAttributes')
      .map(type => ({
        ...type,
        icon: STANDARD_ICONS[type.attributeKey] || DEFAULT_ICON,
      }));

    // Only contact-model custom attributes belong here; never conversation/company ones.
    const custom = contactFilterTypes.value
      .filter(type => type.attributeModel === 'customAttributes')
      .filter(type => type.attributeKey in customTypeByKey.value)
      .map(type => ({
        ...type,
        icon:
          CUSTOM_TYPE_ICONS[customTypeByKey.value[type.attributeKey]] ||
          DEFAULT_ICON,
      }));

    return [
      header('contact', t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.GROUP_CONTACT')),
      ...standard,
      header(
        'conversation',
        t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.GROUP_CONVERSATION')
      ),
      ...conversationFilterTypes.value,
      ...(custom.length
        ? [
            header(
              'custom',
              t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.GROUP_CUSTOM')
            ),
            ...custom,
          ]
        : []),
    ];
  });

  return { filterTypes };
}
