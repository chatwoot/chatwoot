import { nextTick, reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useBackCommands } from '../useBackCommands';

vi.mock('vue-i18n');
vi.mock('vue-router');

describe('useBackCommands', () => {
  let route;

  beforeEach(() => {
    route = reactive({ fullPath: '/app/accounts/1/conversations/12' });
    useI18n.mockReturnValue({
      t: (key, params) => (params ? `${key}:${params.page}` : key),
    });
    useRoute.mockReturnValue(route);
    useRouter.mockReturnValue({ push: vi.fn() });
  });

  it('offers nothing until the user has moved to another area', async () => {
    const { backCommands } = useBackCommands();
    expect(backCommands.value).toEqual([]);

    route.fullPath = '/app/accounts/1/conversations/13';
    await nextTick();
    expect(backCommands.value).toEqual([]);
  });

  it('leads back to the area the user came from', async () => {
    const { backCommands } = useBackCommands();
    route.fullPath = '/app/accounts/1/contacts/5';
    await nextTick();

    const [command] = backCommands.value;
    expect(command).toEqual(
      expect.objectContaining({
        id: 'back',
        title: 'COMMAND_BAR.COMMANDS.BACK_TO:SIDEBAR.CONVERSATIONS',
        section: 'COMMAND_BAR.SECTIONS.PAGE',
        place: 'first',
      })
    );
    command.run();
    expect(useRouter().push).toHaveBeenCalledWith(
      '/app/accounts/1/conversations/12'
    );
  });

  it('keeps pointing at the previous area while the user stays in the new one', async () => {
    const { backCommands } = useBackCommands();
    route.fullPath = '/app/accounts/1/settings/agents/list';
    await nextTick();
    route.fullPath = '/app/accounts/1/settings/teams/list';
    await nextTick();

    expect(backCommands.value[0].title).toBe(
      'COMMAND_BAR.COMMANDS.BACK_TO:SIDEBAR.CONVERSATIONS'
    );
  });

  it('stays quiet for areas it cannot name', async () => {
    route.fullPath = '/app/accounts/1/search';
    const { backCommands } = useBackCommands();
    route.fullPath = '/app/accounts/1/contacts';
    await nextTick();

    expect(backCommands.value).toEqual([]);
  });
});
