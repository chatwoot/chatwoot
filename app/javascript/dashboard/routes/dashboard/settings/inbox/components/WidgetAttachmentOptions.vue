<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const options = defineModel({ type: Object, required: true });

const { t } = useI18n();

const rows = computed(() => [
  {
    key: 'send_attachments_with_message',
    label: t('INBOX_MGMT.FEATURES.SEND_ATTACHMENTS_WITH_MESSAGE'),
  },
  {
    key: 'attachment_editor_enabled',
    label: t('INBOX_MGMT.FEATURES.ATTACHMENT_EDITOR'),
  },
  {
    key: 'screen_capture_enabled',
    label: t('INBOX_MGMT.FEATURES.SCREEN_CAPTURE'),
  },
  {
    key: 'screen_capture_editor_enabled',
    label: t('INBOX_MGMT.FEATURES.SCREEN_CAPTURE_EDITOR'),
    disabled: !options.value.screen_capture_enabled,
  },
]);

const update = (key, value) => {
  options.value = { ...options.value, [key]: value };
};
</script>

<template>
  <div
    v-for="row in rows"
    :key="row.key"
    class="flex gap-2 py-0.5"
    :class="{ 'opacity-50': row.disabled }"
  >
    <input
      :id="row.key"
      type="checkbox"
      :checked="options[row.key]"
      :disabled="row.disabled"
      @change="update(row.key, $event.target.checked)"
    />
    <label :for="row.key">{{ row.label }}</label>
  </div>
</template>
