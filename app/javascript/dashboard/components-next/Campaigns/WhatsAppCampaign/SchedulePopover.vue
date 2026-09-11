<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Popover from 'dashboard/components-next/popover/Popover.vue';

defineProps({
  buttonLabel: {
    type: String,
    required: true,
  },
  confirmLabel: {
    type: String,
    default: '',
  },
  variant: {
    type: String,
    default: 'solid',
  },
  color: {
    type: String,
    default: 'blue',
  },
  showActions: {
    type: Boolean,
    default: true,
  },
  isDisabled: {
    type: Boolean,
    default: false,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['confirm']);

const scheduledAt = defineModel({ type: String, default: '' });

const { t } = useI18n();

const popoverRef = ref(null);

const minDateTime = computed(() => {
  const now = new Date();
  return new Date(now.getTime() - now.getTimezoneOffset() * 60000)
    .toISOString()
    .slice(0, 16);
});

const handleConfirm = () => {
  popoverRef.value.hide();
  emit('confirm');
};
</script>

<template>
  <Popover ref="popoverRef">
    <Button
      size="sm"
      :variant="variant"
      :color="color"
      :label="buttonLabel"
      :disabled="isDisabled"
    />
    <template #content="{ hide }">
      <div class="flex flex-col gap-3 p-4 w-72">
        <Input
          v-model="scheduledAt"
          type="datetime-local"
          :min="minDateTime"
          :label="t('CAMPAIGN.WHATSAPP.FORM.SCHEDULE_POPOVER.LABEL')"
        />
        <div v-if="showActions" class="flex items-center justify-between gap-3">
          <Button
            variant="faded"
            color="slate"
            size="sm"
            class="w-full"
            :label="t('CAMPAIGN.WHATSAPP.FORM.SCHEDULE_POPOVER.CANCEL')"
            @click="hide"
          />
          <Button
            size="sm"
            class="w-full"
            :label="confirmLabel"
            :is-loading="isLoading"
            :disabled="isLoading || !scheduledAt"
            @click="handleConfirm"
          />
        </div>
      </div>
    </template>
  </Popover>
</template>
