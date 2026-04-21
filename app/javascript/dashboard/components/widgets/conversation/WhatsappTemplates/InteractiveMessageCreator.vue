<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import WhatsappInteractiveTemplatesAPI from 'dashboard/api/whatsappInteractiveTemplates';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['templateCreated']);

const { t } = useI18n();
const store = useStore();
const showAlert = useAlert;
const accountId = useMapGetter('getCurrentAccountId');

const BODY_MAX = 1024;
const FOOTER_MAX = 60;
const HEADER_MAX = 60;
const BUTTON_TEXT_MAX = 20;

const name = ref('');
const templateType = ref('cta_url');
const headerType = ref('text');
const headerText = ref('');
const headerImageUrl = ref('');
const bodyText = ref('');
const footerText = ref('');
const buttonText = ref('Pagar agora');
const isSubmitting = ref(false);
const isPublishingImage = ref(false);
const errors = ref({});

const isCta = computed(() => templateType.value === 'cta_url');
const isRichText = computed(() => templateType.value === 'rich_text');

const templates = computed(
  () => store.getters['whatsappInteractiveTemplates/getTemplates']
);
const uiFlags = computed(
  () => store.getters['whatsappInteractiveTemplates/getUIFlags']
);

const previewHeader = computed(() => {
  if (headerType.value === 'image') return '';
  return headerText.value.trim();
});

const validate = () => {
  const nextErrors = {};

  if (!name.value.trim()) {
    nextErrors.name = t(
      'WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.NAME_REQUIRED'
    );
  }

  if (!bodyText.value.trim()) {
    nextErrors.body = t(
      'WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.BODY_REQUIRED'
    );
  } else if (bodyText.value.length > BODY_MAX) {
    nextErrors.body = t('WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.BODY_MAX');
  }

  if (headerType.value === 'text') {
    if (!headerText.value.trim()) {
      nextErrors.headerText = t(
        'WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.HEADER_TEXT_REQUIRED'
      );
    } else if (headerText.value.length > HEADER_MAX) {
      nextErrors.headerText = t(
        'WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.HEADER_MAX'
      );
    }
  }

  if (headerType.value === 'image' && !headerImageUrl.value.trim()) {
    nextErrors.headerImageUrl = t(
      'WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.HEADER_IMAGE_REQUIRED'
    );
  }

  if (footerText.value.length > FOOTER_MAX) {
    nextErrors.footer = t(
      'WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.FOOTER_MAX'
    );
  }

  if (isCta.value) {
    if (!buttonText.value.trim()) {
      nextErrors.button = t(
        'WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.BUTTON_REQUIRED'
      );
    } else if (buttonText.value.length > BUTTON_TEXT_MAX) {
      nextErrors.button = t(
        'WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.BUTTON_MAX'
      );
    }
  }

  errors.value = nextErrors;
  return Object.keys(nextErrors).length === 0;
};

const resetForm = () => {
  name.value = '';
  templateType.value = 'cta_url';
  headerType.value = 'text';
  headerText.value = '';
  headerImageUrl.value = '';
  bodyText.value = '';
  footerText.value = '';
  buttonText.value = 'Pagar agora';
  errors.value = {};
};

const publishHeaderImage = async event => {
  const [file] = event.target.files || [];
  if (!file) return;

  isPublishingImage.value = true;
  try {
    const { blobId } = await uploadFile(file, accountId.value);
    const response =
      await WhatsappInteractiveTemplatesAPI.publishHeader(blobId);
    headerImageUrl.value = response.data.file_url;
    errors.value.headerImageUrl = '';
    showAlert(t('WHATSAPP_TEMPLATES.INTERACTIVE.IMAGE_SUCCESS'));
  } catch (error) {
    const message =
      error?.response?.data?.error ||
      t('WHATSAPP_TEMPLATES.INTERACTIVE.IMAGE_ERROR');
    showAlert(message);
  } finally {
    isPublishingImage.value = false;
    event.target.value = '';
  }
};

const handleSubmit = async () => {
  if (!validate() || isSubmitting.value) return;

  isSubmitting.value = true;
  try {
    const payload = {
      name: name.value.trim(),
      template_type: templateType.value,
      header_type: headerType.value,
      header_text: headerType.value === 'text' ? headerText.value.trim() : '',
      header_image_url:
        headerType.value === 'image' ? headerImageUrl.value.trim() : '',
      body_text: bodyText.value.trim(),
      footer_text: footerText.value.trim(),
    };
    if (isCta.value) {
      payload.button_text = buttonText.value.trim();
    }
    await store.dispatch('whatsappInteractiveTemplates/create', {
      whatsapp_interactive_template: payload,
    });

    showAlert(t('WHATSAPP_TEMPLATES.INTERACTIVE.SUCCESS'));
    resetForm();
    emit('templateCreated');
  } catch (error) {
    const message =
      error?.response?.data?.error || t('WHATSAPP_TEMPLATES.INTERACTIVE.ERROR');
    showAlert(message);
  } finally {
    isSubmitting.value = false;
  }
};

const deleteTemplate = async id => {
  try {
    await store.dispatch('whatsappInteractiveTemplates/delete', id);
    showAlert(t('WHATSAPP_TEMPLATES.INTERACTIVE.DELETE_SUCCESS'));
  } catch {
    showAlert(t('WHATSAPP_TEMPLATES.INTERACTIVE.DELETE_ERROR'));
  }
};

onMounted(() => {
  store.dispatch('whatsappInteractiveTemplates/get');
});
</script>

<template>
  <div class="w-full">
    <div class="grid grid-cols-1 xl:grid-cols-[minmax(0,1fr)_18rem] gap-6">
      <div class="space-y-5">
        <!-- Message Type Selector -->
        <div>
          <p class="text-sm font-semibold text-n-slate-12 mb-2">
            {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.TYPE_LABEL') }}
          </p>
          <div class="flex gap-2">
            <button
              class="px-3 py-2 text-sm rounded-lg border"
              :class="
                templateType === 'cta_url'
                  ? 'border-n-brand text-n-brand bg-n-brand/10'
                  : 'border-n-weak text-n-slate-11'
              "
              @click="templateType = 'cta_url'"
            >
              {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.TYPE_CTA') }}
            </button>
            <button
              class="px-3 py-2 text-sm rounded-lg border"
              :class="
                templateType === 'rich_text'
                  ? 'border-n-brand text-n-brand bg-n-brand/10'
                  : 'border-n-weak text-n-slate-11'
              "
              @click="templateType = 'rich_text'"
            >
              {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.TYPE_BODY_LINK') }}
            </button>
          </div>
          <p v-if="isRichText" class="mt-1.5 text-xs text-n-slate-10">
            {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.TYPE_BODY_LINK_HINT') }}
          </p>
        </div>

        <div>
          <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
            {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.NAME_LABEL') }}
          </label>
          <input
            v-model="name"
            type="text"
            :placeholder="t('WHATSAPP_TEMPLATES.INTERACTIVE.NAME_PLACEHOLDER')"
            class="reset-base w-full h-10 px-3 rounded-xl bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand transition-all"
          />
          <p v-if="errors.name" class="mt-1 text-xs text-n-ruby-11">
            {{ errors.name }}
          </p>
        </div>

        <div>
          <p class="text-sm font-semibold text-n-slate-12 mb-2">
            {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.HEADER_LABEL') }}
          </p>
          <div class="flex gap-2 mb-3">
            <button
              class="px-3 py-2 text-sm rounded-lg border"
              :class="
                headerType === 'text'
                  ? 'border-n-brand text-n-brand bg-n-brand/10'
                  : 'border-n-weak text-n-slate-11'
              "
              @click="headerType = 'text'"
            >
              {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.HEADER_TEXT_OPTION') }}
            </button>
            <button
              class="px-3 py-2 text-sm rounded-lg border"
              :class="
                headerType === 'image'
                  ? 'border-n-brand text-n-brand bg-n-brand/10'
                  : 'border-n-weak text-n-slate-11'
              "
              @click="headerType = 'image'"
            >
              {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.HEADER_IMAGE_OPTION') }}
            </button>
          </div>

          <template v-if="headerType === 'text'">
            <input
              v-model="headerText"
              type="text"
              :maxlength="HEADER_MAX"
              :placeholder="
                t('WHATSAPP_TEMPLATES.INTERACTIVE.HEADER_TEXT_PLACEHOLDER')
              "
              class="reset-base w-full h-10 px-3 rounded-xl bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand transition-all"
            />
            <p v-if="errors.headerText" class="mt-1 text-xs text-n-ruby-11">
              {{ errors.headerText }}
            </p>
          </template>

          <template v-else>
            <div
              class="rounded-xl border border-dashed border-n-weak p-4 bg-n-alpha-1"
            >
              <div class="flex items-center gap-3">
                <label
                  class="inline-flex items-center gap-2 px-3 py-2 rounded-lg bg-n-brand text-white text-sm cursor-pointer"
                >
                  <Icon icon="i-lucide-upload" class="size-4" />
                  {{
                    isPublishingImage
                      ? t('WHATSAPP_TEMPLATES.INTERACTIVE.UPLOADING')
                      : t('WHATSAPP_TEMPLATES.INTERACTIVE.UPLOAD_BUTTON')
                  }}
                  <input
                    type="file"
                    accept="image/*"
                    class="hidden"
                    @change="publishHeaderImage"
                  />
                </label>
                <span class="text-xs text-n-slate-10">
                  {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.IMAGE_HINT') }}
                </span>
              </div>
              <p
                v-if="headerImageUrl"
                class="mt-3 text-xs text-n-slate-11 break-all"
              >
                {{ headerImageUrl }}
              </p>
              <p
                v-if="errors.headerImageUrl"
                class="mt-2 text-xs text-n-ruby-11"
              >
                {{ errors.headerImageUrl }}
              </p>
            </div>
          </template>
        </div>

        <div>
          <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
            {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.BODY_LABEL') }}
          </label>
          <textarea
            v-model="bodyText"
            rows="5"
            :maxlength="BODY_MAX"
            :placeholder="t('WHATSAPP_TEMPLATES.INTERACTIVE.BODY_PLACEHOLDER')"
            class="reset-base w-full px-3 py-2.5 rounded-xl bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand resize-none transition-all"
          />
          <p v-if="errors.body" class="mt-1 text-xs text-n-ruby-11">
            {{ errors.body }}
          </p>
        </div>

        <div>
          <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
            {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.FOOTER_LABEL') }}
          </label>
          <input
            v-model="footerText"
            type="text"
            :maxlength="FOOTER_MAX"
            :placeholder="
              t('WHATSAPP_TEMPLATES.INTERACTIVE.FOOTER_PLACEHOLDER')
            "
            class="reset-base w-full h-10 px-3 rounded-xl bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand transition-all"
          />
          <p v-if="errors.footer" class="mt-1 text-xs text-n-ruby-11">
            {{ errors.footer }}
          </p>
        </div>

        <div v-if="isCta">
          <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
            {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.BUTTON_LABEL') }}
          </label>
          <input
            v-model="buttonText"
            type="text"
            :maxlength="BUTTON_TEXT_MAX"
            :placeholder="
              t('WHATSAPP_TEMPLATES.INTERACTIVE.BUTTON_PLACEHOLDER')
            "
            class="reset-base w-full h-10 px-3 rounded-xl bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand transition-all"
          />
          <p v-if="errors.button" class="mt-1 text-xs text-n-ruby-11">
            {{ errors.button }}
          </p>
        </div>

        <div class="rounded-xl bg-n-slate-2 p-4 text-sm text-n-slate-11">
          <p class="font-semibold text-n-slate-12 mb-1">
            {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.RUNTIME_TITLE') }}
          </p>
          <p>{{ t('WHATSAPP_TEMPLATES.INTERACTIVE.RUNTIME_DESCRIPTION') }}</p>
        </div>

        <div class="flex justify-end pt-3 pb-1 border-t border-n-weak">
          <Button
            :is-loading="isSubmitting || uiFlags.isCreating"
            :disabled="isSubmitting || uiFlags.isCreating"
            :label="t('WHATSAPP_TEMPLATES.INTERACTIVE.SUBMIT')"
            icon="i-lucide-send"
            @click="handleSubmit"
          />
        </div>
      </div>

      <div class="space-y-4">
        <div>
          <p class="text-sm font-semibold text-n-slate-12 mb-3">
            {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.PREVIEW_TITLE') }}
          </p>
          <div class="rounded-2xl p-4 space-y-2 bg-[#e8ded3]">
            <div class="rounded-xl bg-white p-3.5 shadow-sm">
              <img
                v-if="headerType === 'image' && headerImageUrl"
                :src="headerImageUrl"
                alt="header preview"
                class="w-full rounded-lg max-h-44 object-cover mb-2"
              />
              <p
                v-else-if="previewHeader"
                class="font-semibold text-sm text-n-slate-12 mb-1.5"
              >
                {{ previewHeader }}
              </p>
              <p
                class="text-sm text-n-slate-12 whitespace-pre-wrap leading-relaxed"
              >
                {{
                  bodyText ||
                  t('WHATSAPP_TEMPLATES.INTERACTIVE.BODY_PLACEHOLDER')
                }}
              </p>
              <p
                v-if="footerText"
                class="text-xs text-n-slate-10 mt-2.5 pt-1.5 border-t border-n-weak/50"
              >
                {{ footerText }}
              </p>
            </div>
            <div
              v-if="isCta"
              class="text-center py-2 rounded-xl bg-white text-sm font-medium text-[#0088cc] shadow-sm"
            >
              {{
                buttonText ||
                t('WHATSAPP_TEMPLATES.INTERACTIVE.BUTTON_PLACEHOLDER')
              }}
            </div>
          </div>
        </div>

        <div>
          <div class="flex items-center justify-between mb-2">
            <p class="text-sm font-semibold text-n-slate-12">
              {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.EXISTING_TITLE') }}
            </p>
            <Icon
              v-if="uiFlags.isFetching"
              icon="i-lucide-loader-circle"
              class="size-4 animate-spin text-n-slate-10"
            />
          </div>
          <div class="space-y-2 max-h-72 overflow-y-auto pr-1">
            <div
              v-for="template in templates"
              :key="template.id"
              class="rounded-xl border border-n-weak p-3 bg-white"
            >
              <div class="flex items-start justify-between gap-2">
                <div>
                  <p class="text-sm font-medium text-n-slate-12">
                    {{ template.name }}
                  </p>
                  <p class="text-xs text-n-slate-10 mt-1 line-clamp-2">
                    {{ template.body_text }}
                  </p>
                </div>
                <button
                  class="text-n-ruby-11 hover:text-n-ruby-12"
                  @click="deleteTemplate(template.id)"
                >
                  <Icon icon="i-lucide-trash-2" class="size-4" />
                </button>
              </div>
              <div class="mt-2 flex gap-2 flex-wrap text-xs">
                <span class="px-2 py-1 rounded-lg bg-n-slate-2 text-n-slate-11">
                  {{
                    template.template_type === 'rich_text'
                      ? 'Link no corpo'
                      : 'CTA URL'
                  }}
                </span>
                <span class="px-2 py-1 rounded-lg bg-n-slate-2 text-n-slate-11">
                  {{ template.header_type }}
                </span>
              </div>
            </div>
            <p
              v-if="!templates.length && !uiFlags.isFetching"
              class="text-sm text-n-slate-10"
            >
              {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.NO_TEMPLATES') }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
