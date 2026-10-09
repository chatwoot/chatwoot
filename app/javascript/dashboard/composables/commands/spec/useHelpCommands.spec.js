import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useHelpCommands } from '../useHelpCommands';
import { SHORTCUT_KEYS } from 'dashboard/components/widgets/modal/constants';

vi.mock('vue-i18n');
vi.mock('dashboard/composables/store');

describe('useHelpCommands', () => {
  let customBranded;

  beforeEach(() => {
    customBranded = false;
    useI18n.mockReturnValue({ t: key => key });
    useMapGetter.mockImplementation(() => ({
      get value() {
        return customBranded;
      },
    }));
  });

  it('links to the documentation unless the instance is custom branded', () => {
    expect(useHelpCommands().helpCommands.value[0].id).toBe('read_docs');
    customBranded = true;
    expect(useHelpCommands().helpCommands.value[0].id).toBe(
      'keyboard_shortcuts'
    );
  });

  it('lists every keyboard shortcut under a help page with the ? prefix', () => {
    const { helpCommands } = useHelpCommands();
    const [, page, ...shortcuts] = helpCommands.value;

    expect(page).toEqual(
      expect.objectContaining({ id: 'keyboard_shortcuts', page: true })
    );
    expect(shortcuts).toHaveLength(SHORTCUT_KEYS.length);
    expect(shortcuts[0]).toEqual(
      expect.objectContaining({
        parent: 'keyboard_shortcuts',
        prefix: '?',
        searchFromRoot: false,
        title: 'KEYBOARD_SHORTCUTS.TITLE.OPEN_CONVERSATION',
      })
    );
    expect(shortcuts[0].shortcut.length).toBeGreaterThan(1);
  });
});
