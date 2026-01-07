<script setup>
import { computed } from 'vue';
import { messageStamp } from 'shared/helpers/timeHelper';
import Button from 'dashboard/components-next/button/Button.vue';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';

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
  <tr>
    <td class="py-4 ltr:pr-4 rtl:pl-4 w-full max-w-0">
      <div class="flex items-center gap-2 min-w-0">
        <span class="text-body-main text-n-slate-12 truncate">
          {{ automation.name }}
        </span>
        <div class="w-px h-3 rounded-lg bg-n-weak flex-shrink-0" />
        <span class="text-body-main text-n-slate-11 truncate">
          {{ automation.description }}
        </span>
      </div>
    </td>
    <td class="py-4 ltr:pr-4 rtl:pl-4 w-16">
      <ToggleSwitch v-model="automationActive" />
    </td>
    <td
      class="py-4 ltr:pr-4 rtl:pl-4 whitespace-nowrap w-32"
      :title="readableDateWithTime(automation.created_on)"
    >
      <span class="text-body-main text-n-slate-12">
        {{ readableDate(automation.created_on) }}
      </span>
    </td>
    <td class="py-4 w-36">
      <div class="flex gap-3 justify-end flex-shrink-0">
        <Button
          v-tooltip.top="$t('AUTOMATION.FORM.EDIT')"
          icon="i-woot-edit-pen"
          slate
          sm
          :is-loading="loading"
          @click="$emit('edit', automation)"
        />
        <Button
          v-tooltip.top="$t('AUTOMATION.FORM.DELETE')"
          :is-loading="loading"
          icon="i-woot-bin"
          slate
          sm
          @click="$emit('delete', automation)"
        />
        <Button
          v-tooltip.top="$t('AUTOMATION.CLONE.TOOLTIP')"
          icon="i-woot-clone"
          sm
          slate
          :is-loading="loading"
          @click="$emit('clone', automation)"
        />
      </div>
    </td>
  </tr>
</template>
