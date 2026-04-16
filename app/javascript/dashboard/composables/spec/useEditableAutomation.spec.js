import { useEditableAutomation } from '../useEditableAutomation';
import useAutomationValues from '../useAutomationValues';

vi.mock('../useAutomationValues');

describe('useEditableAutomation', () => {
  beforeEach(() => {
    useAutomationValues.mockReturnValue({
      getConditionDropdownValues: vi.fn(attributeKey => {
        if (attributeKey === 'private_note') {
          return [
            { id: true, name: 'True' },
            { id: false, name: 'False' },
          ];
        }

        return [];
      }),
      getActionDropdownValues: vi.fn(),
    });
  });

  it('rehydrates boolean conditions as a single selected option', () => {
    const automation = {
      event_name: 'message_created',
      conditions: [
        {
          attribute_key: 'private_note',
          filter_operator: 'equal_to',
          values: [false],
          query_operator: null,
        },
      ],
      actions: [],
    };
    const automationTypes = {
      message_created: {
        conditions: [{ key: 'private_note', inputType: 'search_select' }],
      },
    };

    const { formatAutomation } = useEditableAutomation();
    const result = formatAutomation(automation, [], automationTypes, []);

    expect(result.conditions).toEqual([
      {
        attribute_key: 'private_note',
        filter_operator: 'equal_to',
        values: { id: false, name: 'False' },
        query_operator: 'and',
      },
    ]);
  });
});
