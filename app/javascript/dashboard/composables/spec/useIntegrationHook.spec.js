import { useIntegrationHook } from '../useIntegrationHook';
import { useMapGetter } from 'dashboard/composables/store';
import { nextTick } from 'vue';

vi.mock('dashboard/composables/store');

describe('useIntegrationHook', () => {
  let integrationGetter;

  beforeEach(() => {
    integrationGetter = vi.fn();
    useMapGetter.mockReturnValue({ value: integrationGetter });
  });

  it('should return the correct computed properties', async () => {
    const mockIntegration = {
      id: 1,
      hook_type: 'inbox',
      hooks: ['hook1', 'hook2'],
      allow_multiple_hooks: true,
    };
    integrationGetter.mockReturnValue(mockIntegration);

    const hook = useIntegrationHook(1);

    await nextTick();

    expect(hook.integration.value).toEqual(mockIntegration);
    expect(hook.integrationType.value).toBe('multiple');
    expect(hook.isIntegrationMultiple.value).toBe(true);
    expect(hook.isIntegrationSingle.value).toBe(false);
    expect(hook.isHookTypeInbox.value).toBe(true);
    expect(hook.hasConnectedHooks.value).toBe(true);
  });

  it('should handle single integration type correctly', async () => {
    const mockIntegration = {
      id: 2,
      hook_type: 'channel',
      hooks: [],
      allow_multiple_hooks: false,
    };
    integrationGetter.mockReturnValue(mockIntegration);

    const hook = useIntegrationHook(2);

    await nextTick();

    expect(hook.integration.value).toEqual(mockIntegration);
    expect(hook.integrationType.value).toBe('single');
    expect(hook.isIntegrationMultiple.value).toBe(false);
    expect(hook.isIntegrationSingle.value).toBe(true);
    expect(hook.isHookTypeInbox.value).toBe(false);
    expect(hook.hasConnectedHooks.value).toBe(false);
  });
});
