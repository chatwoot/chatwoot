<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  sync: {
    type: Object,
    required: true,
  },
  learnMoreUrl: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();

const STATUS_META = {
  requested: {
    icon: 'i-lucide-clock-3',
    color: 'blue',
  },
  receiving: {
    icon: 'i-lucide-cloud-download',
    color: 'blue',
  },
  processing: {
    icon: 'i-lucide-loader-circle',
    color: 'blue',
  },
  completed: {
    icon: 'i-lucide-circle-check',
    color: 'teal',
  },
  not_shared: {
    icon: 'i-lucide-circle-alert',
    color: 'amber',
  },
  failed: {
    icon: 'i-lucide-circle-x',
    color: 'ruby',
  },
  no_data_received: {
    icon: 'i-lucide-hourglass',
    color: 'amber',
  },
  unknown: {
    icon: 'i-lucide-circle-help',
    color: 'slate',
  },
};

const ICON_CONTAINER_CLASSES = {
  blue: 'bg-n-blue-3 text-n-blue-11',
  teal: 'bg-n-teal-3 text-n-teal-11',
  amber: 'bg-n-amber-3 text-n-amber-11',
  ruby: 'bg-n-ruby-3 text-n-ruby-11',
  slate: 'bg-n-alpha-2 text-n-slate-11',
};

const status = computed(() =>
  Object.hasOwn(STATUS_META, props.sync.status) ? props.sync.status : 'unknown'
);
const statusMeta = computed(() => STATUS_META[status.value]);
const isProcessing = computed(() => status.value === 'processing');
const showsProgress = computed(() =>
  ['receiving', 'processing'].includes(status.value)
);
const progress = computed(() => {
  const value = Number(props.sync.progress);
  return Number.isFinite(value) ? Math.min(100, Math.max(0, value)) : 0;
});

const numberLabel = value => Number(value || 0).toLocaleString();

const stateCopy = computed(() => {
  if (status.value === 'requested') {
    return {
      title: t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.STATES.requested.TITLE'
      ),
      description: t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.STATES.requested.DESCRIPTION'
      ),
    };
  }
  if (status.value === 'receiving') {
    return {
      title: t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.STATES.receiving.TITLE'
      ),
      description: t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.STATES.receiving.DESCRIPTION'
      ),
    };
  }
  if (status.value === 'processing') {
    return {
      title: t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.STATES.processing.TITLE'
      ),
      description: t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.STATES.processing.DESCRIPTION'
      ),
    };
  }
  if (status.value === 'completed') {
    return {
      title: t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.STATES.completed.TITLE'
      ),
      description: t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.STATES.completed.DESCRIPTION',
        {
          messages: numberLabel(props.sync.imported_messages),
          conversations: numberLabel(props.sync.imported_conversations),
        }
      ),
    };
  }
  if (status.value === 'not_shared') {
    return {
      title: t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.STATES.not_shared.TITLE'
      ),
      description: t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.STATES.not_shared.DESCRIPTION'
      ),
    };
  }
  if (status.value === 'failed') {
    return {
      title: t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.STATES.failed.TITLE'
      ),
      description: t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.STATES.failed.DESCRIPTION',
        { requestId: props.sync.request_id || '—' }
      ),
    };
  }
  if (status.value === 'no_data_received') {
    return {
      title: t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.STATES.no_data_received.TITLE'
      ),
      description: t(
        'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.STATES.no_data_received.DESCRIPTION'
      ),
    };
  }

  return {
    title: t(
      'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.STATES.unknown.TITLE'
    ),
    description: t(
      'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.STATES.unknown.DESCRIPTION'
    ),
  };
});

const title = computed(() => stateCopy.value.title);
const description = computed(() => stateCopy.value.description);
const progressSummary = computed(() =>
  t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.PROGRESS_SUMMARY', {
    messages: numberLabel(props.sync.imported_messages),
    progress: progress.value,
  })
);
const completedAtLabel = computed(() => {
  if (!props.sync.completed_at) return '';

  return t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.COMPLETED_AT', {
    time: dynamicTime(props.sync.completed_at),
  });
});
</script>

<template>
  <section
    class="rounded-xl border border-n-weak bg-n-solid-1 px-3 py-2.5"
    role="status"
    aria-live="polite"
  >
    <div class="flex flex-wrap items-center gap-x-3 gap-y-2">
      <div
        class="grid size-8 shrink-0 place-items-center rounded-lg"
        :class="ICON_CONTAINER_CLASSES[statusMeta.color]"
      >
        <Spinner v-if="isProcessing" :size="14" />
        <Icon v-else :icon="statusMeta.icon" class="size-4" />
      </div>

      <div
        class="flex min-w-48 flex-1 flex-wrap items-baseline gap-x-2 gap-y-0.5"
      >
        <h4 class="text-label text-n-slate-12">
          {{ title }}
        </h4>
        <span class="text-label-small text-n-slate-10">
          {{ showsProgress ? progressSummary : description }}
        </span>
        <span v-if="completedAtLabel" class="text-label-small text-n-slate-10">
          {{ completedAtLabel }}
        </span>
        <a
          v-if="learnMoreUrl"
          :href="learnMoreUrl"
          target="_blank"
          rel="noopener noreferrer"
          class="shrink-0 text-label-small text-n-brand hover:underline"
        >
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_HISTORY_SYNC.LEARN_MORE') }}
        </a>
      </div>

      <div
        v-if="showsProgress"
        class="hidden h-1.5 w-24 shrink-0 grid-cols-[repeat(100,minmax(0,1fr))] overflow-hidden rounded-full bg-n-alpha-2 lg:grid"
        role="progressbar"
        :aria-valuenow="progress"
        aria-valuemin="0"
        aria-valuemax="100"
      >
        <span
          v-for="segment in 100"
          :key="segment"
          class="h-full"
          :class="segment <= progress ? 'bg-n-brand' : 'bg-transparent'"
        />
      </div>
    </div>
  </section>
</template>
