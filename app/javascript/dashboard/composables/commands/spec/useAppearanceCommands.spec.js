import { useAppearanceCommands } from '../useAppearanceCommands';
import { useI18n } from 'vue-i18n';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { setColorTheme } from 'dashboard/helper/themeHelper.js';

vi.mock('vue-i18n');
vi.mock('shared/helpers/localStorage');
vi.mock('dashboard/helper/themeHelper.js');

describe('useAppearanceCommands', () => {
  beforeEach(() => {
    useI18n.mockReturnValue({
      t: vi.fn(key => key),
    });

    window.matchMedia = vi.fn().mockReturnValue({ matches: false });
  });

  it('should return appearanceCommands computed property', () => {
    const { appearanceCommands } = useAppearanceCommands();
    expect(appearanceCommands.value).toBeDefined();
  });

  it('should have the correct number of appearance options', () => {
    const { appearanceCommands } = useAppearanceCommands();
    expect(appearanceCommands.value.length).toBe(4); // 1 parent + 3 theme options
  });

  it('should have the correct parent option', () => {
    const { appearanceCommands } = useAppearanceCommands();
    const parentOption = appearanceCommands.value.find(
      option => option.id === 'appearance_settings'
    );
    expect(parentOption.page).toBe(true);
  });

  it('should have the correct theme options', () => {
    const { appearanceCommands } = useAppearanceCommands();
    const themeOptions = appearanceCommands.value.filter(
      option => option.parent === 'appearance_settings'
    );
    expect(themeOptions.length).toBe(3);
    expect(themeOptions.map(option => option.id)).toEqual([
      'appearance-light',
      'appearance-dark',
      'appearance-auto',
    ]);
  });

  it('should call setAppearance when a theme option is selected', () => {
    const { appearanceCommands } = useAppearanceCommands();
    const lightThemeOption = appearanceCommands.value.find(
      option => option.id === 'appearance-light'
    );

    lightThemeOption.run();

    expect(LocalStorage.set).toHaveBeenCalledWith(
      LOCAL_STORAGE_KEYS.COLOR_SCHEME,
      'light'
    );
    expect(setColorTheme).toHaveBeenCalledWith(false);
  });

  it('should handle system dark mode preference', () => {
    window.matchMedia = vi.fn().mockReturnValue({ matches: true });

    const { appearanceCommands } = useAppearanceCommands();
    const autoThemeOption = appearanceCommands.value.find(
      option => option.id === 'appearance-auto'
    );

    autoThemeOption.run();

    expect(LocalStorage.set).toHaveBeenCalledWith(
      LOCAL_STORAGE_KEYS.COLOR_SCHEME,
      'auto'
    );
    expect(setColorTheme).toHaveBeenCalledWith(true);
  });
});
