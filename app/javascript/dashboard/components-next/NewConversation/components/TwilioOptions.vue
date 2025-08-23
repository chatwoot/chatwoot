<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TwilioTemplate from './TwilioTemplate.vue';

const props = defineProps({
  inboxId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['sendMessage']);

const { t } = useI18n();
const inbox = useMapGetter('inboxes/getInbox');

const searchQuery = ref('');
const selectedTemplate = ref(null);
const showTemplatesMenu = ref(false);

const twilioTemplates = computed(() => {
  const inboxData = inbox.value(props.inboxId);
  return inboxData?.content_templates?.templates || [];
});

const filteredTemplates = computed(() => {
  return twilioTemplates.value.filter(
    template =>
      template.friendly_name
        .toLowerCase()
        .includes(searchQuery.value.toLowerCase()) &&
      template.status === 'approved'
  );
});

const getTemplateType = template => {
  if (template.template_type === 'media') {
    return 'Media';
  }
  if (template.template_type === 'quick_reply') {
    return 'Quick Reply';
  }
  return 'Text';
};

const handleTriggerClick = () => {
  searchQuery.value = '';
  showTemplatesMenu.value = !showTemplatesMenu.value;
};

const handleTemplateClick = template => {
  selectedTemplate.value = template;
  showTemplatesMenu.value = false;
};

const handleBack = () => {
  selectedTemplate.value = null;
  showTemplatesMenu.value = true;
};

const handleSendMessage = template => {
  emit('sendMessage', template);
  selectedTemplate.value = null;
};
</script>

<template>
  <div class="relative">
    <Button
      icon="i-ph-whatsapp-logo"
      :label="t('COMPOSE_NEW_CONVERSATION.FORM.TWILIO_OPTIONS.LABEL')"
      color="slate"
      size="sm"
      :disabled="selectedTemplate"
      class="!text-xs font-medium"
      @click="handleTriggerClick"
    />
    <div
      v-if="showTemplatesMenu"
      class="absolute top-full mt-1.5 max-h-96 overflow-y-auto ltr:left-0 rtl:right-0 flex flex-col gap-2 p-4 items-center w-[21.875rem] h-auto bg-n-solid-2 border border-n-strong shadow-sm rounded-lg"
    >
      <div class="relative w-full">
        <Icon
          icon="i-lucide-search"
          class="absolute size-3.5 top-2 ltr:left-3 rtl:right-3"
        />
        <input
          v-model="searchQuery"
          type="search"
          :placeholder="
            t('COMPOSE_NEW_CONVERSATION.FORM.TWILIO_OPTIONS.SEARCH_PLACEHOLDER')
          "
          class="w-full h-8 py-2 ltr:pl-10 rtl:pr-10 ltr:pr-2 rtl:pl-2 text-sm reset-base outline-none border-none rounded-lg bg-n-alpha-black2 dark:bg-n-solid-1 text-n-slate-12"
        />
      </div>
      <div
        v-for="template in filteredTemplates"
        :key="template.content_sid"
        class="flex flex-col gap-2 p-2 w-full rounded-lg cursor-pointer dark:hover:bg-n-alpha-3 hover:bg-n-alpha-1"
        @click="handleTemplateClick(template)"
      >
        <div class="flex justify-between items-center">
          <span class="text-sm text-n-slate-12">{{
            template.friendly_name
          }}</span>
          <div class="flex gap-1">
            <span
              class="inline-block px-2 py-1 text-xs leading-none rounded-lg cursor-default bg-n-slate-3 text-n-slate-12"
            >
              {{ getTemplateType(template) }}
            </span>
            <span
              class="inline-block px-2 py-1 text-xs leading-none rounded-lg cursor-default bg-n-slate-3 text-n-slate-12"
            >
              {{ template.language }}
            </span>
          </div>
        </div>
        <p class="mb-0 text-xs leading-5 text-n-slate-11 line-clamp-2">
          {{ template.body || 'No content' }}
        </p>
      </div>
      <template v-if="filteredTemplates.length === 0">
        <p class="pt-2 w-full text-sm text-n-slate-11">
          {{ t('COMPOSE_NEW_CONVERSATION.FORM.TWILIO_OPTIONS.EMPTY_STATE') }}
        </p>
      </template>
    </div>
    <TwilioTemplate
      v-if="selectedTemplate"
      :template="selectedTemplate"
      @send-message="handleSendMessage"
      @back="handleBack"
    />
  </div>
</template>
