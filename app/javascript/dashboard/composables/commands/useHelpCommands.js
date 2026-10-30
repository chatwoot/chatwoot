import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { SHORTCUT_KEYS } from 'dashboard/components/widgets/modal/constants';
import { shortcutKeys } from 'dashboard/helper/commandbar/shortcuts';

const DOCS_URL = 'https://www.chatwoot.com/hc/user-guide/en';

const joinBindings = bindings =>
  bindings.flatMap((binding, index) =>
    index ? ['/', ...shortcutKeys(binding)] : shortcutKeys(binding)
  );

export function useHelpCommands() {
  const { t } = useI18n();
  const isCustomBranded = useMapGetter('globalConfig/isACustomBrandedInstance');

  const helpCommands = computed(() => {
    const section = t('COMMAND_BAR.SECTIONS.HELP');
    return [
      ...(isCustomBranded.value
        ? []
        : [
            {
              id: 'read_docs',
              title: t('SIDEBAR_ITEMS.DOCS'),
              section,
              icon: 'i-lucide-book',
              run: () => window.open(DOCS_URL, '_blank', 'noopener'),
            },
          ]),
      {
        id: 'keyboard_shortcuts',
        title: t('COMMAND_BAR.COMMANDS.KEYBOARD_SHORTCUTS'),
        section,
        icon: 'i-lucide-keyboard',
        shortcut: shortcutKeys('$mod+Slash'),
        page: true,
      },
      ...SHORTCUT_KEYS.map(shortcut => ({
        id: `shortcut-${shortcut.label}`,
        title: t(`KEYBOARD_SHORTCUTS.TITLE.${shortcut.label}`),
        parent: 'keyboard_shortcuts',
        section,
        prefix: '?',
        searchFromRoot: false,
        shortcut: joinBindings(shortcut.keySet),
      })),
    ];
  });

  return { helpCommands };
}
