import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { pathArea } from 'dashboard/modules/command-bar/commands';

const AREA_LABELS = {
  conversations: 'SIDEBAR.CONVERSATIONS',
  dashboard: 'SIDEBAR.CONVERSATIONS',
  inbox: 'SIDEBAR.CONVERSATIONS',
  label: 'SIDEBAR.CONVERSATIONS',
  team: 'SIDEBAR.CONVERSATIONS',
  mentions: 'SIDEBAR.CONVERSATIONS',
  participating: 'SIDEBAR.CONVERSATIONS',
  unattended: 'SIDEBAR.CONVERSATIONS',
  custom_view: 'SIDEBAR.CONVERSATIONS',
  'inbox-view': 'SIDEBAR.INBOX',
  contacts: 'SIDEBAR.CONTACTS',
  companies: 'SIDEBAR.COMPANIES',
  reports: 'SIDEBAR.REPORTS',
  settings: 'SIDEBAR.SETTINGS',
  profile: 'SIDEBAR.SETTINGS',
  captain: 'SIDEBAR.CAPTAIN',
  campaigns: 'SIDEBAR.CAMPAIGNS',
  calls: 'SIDEBAR.CALLS',
  portals: 'SIDEBAR.HELP_CENTER.TITLE',
};

const areaOf = path => AREA_LABELS[pathArea(path)];

export function useBackCommands() {
  const { t } = useI18n();
  const route = useRoute();
  const router = useRouter();
  const previous = ref(null);

  watch(
    () => route.fullPath,
    (path, oldPath) => {
      if (!oldPath || areaOf(path) === areaOf(oldPath)) return;
      previous.value = { path: oldPath, label: areaOf(oldPath) };
    }
  );

  const backCommands = computed(() => {
    const label = previous.value?.label;
    if (!label || label === areaOf(route.fullPath)) return [];

    return [
      {
        id: 'back',
        title: t('COMMAND_BAR.COMMANDS.BACK_TO', { page: t(label) }),
        section: t('COMMAND_BAR.SECTIONS.PAGE'),
        icon: 'i-lucide-arrow-left',
        place: 'first',
        run: () => router.push(previous.value.path),
      },
    ];
  });

  return { backCommands };
}
