<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Input from 'dashboard/components-next/input/Input.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  inboxes: {
    type: Array,
    default: () => [],
  },
});

const title = defineModel('title', { type: String, default: '' });
const inboxId = defineModel('inboxId', {
  type: [Number, String],
  default: null,
});

const { t } = useI18n();

const inboxOptions = computed(() =>
  props.inboxes.map(inbox => ({ value: inbox.id, label: inbox.name }))
);
</script>

<template>
  <Input
    v-model="title"
    :label="t('CAMPAIGN.WHATSAPP.FORM.BASIC_SETTINGS.NAME.LABEL')"
    :placeholder="t('CAMPAIGN.WHATSAPP.FORM.BASIC_SETTINGS.NAME.PLACEHOLDER')"
  />

  <div class="flex flex-col gap-1">
    <label for="campaign-inbox" class="mb-0.5 text-heading-3 text-n-slate-12">
      {{ t('CAMPAIGN.WHATSAPP.FORM.BASIC_SETTINGS.INBOX.LABEL') }}
    </label>
    <ComboBox
      id="campaign-inbox"
      v-model="inboxId"
      :options="inboxOptions"
      :placeholder="
        t('CAMPAIGN.WHATSAPP.FORM.BASIC_SETTINGS.INBOX.PLACEHOLDER')
      "
    />
  </div>
</template>
