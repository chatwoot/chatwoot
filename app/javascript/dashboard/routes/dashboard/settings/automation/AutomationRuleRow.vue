<script setup>
import { messageStamp } from 'shared/helpers/timeHelper';

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

const readableDate = date => messageStamp(new Date(date), 'LLL d, yyyy');
const readableDateWithTime = date =>
  messageStamp(new Date(date), 'LLL d, yyyy hh:mm a');

const toggle = () => {
  const { id, name, active } = props.automation;
  emit('toggle', {
    id,
    name,
    status: active,
  });
};
</script>

<template>
  <tr>
    <td class="py-4 ltr:pr-4 rtl:pl-4 min-w-[200px]">{{ automation.name }}</td>
    <td class="py-4 ltr:pr-4 rtl:pl-4">{{ automation.description }}</td>
    <td class="py-4 ltr:pr-4 rtl:pl-4">
      <woot-switch :model-value="automation.active" @input="toggle" />
    </td>
    <td
      class="py-4 ltr:pr-4 rtl:pl-4 min-w-[12px]"
      :title="readableDateWithTime(automation.created_on)"
    >
      {{ readableDate(automation.created_on) }}
    </td>
    <td class="py-4 min-w-xs">
      <div class="flex gap-1 justify-end flex-shrink-0">
        <woot-button
          v-tooltip.top="$t('AUTOMATION.FORM.EDIT')"
          variant="smooth"
          size="tiny"
          color-scheme="secondary"
          class-names="grey-btn"
          icon="edit"
          :is-loading="loading"
          @click="$emit('edit', automation)"
        />
        <woot-button
          v-tooltip.top="$t('AUTOMATION.CLONE.TOOLTIP')"
          variant="smooth"
          size="tiny"
          :is-loading="loading"
          color-scheme="primary"
          class-names="grey-btn"
          icon="copy"
          @click="$emit('clone', automation)"
        />
        <woot-button
          v-tooltip.top="$t('AUTOMATION.FORM.DELETE')"
          variant="smooth"
          :is-loading="loading"
          color-scheme="alert"
          size="tiny"
          icon="dismiss-circle"
          class-names="grey-btn"
          @click="$emit('delete', automation)"
        />
      </div>
    </td>
  </tr>
</template>
