<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import { BaseTableRow, BaseTableCell } from 'dashboard/components-next/table';

const props = defineProps({
  flow: {
    type: Object,
    required: true,
  },
});

defineEmits(['delete']);

const { t } = useI18n();

const statusLabel = computed(() =>
  props.flow.active ? t('FLOWS.LIST.ACTIVE') : t('FLOWS.LIST.INACTIVE')
);

const description = computed(
  () => props.flow.description || t('FLOWS.LIST.NO_DESCRIPTION')
);
</script>

<template>
  <BaseTableRow :item="flow">
    <template #default>
      <BaseTableCell class="max-w-0 w-full">
        <div class="flex items-center gap-2 min-w-0">
          <span class="text-body-main text-n-slate-12 truncate">
            {{ flow.name }}
          </span>
          <div class="w-px h-3 rounded-lg bg-n-weak flex-shrink-0" />
          <span class="text-body-main text-n-slate-11 truncate">
            {{ description }}
          </span>
        </div>
      </BaseTableCell>

      <BaseTableCell class="w-28 whitespace-nowrap">
        <span class="text-body-main text-n-slate-12 whitespace-nowrap">
          {{ statusLabel }}
        </span>
      </BaseTableCell>

      <BaseTableCell align="end" class="w-24">
        <div class="flex gap-3 justify-end flex-shrink-0">
          <router-link
            :to="{ name: 'flows_edit', params: { flowId: flow.id } }"
          >
            <Button
              v-tooltip.top="$t('FLOWS.EDIT.TOOLTIP')"
              icon="i-woot-edit-pen"
              slate
              sm
            />
          </router-link>
          <Button
            v-tooltip.top="$t('FLOWS.DELETE.TOOLTIP')"
            icon="i-woot-bin"
            slate
            sm
            class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
            @click="$emit('delete')"
          />
        </div>
      </BaseTableCell>
    </template>
  </BaseTableRow>
</template>
