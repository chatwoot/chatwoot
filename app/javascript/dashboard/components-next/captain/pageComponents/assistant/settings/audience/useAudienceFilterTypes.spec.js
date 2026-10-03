import languages from 'dashboard/components/widgets/conversation/advancedFilterItems/languages.js';
import { useAudienceFilterTypes } from './useAudienceFilterTypes';

const state = vi.hoisted(() => ({
  contactFilterTypes: [],
  contactAttributes: [],
  equalityOperators: [{ value: 'equal_to' }, { value: 'not_equal_to' }],
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/composables/store.js', () => ({
  useMapGetter: () => ({ value: state.contactAttributes }),
}));

vi.mock('dashboard/components-next/filter/contactProvider.js', () => ({
  useContactFilterContext: () => ({
    filterTypes: { value: state.contactFilterTypes },
  }),
}));

vi.mock('dashboard/components-next/filter/operators.js', () => ({
  useOperators: () => ({
    equalityOperators: { value: state.equalityOperators },
  }),
}));

describe('useAudienceFilterTypes', () => {
  beforeEach(() => {
    state.contactFilterTypes = [
      { attributeKey: 'email', attributeModel: 'standard' },
      { attributeKey: 'mystery', attributeModel: 'standard' },
      { attributeKey: 'signed_up_on', attributeModel: 'customAttributes' },
      { attributeKey: 'company_size', attributeModel: 'customAttributes' },
    ];
    state.contactAttributes = [
      { attributeKey: 'signed_up_on', attributeDisplayType: 'date' },
    ];
  });

  const build = () => useAudienceFilterTypes().filterTypes.value;

  it('assembles grouped sections in order', () => {
    const keys = build().map(item => item.attributeKey ?? item.value);
    expect(keys).toEqual([
      '__group_contact',
      'email',
      'mystery',
      '__group_conversation',
      'hmac_verified',
      'browser_language',
      '__group_custom',
      'signed_up_on',
    ]);
  });

  it('marks headers as disabled options', () => {
    const headers = build().filter(item => item.value?.startsWith('__group_'));
    expect(headers).toHaveLength(3);
    expect(headers.every(header => header.disabled)).toBe(true);
  });

  it('excludes custom attributes that are not contact-model attributes', () => {
    const keys = build().map(item => item.attributeKey);
    expect(keys).not.toContain('company_size');
  });

  it('omits the custom section when there are no contact custom attributes', () => {
    state.contactAttributes = [];
    const values = build().map(item => item.attributeKey ?? item.value);
    expect(values).not.toContain('__group_custom');
    expect(values).not.toContain('signed_up_on');
  });

  it('assigns icons by attribute key with a default fallback', () => {
    const byKey = Object.fromEntries(
      build().map(item => [item.attributeKey, item.icon])
    );
    expect(byKey.email).toBe('i-lucide-mail');
    expect(byKey.mystery).toBe('i-lucide-tag');
    expect(byKey.signed_up_on).toBe('i-lucide-calendar');
  });

  it('builds conversation options as searchSelects with equality operators', () => {
    const types = build();
    const hmac = types.find(item => item.attributeKey === 'hmac_verified');
    expect(hmac.inputType).toBe('searchSelect');
    expect(hmac.filterOperators).toEqual(state.equalityOperators);
    expect(hmac.options.map(option => option.id)).toEqual(['true', 'false']);

    const browserLanguage = types.find(
      item => item.attributeKey === 'browser_language'
    );
    expect(browserLanguage.options).toEqual(languages);
  });
});
