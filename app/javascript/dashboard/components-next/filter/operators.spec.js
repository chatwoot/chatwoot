import { useOperators } from './operators';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

describe('useOperators', () => {
  const operatorValuesFor = attributeDisplayType =>
    useOperators()
      .getOperatorTypes(attributeDisplayType)
      .map(operator => operator.value);

  describe('getOperatorTypes', () => {
    it.each(['list', 'number', 'link', 'checkbox', 'unknown'])(
      'offers equality and presence operators for the %s type',
      attributeDisplayType => {
        expect(operatorValuesFor(attributeDisplayType)).toEqual([
          'equal_to',
          'not_equal_to',
          'is_present',
          'is_not_present',
        ]);
      }
    );

    it('offers containment and presence operators for the text type', () => {
      expect(operatorValuesFor('text')).toEqual([
        'equal_to',
        'not_equal_to',
        'contains',
        'does_not_contain',
        'is_present',
        'is_not_present',
      ]);
    });

    it('offers comparison operators for the date type', () => {
      expect(operatorValuesFor('date')).toEqual([
        'equal_to',
        'not_equal_to',
        'is_present',
        'is_not_present',
        'is_greater_than',
        'is_less_than',
      ]);
    });
  });

  it('marks presence operators as not requiring an input', () => {
    const { operators } = useOperators();

    expect(operators.value.is_present.hasInput).toBe(false);
    expect(operators.value.is_not_present.hasInput).toBe(false);
    expect(operators.value.equal_to.hasInput).toBe(true);
  });
});
