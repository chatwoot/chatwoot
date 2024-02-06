import {
  ICON_APPEARANCE,
  ICON_LIGHT_MODE,
  ICON_DARK_MODE,
  ICON_SYSTEM_MODE,
} from './CommandBarIcons';
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { setColorTheme } from 'dashboard/helper/themeHelper.js';

export default {
  computed: {
    themeOptions() {
      return [
        {
          key: 'light',
          label: this.$t('COMMAND_BAR.COMMANDS.LIGHT_MODE'),
          icon: ICON_LIGHT_MODE,
        },
        {
          key: 'dark',
          label: this.$t('COMMAND_BAR.COMMANDS.DARK_MODE'),
          icon: ICON_DARK_MODE,
        },

        {
          key: 'auto',
          label: this.$t('COMMAND_BAR.COMMANDS.SYSTEM_MODE'),
          icon: ICON_SYSTEM_MODE,
        },
      ];
    },
    goToAppearanceHotKeys() {
      const options = this.themeOptions.map(theme => ({
        id: theme.key,
        title: theme.label,
        parent: 'appearance_settings',
        section: this.$t('COMMAND_BAR.SECTIONS.APPEARANCE'),
        icon: theme.icon,
        handler: () => {
          this.setAppearance(theme.key);
        },
      }));
      return [
        {
          id: 'appearance_settings',
          title: this.$t('COMMAND_BAR.COMMANDS.CHANGE_APPEARANCE'),
          section: this.$t('COMMAND_BAR.SECTIONS.APPEARANCE'),
          icon: ICON_APPEARANCE,
          children: options.map(option => option.id),
        },
        ...options,
      ];
    },
  },
  methods: {
    setAppearance(theme) {
      LocalStorage.set(LOCAL_STORAGE_KEYS.COLOR_SCHEME, theme);
      const isOSOnDarkMode = window.matchMedia(
        '(prefers-color-scheme: dark)'
      ).matches;
      setColorTheme(isOSOnDarkMode);
    },
  },
};
