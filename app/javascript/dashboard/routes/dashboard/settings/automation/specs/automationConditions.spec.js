import { getAutomationCondition } from '../automationConditions';

describe('#getAutomationCondition', () => {
  it('returns messaged created conditions if message_created action type passed', () => {
    expect(getAutomationCondition({ actionType: 'messaged_created' })).toEqual([
      {
        attributeKey: 'status',
        attributeI18nKey: 'STATUS',
        inputType: 'multi_select',
        dataType: 'text',
        filterOperators: [
          {
            value: 'equal_to',
            label: 'Equal to',
          },
          {
            value: 'not_equal_to',
            label: 'Not equal to',
          },
        ],
        attribute_type: 'standard',
      },
    ]);
  });
});
