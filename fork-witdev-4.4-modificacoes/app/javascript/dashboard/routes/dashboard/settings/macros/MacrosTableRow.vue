<script setup>
import { computed } from 'vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  macro: {
    type: Object,
    required: true,
  },
});
defineEmits(['delete']);
const { t } = useI18n();

const createdByName = computed(() => {
  const createdBy = props.macro.created_by;
  return createdBy.available_name ?? createdBy.email ?? '';
});

const updatedByName = computed(() => {
  const updatedBy = props.macro.updated_by;
  return updatedBy.available_name ?? updatedBy.email ?? '';
});

const visibilityLabel = computed(() => {
  const i18nKey =
    props.macro.visibility === 'global'
      ? 'MACROS.EDITOR.VISIBILITY.GLOBAL.LABEL'
      : 'MACROS.EDITOR.VISIBILITY.PERSONAL.LABEL';
  return t(i18nKey);
});
</script>

<template>
  <tr>
    <td class="py-4 ltr:pr-4 rtl:pl-4 truncate">{{ macro.name }}</td>
    <td class="py-4 ltr:pr-4 rtl:pl-4">
      <div v-if="macro.created_by" class="flex items-center">
        <Thumbnail :username="createdByName" size="24px" />
        <span class="mx-2">{{ createdByName }}</span>
      </div>
      <div v-else>--</div>
    </td>
    <td class="py-4 ltr:pr-4 rtl:pl-4">
      <div v-if="macro.updated_by" class="flex items-center">
        <Thumbnail :username="updatedByName" size="24px" />
        <span class="mx-2">{{ updatedByName }}</span>
      </div>
      <div v-else>--</div>
    </td>
    <td class="py-4 ltr:pr-4 rtl:pl-4">{{ visibilityLabel }}</td>
    <td class="py-4 flex justify-end gap-1">
      <router-link :to="{ name: 'macros_edit', params: { macroId: macro.id } }">
        <Button
          v-tooltip.top="$t('MACROS.EDIT.TOOLTIP')"
          icon="i-lucide-pen"
          slate
          xs
          faded
        />
      </router-link>
      <Button
        v-tooltip.top="$t('MACROS.DELETE.TOOLTIP')"
        icon="i-lucide-trash-2"
        xs
        ruby
        faded
        @click="$emit('delete')"
      />
    </td>
  </tr>
</template>
