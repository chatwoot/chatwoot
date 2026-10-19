<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { messageStamp } from 'shared/helpers/timeHelper';
import { formatDelay } from 'dashboard/helper/automationHelper';
import { useAccount } from 'dashboard/composables/useAccount';
import HoverActions from 'dashboard/components-next/hover-actions/HoverActions.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Label from 'dashboard/components-next/label/Label.vue';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';
import { BaseTableRow, BaseTableCell } from 'dashboard/components-next/table';

const props = defineProps({
  automation: {
    type: Object,
    required: true,
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['toggle', 'edit', 'delete', 'clone']);

const { t } = useI18n();
const { accountScopedRoute } = useAccount();

const readableDate = date => messageStamp(new Date(date), 'LLL d, yyyy');
const readableDateWithTime = date =>
  messageStamp(new Date(date), 'LLL d, yyyy hh:mm a');

const monitorIssue = computed(
  () =>
    ({
      paused: t('AUTOMATION.LIST.MONITOR_PAUSED'),
      deleted: t('AUTOMATION.LIST.MONITOR_DELETED'),
      unavailable: t('AUTOMATION.LIST.MONITOR_UNAVAILABLE'),
    })[props.automation.monitor_availability]
);
const monitorRoute = computed(() =>
  accountScopedRoute('monitor_reports_show', {
    monitorId: props.automation.monitor_id,
  })
);
const actions = computed(() => [
  { key: 'edit', icon: 'i-woot-edit-pen', label: t('AUTOMATION.FORM.EDIT') },
  { key: 'clone', icon: 'i-woot-clone', label: t('AUTOMATION.CLONE.TOOLTIP') },
  {
    key: 'delete',
    icon: 'i-woot-bin',
    label: t('AUTOMATION.FORM.DELETE'),
    danger: true,
  },
]);
const actionHandlers = {
  edit: () => emit('edit', props.automation),
  clone: () => emit('clone', props.automation),
  delete: () => emit('delete', props.automation),
};

const automationActive = computed({
  get: () => props.automation.active,
  set: active => {
    const { id, name } = props.automation;
    emit('toggle', {
      id,
      name,
      status: !active,
    });
  },
});
</script>

<template>
  <BaseTableRow :item="automation" class="group">
    <BaseTableCell class="max-w-0 w-full">
      <div class="flex min-w-0 flex-col gap-1">
        <div class="flex min-w-0 items-center gap-2">
          <span class="truncate text-body-main text-n-slate-12">
            {{ automation.name }}
          </span>
          <Label
            v-if="monitorIssue"
            compact
            color="amber"
            :label="monitorIssue"
          />
          <Label
            v-if="automation.execution_delay"
            compact
            :label="
              $t('AUTOMATION.LIST.DELAY_BADGE', {
                delay: formatDelay(automation.execution_delay),
              })
            "
          >
            <template #icon>
              <Icon icon="i-lucide-timer" class="size-3 text-n-slate-11" />
            </template>
          </Label>
        </div>
        <div
          v-if="automation.monitor_name || automation.description"
          class="flex min-w-0 items-center gap-2"
        >
          <RouterLink
            v-if="automation.monitor_name"
            :to="monitorRoute"
            class="shrink-0 rounded-md focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-brand"
          >
            <Label compact :label="automation.monitor_name">
              <template #icon>
                <Icon icon="i-lucide-monitor" class="size-3 text-n-slate-11" />
              </template>
            </Label>
          </RouterLink>
          <template v-if="automation.description">
            <div
              v-if="automation.monitor_name"
              class="h-3 w-px shrink-0 rounded-lg bg-n-weak"
            />
            <span class="truncate text-body-main text-n-slate-11">
              {{ automation.description }}
            </span>
          </template>
        </div>
      </div>
    </BaseTableCell>

    <BaseTableCell>
      <ToggleSwitch
        v-model="automationActive"
        :disabled="Boolean(monitorIssue)"
      />
    </BaseTableCell>

    <BaseTableCell align="end" class="md:min-w-60">
      <HoverActions
        :actions="actions"
        :loading="loading"
        @action="key => actionHandlers[key]()"
      >
        <span
          :title="readableDateWithTime(automation.created_on)"
          class="hidden whitespace-nowrap text-body-main text-n-slate-12 md:inline"
        >
          {{ readableDate(automation.created_on) }}
        </span>
      </HoverActions>
    </BaseTableCell>
  </BaseTableRow>
</template>
