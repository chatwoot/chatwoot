<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import DataOperationStatus from './DataOperationStatus.vue';
import { importSourceFor } from '../importSources';
import { formatDate, importedCount } from '../importStatus';

const props = defineProps({
  items: { type: Array, default: () => [] },
  type: { type: String, default: 'import' },
});
defineEmits(['open']);
const { t } = useI18n();
const isExport = computed(() => props.type === 'export');
const rows = computed(() =>
  props.items.map(item => {
    const source = importSourceFor(item);
    const types = item.import_types?.length
      ? item.import_types
      : [item.data_type];
    const typeLabels = {
      contacts: t('DATA_IMPORTS.TYPES.CONTACTS'),
      conversations: t('DATA_IMPORTS.TYPES.CONVERSATIONS'),
    };
    const subtitle = isExport.value
      ? item.export_options.scope_name ||
        item.export_options.label ||
        t('DATA_EXPORTS.ALL_CONTACTS')
      : [
          source.label,
          types.map(type => typeLabels[type] || type).join(', '),
        ].join(' · ');
    return {
      ...item,
      title: item.name || t('DATA_IMPORTS.TABLE.UNNAMED'),
      subtitle,
      icon: isExport.value ? null : source.icon,
      iconClass: isExport.value ? 'i-lucide-file-output' : source.iconClass,
      count: (isExport.value
        ? item.processed_records
        : importedCount(item)
      ).toLocaleString(),
      date: formatDate(item.created_at),
    };
  })
);
</script>

<template>
  <div class="overflow-hidden rounded-xl border border-n-weak bg-n-solid-1">
    <div
      aria-hidden="true"
      class="hidden grid-cols-[minmax(0,1fr)_11rem_5rem_10rem_1rem] items-center gap-4 border-b border-n-weak bg-n-alpha-1 px-5 py-3 text-label-small text-n-slate-11 lg:grid"
    >
      <span>{{ $t('DATA_IMPORTS.TABLE.NAME') }}</span>
      <span>{{ $t('DATA_IMPORTS.TABLE.STATUS') }}</span>
      <span>{{
        isExport
          ? $t('DATA_EXPORTS.TABLE.EXPORTED')
          : $t('DATA_IMPORTS.TABLE.IMPORTED')
      }}</span>
      <span>{{ $t('DATA_IMPORTS.TABLE.CREATED') }}</span>
      <span />
    </div>
    <ul class="m-0 list-none divide-y divide-n-weak p-0">
      <li v-for="item in rows" :key="item.id">
        <button
          type="button"
          class="group grid w-full grid-cols-[minmax(0,1fr)_auto] items-center gap-x-4 gap-y-3 px-5 py-4 text-start transition-colors hover:bg-n-alpha-1 focus-visible:outline focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-n-brand lg:grid-cols-[minmax(0,1fr)_11rem_5rem_10rem_1rem]"
          @click="$emit('open', item.id)"
        >
          <span
            class="col-span-2 flex min-w-0 items-center gap-3 lg:col-span-1"
          >
            <span
              class="grid size-10 shrink-0 place-items-center rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-11"
            >
              <img
                v-if="item.icon"
                :src="item.icon"
                alt=""
                class="size-6 object-contain"
              />
              <Icon v-else :icon="item.iconClass" class="size-5" />
            </span>
            <span class="flex min-w-0 flex-col gap-1">
              <span
                :title="item.title"
                class="truncate text-heading-3 text-n-slate-12"
              >
                {{ item.title }}
              </span>
              <span
                :title="item.subtitle"
                class="truncate text-label-small text-n-slate-11"
              >
                {{ item.subtitle }}
              </span>
            </span>
          </span>
          <DataOperationStatus :status="item.status" />
          <span
            class="text-end text-body-main tabular-nums text-n-slate-12 lg:text-start"
          >
            {{ item.count }}
            <span class="text-label-small text-n-slate-11 lg:hidden">{{
              isExport
                ? $t('DATA_EXPORTS.TABLE.EXPORTED')
                : $t('DATA_IMPORTS.TABLE.IMPORTED')
            }}</span>
          </span>
          <span
            class="col-span-2 text-label-small text-n-slate-11 lg:col-span-1"
          >
            {{ item.date }}
          </span>
          <Icon
            icon="i-lucide-chevron-right"
            class="hidden size-4 text-n-slate-10 group-hover:text-n-slate-12 lg:block"
          />
        </button>
      </li>
    </ul>
  </div>
</template>
