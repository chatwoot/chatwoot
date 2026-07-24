<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Popover from 'dashboard/components-next/popover/Popover.vue';
import ContentTemplateForm from './ContentTemplateForm.vue';

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

const contentTemplates = computed(() => {
  const inboxData = inbox.value(props.inboxId);
  return inboxData?.content_templates?.templates || [];
});

const filteredTemplates = computed(() => {
  return contentTemplates.value.filter(
    template =>
      template.friendly_name
        .toLowerCase()
        .includes(searchQuery.value.toLowerCase()) &&
      template.status === 'approved'
  );
});

const handlePopoverShow = () => {
  searchQuery.value = '';
  selectedTemplate.value = null;
};

const handlePopoverHide = () => {
  selectedTemplate.value = null;
};

const handleTemplateClick = template => {
  selectedTemplate.value = template;
};

const handleBack = () => {
  selectedTemplate.value = null;
};

const handleSendMessage = (template, hide) => {
  emit('sendMessage', template);
  hide();
};
</script>

<template>
  <Popover
    align="start"
    disable-mobile-view
    @show="handlePopoverShow"
    @hide="handlePopoverHide"
  >
    <Button
      icon="i-ph-whatsapp-logo"
      :label="t('COMPOSE_NEW_CONVERSATION.FORM.TWILIO_OPTIONS.LABEL')"
      color="slate"
      size="sm"
      :disabled="selectedTemplate"
      class="!text-xs font-medium"
    />
    <template #content="{ hide }">
      <div
        v-if="!selectedTemplate"
        class="flex flex-col gap-2 p-4 items-center w-[21.875rem]"
      >
        <div class="w-full">
          <Input
            v-model="searchQuery"
            type="search"
            :placeholder="
              t(
                'COMPOSE_NEW_CONVERSATION.FORM.TWILIO_OPTIONS.SEARCH_PLACEHOLDER'
              )
            "
            custom-input-class="ltr:pl-10 rtl:pr-10"
          >
            <template #prefix>
              <Icon
                icon="i-lucide-search"
                class="absolute top-2 size-3.5 ltr:left-3 rtl:right-3"
              />
            </template>
          </Input>
        </div>
        <div
          v-for="template in filteredTemplates"
          :key="template.content_sid"
          tabindex="0"
          class="flex flex-col gap-2 p-2 w-full rounded-lg cursor-pointer dark:hover:bg-n-alpha-3 hover:bg-n-alpha-1"
          @click="handleTemplateClick(template)"
        >
          <div class="flex justify-between items-center">
            <span class="text-sm text-n-slate-12">{{
              template.friendly_name
            }}</span>
          </div>
          <p class="mb-0 text-xs leading-5 text-n-slate-11 line-clamp-2">
            {{ template.body || t('CONTENT_TEMPLATES.PICKER.NO_CONTENT') }}
          </p>
        </div>
        <template v-if="filteredTemplates.length === 0">
          <p class="pt-2 w-full text-sm text-n-slate-11">
            {{ t('COMPOSE_NEW_CONVERSATION.FORM.TWILIO_OPTIONS.EMPTY_STATE') }}
          </p>
        </template>
      </div>
      <ContentTemplateForm
        v-else
        :template="selectedTemplate"
        @send-message="payload => handleSendMessage(payload, hide)"
        @back="handleBack"
      />
    </template>
  </Popover>
</template>
