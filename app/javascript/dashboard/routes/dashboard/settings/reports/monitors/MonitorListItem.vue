<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Label from 'dashboard/components-next/label/Label.vue';

const props = defineProps({
  monitor: { type: Object, required: true },
  showActions: { type: Boolean, default: false },
});
const emit = defineEmits(['action']);

const { t } = useI18n();
const router = useRouter();
const { accountScopedRoute } = useAccount();
const isPaused = computed(() => Boolean(props.monitor.paused_at));
const monitorRoute = computed(() =>
  accountScopedRoute('monitor_reports_show', { monitorId: props.monitor.id })
);
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
        class="flex size-10 shrink-0 items-center justify-center rounded-xl outline outline-1 -outline-offset-1 outline-n-weak"
      >
        <Icon icon="i-lucide-monitor" class="size-4 text-n-slate-11" />
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
        <span
          v-tooltip.top="monitor.condition"
          class="truncate text-body-main text-n-slate-11"
        >
          {{ monitor.condition }}
        </span>
      </span>
    </RouterLink>
    <div class="relative flex shrink-0 items-center justify-end">
      <span
        v-tooltip.top="t('MONITORS.LIST.CONVERSATIONS_HELP')"
        class="flex flex-col items-end gap-1 transition-opacity"
        :class="{
          '[@media(hover:hover)]:group-hover:opacity-0 [@media(hover:hover)]:group-focus-within:opacity-0':
            showActions,
        }"
      >
        <span class="text-heading-3 tabular-nums text-n-slate-12">
          {{
            t('MONITORS.LIST.CONVERSATIONS_COUNT', {
              count: monitor.recent_count,
            })
          }}
        </span>
        <span class="text-label-small text-n-slate-11">
          {{
            isPaused
              ? t('MONITORS.LAST_DAYS_BEFORE_PAUSE', { count: 7 })
              : t('MONITORS.LAST_DAYS', { count: 7 })
          }}
        </span>
      </span>
      <div
        v-if="showActions"
        class="ms-3 flex gap-3 transition-opacity [@media(hover:hover)]:pointer-events-none [@media(hover:hover)]:absolute [@media(hover:hover)]:end-0 [@media(hover:hover)]:top-1/2 [@media(hover:hover)]:-translate-y-1/2 [@media(hover:hover)]:ms-0 [@media(hover:hover)]:opacity-0 [@media(hover:hover)]:group-hover:pointer-events-auto [@media(hover:hover)]:group-hover:opacity-100 [@media(hover:hover)]:group-focus-within:pointer-events-auto [@media(hover:hover)]:group-focus-within:opacity-100"
      >
        <Button
          v-tooltip.top="t('MONITORS.EDIT')"
          icon="i-woot-edit-pen"
          slate
          sm
          :aria-label="t('MONITORS.EDIT')"
          @click.stop="emit('action', 'edit')"
        />
        <Button
          v-tooltip.top="isPaused ? t('MONITORS.RESUME') : t('MONITORS.PAUSE')"
          :icon="isPaused ? 'i-ph-play' : 'i-ph-pause'"
          slate
          sm
          :aria-label="isPaused ? t('MONITORS.RESUME') : t('MONITORS.PAUSE')"
          @click.stop="emit('action', isPaused ? 'resume' : 'pause')"
        />
        <Button
          v-tooltip.top="t('MONITORS.DELETE')"
          icon="i-woot-bin"
          slate
          sm
          :aria-label="t('MONITORS.DELETE')"
          class="hover:enabled:bg-n-ruby-2 hover:enabled:text-n-ruby-11"
          @click.stop="emit('action', 'delete')"
        />
      </div>
    </div>
  </div>
</template>
