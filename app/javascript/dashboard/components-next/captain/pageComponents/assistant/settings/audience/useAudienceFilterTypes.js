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

const header = (id, label) => ({
  value: `__group_${id}`,
  label,
  disabled: true,
});

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

  const conversationTypes = computed(() => [
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
  ]);

  const standardTypes = computed(() =>
    contactFilterTypes.value
      .filter(type => type.attributeModel !== 'customAttributes')
      .map(type => ({
        ...type,
        icon: STANDARD_ICONS[type.attributeKey] || DEFAULT_ICON,
      }))
  );

  const customTypes = computed(() =>
    contactFilterTypes.value
      .filter(type => type.attributeModel === 'customAttributes')
      .filter(type => type.attributeKey in customTypeByKey.value)
      .map(type => ({
        ...type,
        icon:
          CUSTOM_TYPE_ICONS[customTypeByKey.value[type.attributeKey]] ||
          DEFAULT_ICON,
      }))
  );

  const filterTypes = computed(() => [
    header('contact', t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.GROUP_CONTACT')),
    ...standardTypes.value,
    header(
      'conversation',
      t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.GROUP_CONVERSATION')
    ),
    ...conversationTypes.value,
    ...(customTypes.value.length
      ? [
          header('custom', t('CAPTAIN.ASSISTANTS.FORM.AUDIENCE.GROUP_CUSTOM')),
          ...customTypes.value,
        ]
      : []),
  ]);

  return { filterTypes };
}
