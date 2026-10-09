import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useImpersonation } from 'dashboard/composables/useImpersonation';
import Auth from 'dashboard/api/auth';

const STATUSES = [
  {
    key: 'online',
    title: 'PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.ONLINE',
    icon: 'i-lucide-circle-check',
  },
  {
    key: 'busy',
    title: 'PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.BUSY',
    icon: 'i-lucide-circle-minus',
  },
  {
    key: 'offline',
    title: 'PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.OFFLINE',
    icon: 'i-lucide-circle-off',
  },
];

export function useAccountCommands() {
  const { t } = useI18n();
  const store = useStore();
  const { isImpersonating } = useImpersonation();

  const accountId = useMapGetter('getCurrentAccountId');
  const availability = useMapGetter('getCurrentUserAvailability');
  const accounts = useMapGetter('getUserAccounts');

  const availabilityCommands = computed(() => {
    if (isImpersonating.value) return [];

    const section = t('COMMAND_BAR.SECTIONS.ACCOUNT');
    const current = STATUSES.find(status => status.key === availability.value);
    return [
      {
        id: 'set_availability',
        title: t('COMMAND_BAR.COMMANDS.SET_AVAILABILITY'),
        section,
        icon: 'i-lucide-circle-dot',
        badge: current && t(current.title),
        page: true,
      },
      ...STATUSES.filter(status => status !== current).map(status => ({
        id: `availability-${status.key}`,
        title: t(status.title),
        parent: 'set_availability',
        section,
        icon: status.icon,
        run: () =>
          store.dispatch('updateAvailability', {
            availability: status.key,
            account_id: accountId.value,
          }),
      })),
    ];
  });

  const switchAccountCommands = computed(() => {
    if (accounts.value.length < 2) return [];

    const section = t('COMMAND_BAR.SECTIONS.ACCOUNT');
    const others = accounts.value
      .filter(account => account.id !== accountId.value)
      .sort((a, b) => a.name.localeCompare(b.name));
    return [
      {
        id: 'switch_account',
        title: t('COMMAND_BAR.COMMANDS.SWITCH_ACCOUNT'),
        section,
        icon: 'i-lucide-arrow-right-left',
        page: true,
      },
      ...others.map(account => ({
        id: `account-${account.id}`,
        title: account.name,
        parent: 'switch_account',
        section,
        icon: 'i-lucide-building-2',
        run: () => {
          window.location.href = `/app/accounts/${account.id}/dashboard`;
        },
      })),
    ];
  });

  const accountCommands = computed(() => [
    ...availabilityCommands.value,
    ...switchAccountCommands.value,
    {
      id: 'log_out',
      title: t('SIDEBAR_ITEMS.LOGOUT'),
      section: t('COMMAND_BAR.SECTIONS.ACCOUNT'),
      icon: 'i-lucide-log-out',
      run: () => Auth.logout(),
    },
  ]);

  return { accountCommands };
}
