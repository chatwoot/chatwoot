import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';

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
};

const AREA_PATTERN = /^\/app\/accounts\/\d+\/([^/?#]+)/;

const areaOf = path => path.match(AREA_PATTERN)?.[1];

export function useBackCommands() {
  const { t } = useI18n();
  const route = useRoute();
  const router = useRouter();
  const previous = ref(null);

  watch(
    () => route.fullPath,
    (path, oldPath) => {
      if (!oldPath || areaOf(path) === areaOf(oldPath)) return;
      previous.value = { path: oldPath, area: areaOf(oldPath) };
    }
  );

  const backCommands = computed(() => {
    const label = AREA_LABELS[previous.value?.area];
    if (!label || previous.value.area === areaOf(route.fullPath)) return [];

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
