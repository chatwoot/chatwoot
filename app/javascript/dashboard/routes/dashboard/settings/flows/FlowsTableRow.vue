<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import { BaseTableRow, BaseTableCell } from 'dashboard/components-next/table';

const props = defineProps({
  flow: {
    type: Object,
    required: true,
  },
});

defineEmits(['delete']);

const { t } = useI18n();
const store = useStore();
const toggling = ref(false);

const description = computed(
  () => props.flow.description || t('FLOWS.LIST.NO_DESCRIPTION')
);

const categoryLabel = computed(
  () => props.flow.category || t('FLOWS.LIST.NO_CATEGORY')
);

const onToggleActive = async value => {
  if (toggling.value) return;
  toggling.value = true;
  try {
    await store.dispatch('flows/update', {
      id: props.flow.id,
      active: value,
    });
  } catch (e) {
    useAlert(t('FLOWS.EDIT.API.ERROR_MESSAGE'));
  } finally {
    toggling.value = false;
  }
};
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

      <BaseTableCell class="w-36 whitespace-nowrap">
        <span class="text-body-main text-n-slate-12 truncate">
          {{ categoryLabel }}
        </span>
      </BaseTableCell>

      <BaseTableCell class="w-28 whitespace-nowrap">
        <div
          class="flex items-center gap-2"
          :class="{ 'opacity-50 pointer-events-none': toggling }"
        >
          <Switch
            :model-value="flow.active"
            @update:model-value="onToggleActive"
          />
          <span class="text-xs text-n-slate-11">
            {{
              flow.active ? t('FLOWS.LIST.ACTIVE') : t('FLOWS.LIST.INACTIVE')
            }}
          </span>
        </div>
      </BaseTableCell>

      <BaseTableCell align="end" class="w-24">
        <div class="flex gap-3 justify-end flex-shrink-0">
          <router-link
            :to="{ name: 'flows_edit', params: { flowId: flow.id } }"
          >
            <Button
              v-tooltip.top="t('FLOWS.EDIT.TOOLTIP')"
              icon="i-woot-edit-pen"
              slate
              sm
            />
          </router-link>
          <Button
            v-tooltip.top="t('FLOWS.DELETE.TOOLTIP')"
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
