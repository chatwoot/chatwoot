import {
  getCurrentInstance,
  onActivated,
  onBeforeUnmount,
  onDeactivated,
} from 'vue';
import { useI18n } from 'vue-i18n';
import { useCommandBar } from '@bysivin/jumpbar';

const SCOPES = ['page'];

export function usePageCommands(commands) {
  const { t } = useI18n();
  // Settings pages sit inside <keep-alive>: a hidden page keeps its instance
  // but must stop offering its actions.
  let active = true;
  const unregister = useCommandBar().register({
    id: `page-${getCurrentInstance().uid}`,
    commands: () =>
      active
        ? commands().map(command => ({
            section: t('COMMAND_BAR.SECTIONS.PAGE'),
            icon: 'i-lucide-plus',
            scopes: SCOPES,
            place: 'first',
            ...command,
          }))
        : [],
  });

  onActivated(() => {
    active = true;
  });
  onDeactivated(() => {
    active = false;
  });
  onBeforeUnmount(unregister);
}

export const recordCommands = ({ id, title, icon, records, label, run }) => [
  { id, title, icon, page: true },
  ...records.map(record => ({
    id: `${id}-${record.id}`,
    title: label(record),
    parent: id,
    icon,
    run: () => run(record),
  })),
];
