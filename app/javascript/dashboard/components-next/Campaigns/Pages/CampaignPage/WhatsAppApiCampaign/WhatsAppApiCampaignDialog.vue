<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import WhatsappApiMessageTemplatesAPI from 'dashboard/api/whatsappApiMessageTemplates';

const emit = defineEmits(['created', 'close']);

const { t } = useI18n();
const store = useStore();
const fileInput = ref(null);
const templates = ref([]);
const isFetchingTemplates = ref(false);
const isSavingTemplate = ref(false);
const templateName = ref('');

const labels = useMapGetter('labels/getLabels');
const inboxes = useMapGetter('inboxes/getWhatsAppApiCampaignInboxes');
const uiFlags = useMapGetter('whatsappApiCampaigns/getUIFlags');
const variableSnippets = ['{{contact.name}}', '{{contact.first_name}}'];
const variableSnippetParams = {
  contactName: variableSnippets[0],
  contactFirstName: variableSnippets[1],
};

const initialState = {
  title: '',
  inboxId: null,
  templateId: null,
  messageBody: '',
  scheduledAt: null,
  selectedAudience: [],
  mediaFile: null,
};

const state = reactive({ ...initialState });

const isCreating = computed(() => uiFlags.value.isCreating);
const selectedFileName = computed(() => state.mediaFile?.name || '');
const messagePlaceholder = computed(() =>
  t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.MESSAGE.PLACEHOLDER', {
    contactFirstName: variableSnippetParams.contactFirstName,
  })
);
const messageHelp = computed(() =>
  t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.MESSAGE.HELP', variableSnippetParams)
);

const currentDateTime = computed(() => {
  const now = new Date();
  const localTime = new Date(now.getTime() - now.getTimezoneOffset() * 60000);
  return localTime.toISOString().slice(0, 16);
});

const mapToOptions = (items, valueKey, labelKey) =>
  items?.map(item => ({ value: item[valueKey], label: item[labelKey] })) ?? [];

const inboxOptions = computed(() => mapToOptions(inboxes.value, 'id', 'name'));
const audienceOptions = computed(() =>
  mapToOptions(labels.value, 'id', 'title')
);
const templateOptions = computed(() => [
  { value: '', label: t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.TEMPLATE.NONE') },
  ...mapToOptions(templates.value, 'id', 'name'),
]);

const guideSteps = computed(() => [
  {
    number: 1,
    title: t('CAMPAIGN.WHATSAPP_API.CREATE.GUIDE.INBOX_TITLE'),
    body: t('CAMPAIGN.WHATSAPP_API.CREATE.GUIDE.INBOX_BODY'),
  },
  {
    number: 2,
    title: t('CAMPAIGN.WHATSAPP_API.CREATE.GUIDE.MESSAGE_TITLE'),
    body: t('CAMPAIGN.WHATSAPP_API.CREATE.GUIDE.MESSAGE_BODY'),
  },
  {
    number: 3,
    title: t('CAMPAIGN.WHATSAPP_API.CREATE.GUIDE.SEND_TITLE'),
    body: t('CAMPAIGN.WHATSAPP_API.CREATE.GUIDE.SEND_BODY'),
  },
]);

const hasMessageOrMedia = computed(
  () => state.messageBody.trim().length > 0 || !!state.mediaFile
);

const isScheduledAtValid = computed(() => {
  if (!state.scheduledAt) return false;

  return (
    new Date(state.scheduledAt).getTime() >=
    new Date(currentDateTime.value).getTime()
  );
});

const canSubmit = computed(
  () =>
    state.title.trim() &&
    state.inboxId &&
    isScheduledAtValid.value &&
    state.selectedAudience.length > 0 &&
    hasMessageOrMedia.value
);

const reset = () => {
  Object.assign(state, { ...initialState });
  templates.value = [];
  templateName.value = '';
  if (fileInput.value) fileInput.value.value = null;
};

const close = () => {
  reset();
  emit('close');
};

const fetchTemplates = async inboxId => {
  templates.value = [];
  if (!inboxId) return;

  isFetchingTemplates.value = true;
  try {
    const response = await WhatsappApiMessageTemplatesAPI.get(inboxId);
    templates.value = response.data.payload || [];
  } catch (error) {
    useAlert(t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.TEMPLATE.FETCH_ERROR'));
  } finally {
    isFetchingTemplates.value = false;
  }
};

const selectedTemplate = computed(() =>
  templates.value.find(template => template.id === state.templateId)
);

watch(
  () => state.inboxId,
  inboxId => {
    state.templateId = null;
    fetchTemplates(inboxId);
  }
);

watch(selectedTemplate, template => {
  if (template) state.messageBody = template.body;
});

const handleFileClick = () => fileInput.value?.click();

const handleFileChange = () => {
  state.mediaFile = fileInput.value?.files[0] || null;
};

const removeFile = () => {
  state.mediaFile = null;
  if (fileInput.value) fileInput.value.value = null;
};

const saveTemplate = async () => {
  if (!state.inboxId || !templateName.value.trim() || !state.messageBody.trim())
    return;

  isSavingTemplate.value = true;
  try {
    const response = await WhatsappApiMessageTemplatesAPI.create(
      state.inboxId,
      {
        name: templateName.value.trim(),
        body: state.messageBody.trim(),
      }
    );
    const template = response.data.payload;
    templates.value = [...templates.value, template];
    state.templateId = template.id;
    templateName.value = '';
    useAlert(t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.TEMPLATE.SAVE_SUCCESS'));
  } catch (error) {
    useAlert(t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.TEMPLATE.SAVE_ERROR'));
  } finally {
    isSavingTemplate.value = false;
  }
};

const formatToUTCString = localDateTime =>
  localDateTime ? new Date(localDateTime).toISOString() : null;

const submit = async () => {
  if (!canSubmit.value) return;

  try {
    await store.dispatch('whatsappApiCampaigns/create', {
      title: state.title.trim(),
      inboxId: state.inboxId,
      templateId: state.templateId,
      messageBody: state.messageBody.trim(),
      scheduledAt: formatToUTCString(state.scheduledAt),
      mediaFile: state.mediaFile,
      audience: state.selectedAudience.map(id => ({ id, type: 'Label' })),
    });
    useAlert(t('CAMPAIGN.WHATSAPP_API.CREATE.API.SUCCESS_MESSAGE'));
    emit('created');
    close();
  } catch (error) {
    useAlert(t('CAMPAIGN.WHATSAPP_API.CREATE.API.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <form
    class="absolute z-50 flex max-h-[82vh] w-[min(48rem,calc(100vw-3rem))] min-w-0 flex-col overflow-hidden rounded-xl border border-n-weak bg-n-alpha-3 shadow-xl backdrop-blur-[100px] ltr:right-0 rtl:left-0 top-10"
    @submit.prevent="submit"
    @click.stop
  >
    <div class="flex flex-col gap-2 p-6 pb-4">
      <h3 class="text-base font-medium leading-6 text-n-slate-12">
        {{ t('CAMPAIGN.WHATSAPP_API.CREATE.TITLE') }}
      </h3>
      <p class="mb-0 text-sm leading-5 text-n-slate-11">
        {{ t('CAMPAIGN.WHATSAPP_API.CREATE.DESCRIPTION') }}
      </p>
    </div>

    <div class="grid gap-5 px-6 pb-5 overflow-y-auto md:grid-cols-[240px_1fr]">
      <aside class="flex flex-col gap-3 p-4 border rounded-lg border-n-weak">
        <div v-for="step in guideSteps" :key="step.number" class="flex gap-3">
          <span
            class="flex items-center justify-center flex-shrink-0 w-6 h-6 text-xs font-medium rounded-full bg-n-alpha-2 text-n-slate-12"
          >
            {{ step.number }}
          </span>
          <div>
            <p class="mb-1 text-sm font-medium text-n-slate-12">
              {{ step.title }}
            </p>
            <p class="mb-0 text-xs leading-5 text-n-slate-11">
              {{ step.body }}
            </p>
          </div>
        </div>
      </aside>

      <div class="flex flex-col gap-5 min-w-0">
        <Input
          v-model="state.title"
          :label="t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.TITLE.LABEL')"
          :placeholder="
            t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.TITLE.PLACEHOLDER')
          "
        />

        <div class="flex flex-col gap-1">
          <label class="mb-0.5 text-sm font-medium text-n-slate-12">
            {{ t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.INBOX.LABEL') }}
          </label>
          <ComboBox
            v-model="state.inboxId"
            :options="inboxOptions"
            :placeholder="
              t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.INBOX.PLACEHOLDER')
            "
            :empty-state="t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.INBOX.EMPTY')"
            class="[&>div>button]:bg-n-alpha-black2"
          />
        </div>

        <div class="flex flex-col gap-1">
          <label class="mb-0.5 text-sm font-medium text-n-slate-12">
            {{ t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.TEMPLATE.LABEL') }}
          </label>
          <ComboBox
            v-model="state.templateId"
            :options="templateOptions"
            :disabled="!state.inboxId || isFetchingTemplates"
            :placeholder="
              t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.TEMPLATE.PLACEHOLDER')
            "
            class="[&>div>button]:bg-n-alpha-black2"
          />
        </div>

        <TextArea
          v-model="state.messageBody"
          :label="t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.MESSAGE.LABEL')"
          :placeholder="messagePlaceholder"
          :max-length="150000"
          auto-height
          resize
          :message="messageHelp"
          class="[&>div]:min-h-[120px]"
        />

        <div
          class="flex flex-col gap-2 p-3 border rounded-lg border-n-weak bg-n-alpha-1"
        >
          <p class="mb-0 text-sm font-medium text-n-slate-12">
            {{ t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.VARIABLES.TITLE') }}
          </p>
          <p class="mb-0 text-xs leading-5 text-n-slate-11">
            {{ t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.VARIABLES.HELP') }}
          </p>
          <div class="flex flex-wrap gap-2">
            <code
              v-for="snippet in variableSnippets"
              :key="snippet"
              class="px-2 py-1 text-xs rounded bg-n-alpha-2 text-n-slate-12"
            >
              {{ snippet }}
            </code>
          </div>
        </div>

        <div class="grid gap-3 md:grid-cols-[1fr_auto]">
          <Input
            v-model="templateName"
            :label="t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.TEMPLATE_NAME.LABEL')"
            :placeholder="
              t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.TEMPLATE_NAME.PLACEHOLDER')
            "
            :disabled="!state.inboxId"
          />
          <div class="flex items-end">
            <Button
              :label="t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.TEMPLATE_NAME.SAVE')"
              icon="i-lucide-save"
              type="button"
              color="slate"
              variant="outline"
              :is-loading="isSavingTemplate"
              :disabled="
                !state.inboxId ||
                !templateName.trim() ||
                !state.messageBody.trim()
              "
              @click="saveTemplate"
            />
          </div>
        </div>

        <div
          class="flex flex-col gap-3 p-4 border border-dashed rounded-lg border-n-weak bg-n-alpha-1"
        >
          <div class="flex items-start justify-between gap-3">
            <div class="min-w-0">
              <p class="mb-1 text-sm font-medium text-n-slate-12">
                {{ t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.MEDIA.LABEL') }}
              </p>
              <p class="mb-0 text-sm truncate text-n-slate-11">
                {{
                  selectedFileName ||
                  t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.MEDIA.PLACEHOLDER')
                }}
              </p>
            </div>
            <div class="flex items-center gap-1">
              <Button
                :label="t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.MEDIA.CHOOSE')"
                icon="i-lucide-paperclip"
                type="button"
                color="slate"
                variant="ghost"
                size="sm"
                @click="handleFileClick"
              />
              <Button
                v-if="state.mediaFile"
                icon="i-lucide-trash"
                type="button"
                color="ruby"
                variant="ghost"
                size="sm"
                @click="removeFile"
              />
            </div>
          </div>
          <p class="mb-0 text-xs leading-5 text-n-slate-11">
            {{ t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.MEDIA.HELP') }}
          </p>
        </div>

        <div class="flex flex-col gap-1">
          <label class="mb-0.5 text-sm font-medium text-n-slate-12">
            {{ t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.AUDIENCE.LABEL') }}
          </label>
          <TagMultiSelectComboBox
            v-model="state.selectedAudience"
            :options="audienceOptions"
            :placeholder="
              t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.AUDIENCE.PLACEHOLDER')
            "
            class="[&>div]:bg-n-alpha-black2"
          />
        </div>

        <div class="relative flex min-w-0 flex-col gap-1">
          <label class="mb-0.5 text-sm font-medium text-n-slate-12">
            {{ t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.SCHEDULED_AT.LABEL') }}
          </label>
          <input
            :value="state.scheduledAt || ''"
            type="datetime-local"
            class="block h-10 w-full rounded-lg border-0 bg-n-alpha-black2 !px-3 !py-2.5 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak reset-base !mb-0 hover:outline-n-slate-6 focus:outline-n-brand"
            @input="state.scheduledAt = $event.target.value"
            @change="state.scheduledAt = $event.target.value"
          />
        </div>
      </div>
    </div>

    <input
      ref="fileInput"
      type="file"
      class="hidden"
      @change="handleFileChange"
    />

    <div
      class="flex items-center justify-between w-full gap-3 p-6 pt-4 border-t border-n-weak bg-n-alpha-2"
    >
      <Button
        variant="faded"
        color="slate"
        type="button"
        :label="t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.BUTTONS.CANCEL')"
        class="w-full"
        @click="close"
      />
      <Button
        type="submit"
        color="blue"
        :label="t('CAMPAIGN.WHATSAPP_API.CREATE.FORM.BUTTONS.CREATE')"
        class="w-full"
        :is-loading="isCreating"
        :disabled="!canSubmit || isCreating"
      />
    </div>
  </form>
</template>
