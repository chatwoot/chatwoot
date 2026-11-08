import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { setColorTheme } from 'dashboard/helper/themeHelper.js';

const THEMES = [
  {
    key: 'light',
    title: 'COMMAND_BAR.COMMANDS.LIGHT_MODE',
    icon: 'i-lucide-sun',
  },
  {
    key: 'dark',
    title: 'COMMAND_BAR.COMMANDS.DARK_MODE',
    icon: 'i-lucide-moon',
  },
  {
    key: 'auto',
    title: 'COMMAND_BAR.COMMANDS.SYSTEM_MODE',
    icon: 'i-lucide-monitor',
  },
];

const setAppearance = theme => {
  LocalStorage.set(LOCAL_STORAGE_KEYS.COLOR_SCHEME, theme);
  const isOSOnDarkMode = window.matchMedia(
    '(prefers-color-scheme: dark)'
  ).matches;
  setColorTheme(isOSOnDarkMode);
};

export function useAppearanceCommands() {
  const { t } = useI18n();

  const appearanceCommands = computed(() => {
    const section = t('COMMAND_BAR.SECTIONS.APPEARANCE');
    return [
      {
        id: 'appearance_settings',
        title: t('COMMAND_BAR.COMMANDS.CHANGE_APPEARANCE'),
        section,
        icon: 'i-lucide-palette',
        page: true,
      },
      ...THEMES.map(theme => ({
        id: `appearance-${theme.key}`,
        title: t(theme.title),
        parent: 'appearance_settings',
        section,
        icon: theme.icon,
        run: () => setAppearance(theme.key),
      })),
    ];
  });

  return { appearanceCommands };
}
