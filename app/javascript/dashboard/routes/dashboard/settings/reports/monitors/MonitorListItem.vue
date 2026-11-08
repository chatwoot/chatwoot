<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import EmojiIcon from 'dashboard/components-next/emoji-icon-picker/EmojiIcon.vue';
import HoverActions from 'dashboard/components-next/hover-actions/HoverActions.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Label from 'dashboard/components-next/label/Label.vue';

const props = defineProps({
  monitor: { type: Object, required: true },
  showActions: { type: Boolean, default: false },
  canCreateAutomation: { type: Boolean, default: false },
});
const emit = defineEmits(['action']);

const { t } = useI18n();
const router = useRouter();
const { accountScopedRoute } = useAccount();
const isPaused = computed(() => Boolean(props.monitor.paused_at));
const monitorRoute = computed(() =>
  accountScopedRoute('monitor_reports_show', { monitorId: props.monitor.id })
);
const actions = computed(() => {
  if (!props.showActions) return [];
  return [
    props.canCreateAutomation &&
      !isPaused.value && {
        key: 'automation',
        icon: 'i-lucide-plus',
        label: t('MONITORS.AUTOMATIONS.CREATE'),
      },
    { key: 'edit', icon: 'i-woot-edit-pen', label: t('MONITORS.EDIT') },
    isPaused.value
      ? { key: 'resume', icon: 'i-ph-play', label: t('MONITORS.RESUME') }
      : { key: 'pause', icon: 'i-ph-pause', label: t('MONITORS.PAUSE') },
    {
      key: 'delete',
      icon: 'i-woot-bin',
      label: t('MONITORS.DELETE'),
      danger: true,
    },
  ].filter(Boolean);
});

const onAction = key => {
  if (key !== 'automation') {
    emit('action', key);
    return;
  }
  router.push(
    accountScopedRoute('automation_list', {}, { monitor_id: props.monitor.id })
  );
};
</script>

<template>
  <div
    class="group flex min-w-0 cursor-pointer items-center justify-between gap-4 py-4"
    @click="router.push(monitorRoute)"
  >
    <RouterLink
      :to="monitorRoute"
      class="flex min-w-0 items-center gap-4 rounded-md focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-brand"
      @click.stop
    >
      <span
        class="flex size-10 shrink-0 items-center justify-center rounded-xl text-lg outline outline-1 -outline-offset-1 outline-n-weak"
      >
        <EmojiIcon
          v-if="monitor.icon"
          :value="monitor.icon"
          :color="monitor.icon_color"
          class="size-5"
        />
        <Icon v-else icon="i-lucide-monitor" class="size-4 text-n-slate-11" />
      </span>
      <span class="flex min-w-0 flex-col gap-0.5">
        <span class="flex min-w-0 items-center gap-2">
          <span class="truncate text-heading-3 text-n-slate-12">
            {{ monitor.name }}
          </span>
          <Label
            compact
            :color="isPaused ? 'slate' : 'teal'"
            :label="
              isPaused
                ? t('MONITORS.STATES.PAUSED')
                : t('MONITORS.LIST.RUNNING')
            "
          >
            <template #icon>
              <Icon v-if="isPaused" icon="i-ph-pause" class="size-3" />
              <span v-else class="size-1.5 rounded-full bg-n-teal-9" />
            </template>
          </Label>
        </span>
        <span class="truncate text-body-main text-n-slate-11">
          {{ monitor.condition }}
        </span>
      </span>
    </RouterLink>
    <HoverActions :actions="actions" @action="onAction">
      <span
        v-tooltip.top="t('MONITORS.LIST.CONVERSATIONS_HELP')"
        class="flex flex-col items-end gap-1"
      >
        <span class="text-heading-3 tabular-nums text-n-slate-12">
          {{
            t('MONITORS.LIST.CONVERSATIONS_COUNT', {
              count: monitor.recent_count,
            })
          }}
        </span>
        <span class="hidden text-label-small text-n-slate-11 md:inline">
          {{
            isPaused
              ? t('MONITORS.LAST_DAYS_BEFORE_PAUSE', { count: 7 })
              : t('MONITORS.LAST_DAYS', { count: 7 })
          }}
        </span>
      </span>
    </HoverActions>
  </div>
</template>
