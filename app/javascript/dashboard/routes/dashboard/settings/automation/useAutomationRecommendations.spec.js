import { computed, effectScope, ref } from 'vue';
import { flushPromises } from '@vue/test-utils';
import FilterRecommendationsApi from 'dashboard/api/filterRecommendations';
import { useAutomationRecommendations } from './useAutomationRecommendations';

vi.mock('dashboard/api/filterRecommendations', () => ({
  default: { create: vi.fn() },
}));

vi.mock('dashboard/composables/useTranslationPlan', async () => {
  const { ref: vueRef } = await import('vue');
  return { useTranslationPlan: () => ({ isAvailable: vueRef(true) }) };
});

const FILTER_TYPES_BY_EVENT = {
  conversation_created: [{ attributeKey: 'status', label: 'Status' }],
  message_created: [
    { attributeKey: 'content', label: 'Content', inputType: 'multiText' },
    {
      attributeKey: 'message_type',
      label: 'Message type',
      inputType: 'plainText',
    },
  ],
};
const ACTION_TYPES = [
  { key: 'add_label', label: 'Add a label', inputType: 'multi_select' },
];
const LABEL_OPTIONS = [{ id: 'bug', name: 'bug' }];

const setup = ({ canSetEvent = true } = {}) => {
  const automation = ref({
    name: '',
    description: '',
    event_name: 'conversation_created',
    conditions: [{ attribute_key: 'status', values: [] }],
    actions: [{ action_name: 'assign_agent', action_params: [] }],
  });
  const setEvent = vi.fn(eventName => {
    automation.value.event_name = eventName;
  });
  const scope = effectScope();
  const result = scope.run(() =>
    useAutomationRecommendations({
      automation,
      filterTypes: computed(
        () => FILTER_TYPES_BY_EVENT[automation.value.event_name]
      ),
      eventConditionKeys: computed(() => ({
        conversation_created: ['status'],
        message_created: ['content', 'message_type'],
      })),
      canSetEvent: computed(() => canSetEvent),
      setEvent,
      actionTypes: computed(() => ACTION_TYPES),
      getActionDropdownValues: () => LABEL_OPTIONS,
    })
  );
  return { automation, result, scope, setEvent };
};

// The form asks when the description loses focus.
const describeRule = async (automation, result) => {
  automation.value.name = 'Add bug label';
  await result.recommend();
  await flushPromises();
};

describe('useAutomationRecommendations', () => {
  beforeEach(() => {
    FilterRecommendationsApi.create.mockResolvedValue({
      data: {
        event_name: 'message_created',
        payload: [
          {
            attribute_key: 'message_type',
            filter_operator: 'equal_to',
            values: ['incoming'],
          },
          {
            attribute_key: 'content',
            filter_operator: 'contains',
            values: ['bug'],
          },
        ],
        actions: [{ action_name: 'add_label', action_params: ['bug'] }],
      },
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('does not ask again while the name and description are unchanged', async () => {
    const { automation, result, scope } = setup();

    await describeRule(automation, result);
    await result.recommend();
    await result.recommend({ force: true });

    expect(FilterRecommendationsApi.create).toHaveBeenCalledTimes(2);
    scope.stop();
  });

  it('sets the recommended event and offers its conditions and the actions', async () => {
    const { automation, result, scope, setEvent } = setup();

    await describeRule(automation, result);

    expect(setEvent).toHaveBeenCalledWith('message_created');
    expect(
      result.conditionRecommendations.value.map(item => item.label)
    ).toEqual(['Message type equal_to incoming', 'Content contains bug']);
    expect(result.actionRecommendations.value.map(item => item.label)).toEqual([
      'Add a label: bug',
    ]);
    scope.stop();
  });

  it('replaces the row with a recommendation and stops offering it', async () => {
    const { automation, result, scope } = setup();
    await describeRule(automation, result);
    const [first, second] = result.conditionRecommendations.value;

    expect(result.applyConditionRecommendation(0, first.key)).toBe(true);
    expect(automation.value.conditions[0]).toMatchObject({
      attribute_key: 'message_type',
      filter_operator: 'equal_to',
    });
    expect(result.conditionRecommendations.value).toHaveLength(1);

    automation.value.conditions.push({ attribute_key: 'status', values: [] });
    expect(result.applyConditionRecommendation(1, second.key)).toBe(false);
    expect(automation.value.conditions[1].attribute_key).toBe('content');

    const [action] = result.actionRecommendations.value;
    expect(result.applyActionRecommendation(0, action.key)).toBe(false);
    expect(automation.value.actions[0]).toEqual({
      action_name: 'add_label',
      action_params: LABEL_OPTIONS,
    });
    scope.stop();
  });

  it('keeps the event the person picked', async () => {
    const { automation, result, scope, setEvent } = setup({
      canSetEvent: false,
    });

    await describeRule(automation, result);

    expect(FilterRecommendationsApi.create).toHaveBeenCalledWith(
      expect.objectContaining({ events: undefined }),
      expect.anything()
    );
    expect(setEvent).not.toHaveBeenCalled();
    scope.stop();
  });
});
