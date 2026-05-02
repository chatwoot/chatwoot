<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import WhatsappInteractiveTemplatesAPI from 'dashboard/api/whatsappInteractiveTemplates';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  conversationId: {
    type: Number,
    default: undefined,
  },
});

const emit = defineEmits(['templateCreated', 'templateSent']);

const { t } = useI18n();
const store = useStore();
const accountId = useMapGetter('getCurrentAccountId');

const BODY_MAX = 1024;
const FOOTER_MAX = 60;
const HEADER_MAX = 60;
const BUTTON_TEXT_MAX = 20;
const QUICK_REPLY_MAX = 20;
const URL_REGEX = /^https?:\/\/.+/i;

const TYPE_OPTIONS = [
  {
    value: 'cta_url',
    icon: 'i-lucide-mouse-pointer-click',
    titleKey: 'WHATSAPP_TEMPLATES.INTERACTIVE.TYPE_CTA',
    hintKey: 'WHATSAPP_TEMPLATES.INTERACTIVE.TYPE_CTA_HINT',
  },
  {
    value: 'quick_replies',
    icon: 'i-lucide-message-square-reply',
    titleKey: 'WHATSAPP_TEMPLATES.INTERACTIVE.TYPE_QUICK_REPLIES',
    hintKey: 'WHATSAPP_TEMPLATES.INTERACTIVE.TYPE_QUICK_REPLIES_HINT',
  },
  {
    value: 'rich_text',
    icon: 'i-lucide-link',
    titleKey: 'WHATSAPP_TEMPLATES.INTERACTIVE.TYPE_BODY_LINK',
    hintKey: 'WHATSAPP_TEMPLATES.INTERACTIVE.TYPE_BODY_LINK_HINT',
  },
];

const HEADER_TYPE_OPTIONS = [
  {
    value: 'none',
    icon: 'i-lucide-circle-slash',
    labelKey: 'WHATSAPP_TEMPLATES.INTERACTIVE.HEADER_TYPE_NONE',
  },
  {
    value: 'text',
    icon: 'i-lucide-type',
    labelKey: 'WHATSAPP_TEMPLATES.INTERACTIVE.HEADER_TEXT_OPTION',
  },
  {
    value: 'image',
    icon: 'i-lucide-image',
    labelKey: 'WHATSAPP_TEMPLATES.INTERACTIVE.HEADER_IMAGE_OPTION',
  },
];

const URL_MODE_DYNAMIC = 'dynamic';
const URL_MODE_STATIC = 'static';

const name = ref('');
const templateType = ref('cta_url');
const headerType = ref('none');
const headerText = ref('');
const headerImageUrl = ref('');
const bodyText = ref('');
const footerText = ref('');
const buttonText = ref('Pagar agora');
const urlMode = ref(URL_MODE_DYNAMIC);
const staticUrl = ref('');
const quickReplies = ref([]);
const isSubmitting = ref(false);
const isPublishingImage = ref(false);
const errors = ref({});

const isCta = computed(() => templateType.value === 'cta_url');
const isRichText = computed(() => templateType.value === 'rich_text');
const isQuickRepliesOnly = computed(
  () => templateType.value === 'quick_replies'
);

const activeTypeHintKey = computed(
  () =>
    TYPE_OPTIONS.find(opt => opt.value === templateType.value)?.hintKey ||
    TYPE_OPTIONS[0].hintKey
);

const maxQuickReplies = computed(() => (isCta.value ? 2 : 3));
const canAddQuickReply = computed(
  () => quickReplies.value.length < maxQuickReplies.value
);

const templates = computed(
  () => store.getters['whatsappInteractiveTemplates/getTemplates']
);
const uiFlags = computed(
  () => store.getters['whatsappInteractiveTemplates/getUIFlags']
);

const previewHeaderText = computed(() =>
  headerType.value === 'text' ? headerText.value.trim() : ''
);
const previewBodyText = computed(
  () => bodyText.value || t('WHATSAPP_TEMPLATES.INTERACTIVE.BODY_PLACEHOLDER')
);

watch(templateType, type => {
  if (type !== 'cta_url' && quickReplies.value.length > 3) {
    quickReplies.value = quickReplies.value.slice(0, 3);
  }
  if (type === 'cta_url' && quickReplies.value.length > 2) {
    quickReplies.value = quickReplies.value.slice(0, 2);
  }
});

const validate = () => {
  const e = {};

  if (!name.value.trim())
    e.name = t('WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.NAME_REQUIRED');

  if (!bodyText.value.trim())
    e.body = t('WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.BODY_REQUIRED');
  else if (bodyText.value.length > BODY_MAX)
    e.body = t('WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.BODY_MAX');

  if (headerType.value === 'text') {
    if (!headerText.value.trim())
      e.headerText = t(
        'WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.HEADER_TEXT_REQUIRED'
      );
    else if (headerText.value.length > HEADER_MAX)
      e.headerText = t('WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.HEADER_MAX');
  }

  if (headerType.value === 'image' && !headerImageUrl.value.trim()) {
    e.headerImage = t(
      'WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.HEADER_IMAGE_REQUIRED'
    );
  }

  if (footerText.value.length > FOOTER_MAX)
    e.footer = t('WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.FOOTER_MAX');

  if (isCta.value) {
    if (!buttonText.value.trim())
      e.button = t('WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.BUTTON_REQUIRED');
    else if (buttonText.value.length > BUTTON_TEXT_MAX)
      e.button = t('WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.BUTTON_MAX');

    if (urlMode.value === URL_MODE_STATIC) {
      const url = staticUrl.value.trim();
      if (!url)
        e.staticUrl = t(
          'WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.URL_REQUIRED'
        );
      else if (!URL_REGEX.test(url))
        e.staticUrl = t(
          'WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.URL_INVALID'
        );
    }
  }

  if (isQuickRepliesOnly.value && quickReplies.value.length === 0) {
    e.quickReplies = t(
      'WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.QUICK_REPLIES_AT_LEAST_ONE'
    );
  }

  if (quickReplies.value.length > maxQuickReplies.value) {
    e.quickReplies = isCta.value
      ? t(
          'WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.QUICK_REPLY_LIMIT_WITH_CTA'
        )
      : t(
          'WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.QUICK_REPLY_LIMIT_STANDALONE'
        );
  }

  quickReplies.value.forEach((qr, idx) => {
    const text = qr.text?.trim() || '';
    if (!text)
      e[`qr_${idx}`] = t(
        'WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.QUICK_REPLY_REQUIRED'
      );
    else if (text.length > QUICK_REPLY_MAX)
      e[`qr_${idx}`] = t(
        'WHATSAPP_TEMPLATES.INTERACTIVE.VALIDATION.QUICK_REPLY_MAX'
      );
  });

  errors.value = e;
  return Object.keys(e).length === 0;
};

const resetForm = () => {
  name.value = '';
  templateType.value = 'cta_url';
  headerType.value = 'none';
  headerText.value = '';
  headerImageUrl.value = '';
  bodyText.value = '';
  footerText.value = '';
  buttonText.value = 'Pagar agora';
  urlMode.value = URL_MODE_DYNAMIC;
  staticUrl.value = '';
  quickReplies.value = [];
  errors.value = {};
};

const addQuickReply = () => {
  if (canAddQuickReply.value) quickReplies.value.push({ text: '' });
};

const removeQuickReply = idx => {
  quickReplies.value.splice(idx, 1);
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
    errors.value.headerImage = '';
    useAlert(t('WHATSAPP_TEMPLATES.INTERACTIVE.IMAGE_SUCCESS'));
  } catch (error) {
    const message =
      error?.response?.data?.error ||
      t('WHATSAPP_TEMPLATES.INTERACTIVE.IMAGE_ERROR');
    useAlert(message);
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
      quick_replies: quickReplies.value
        .map(qr => ({ text: qr.text.trim() }))
        .filter(qr => qr.text),
    };

    if (isCta.value) {
      payload.button_text = buttonText.value.trim();
      payload.static_url =
        urlMode.value === URL_MODE_STATIC ? staticUrl.value.trim() : '';
    }

    await store.dispatch('whatsappInteractiveTemplates/create', {
      whatsapp_interactive_template: payload,
    });

    useAlert(t('WHATSAPP_TEMPLATES.INTERACTIVE.SUCCESS'));
    resetForm();
    emit('templateCreated');
  } catch (error) {
    const message =
      error?.response?.data?.error || t('WHATSAPP_TEMPLATES.INTERACTIVE.ERROR');
    useAlert(message);
  } finally {
    isSubmitting.value = false;
  }
};

const deleteTemplate = async (event, id) => {
  event?.stopPropagation();
  try {
    await store.dispatch('whatsappInteractiveTemplates/delete', id);
    useAlert(t('WHATSAPP_TEMPLATES.INTERACTIVE.DELETE_SUCCESS'));
  } catch {
    useAlert(t('WHATSAPP_TEMPLATES.INTERACTIVE.DELETE_ERROR'));
  }
};

const sendTemplate = async template => {
  if (!props.conversationId) {
    useAlert(t('WHATSAPP_TEMPLATES.INTERACTIVE.SEND_NO_CONVERSATION'));
    return;
  }
  try {
    await store.dispatch('whatsappInteractiveTemplates/dispatch', {
      templateId: template.id,
      conversationId: props.conversationId,
    });
    useAlert(t('WHATSAPP_TEMPLATES.INTERACTIVE.SEND_SUCCESS'));
    emit('templateSent');
  } catch (error) {
    const message =
      error?.response?.data?.error ||
      t('WHATSAPP_TEMPLATES.INTERACTIVE.SEND_ERROR');
    useAlert(message);
  }
};

onMounted(() => {
  store.dispatch('whatsappInteractiveTemplates/get');
});
</script>

<template>
  <div class="w-full">
    <div class="flex gap-5 items-start max-h-[calc(88vh-12rem)] min-h-[26rem]">
      <!-- Form Column (internal scroll keeps modal bounded) -->
      <div
        class="flex-1 min-w-0 space-y-4 overflow-y-auto overscroll-contain pr-3 -mr-3 pb-1 max-h-full"
      >
        <!-- Template Type Selector (horizontal compact) -->
        <div>
          <label class="block text-sm font-semibold text-n-slate-12 mb-2">
            {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.TYPE_LABEL') }}
          </label>
          <div
            class="flex p-1 rounded-xl bg-n-alpha-black2 outline outline-1 outline-n-weak"
          >
            <button
              v-for="opt in TYPE_OPTIONS"
              :key="opt.value"
              type="button"
              class="flex-1 flex items-center justify-center gap-1.5 px-2 py-2 rounded-lg text-sm font-medium transition-all cursor-pointer"
              :class="
                templateType === opt.value
                  ? 'bg-white dark:bg-n-solid-3 text-n-brand shadow-sm'
                  : 'text-n-slate-11 hover:text-n-slate-12'
              "
              @click="templateType = opt.value"
            >
              <Icon :icon="opt.icon" class="size-4 shrink-0" />
              <span class="truncate">{{ t(opt.titleKey) }}</span>
            </button>
          </div>
          <p class="mt-1.5 text-xs text-n-slate-10 leading-snug">
            {{ t(activeTypeHintKey) }}
          </p>
        </div>

        <!-- Name -->
        <div>
          <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
            {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.NAME_LABEL') }}
          </label>
          <input
            v-model="name"
            type="text"
            :placeholder="t('WHATSAPP_TEMPLATES.INTERACTIVE.NAME_PLACEHOLDER')"
            class="reset-base w-full h-10 px-3 rounded-xl bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand transition-all"
            autocomplete="off"
          />
          <p v-if="errors.name" class="mt-1 text-xs text-n-ruby-11">
            {{ errors.name }}
          </p>
        </div>

        <!-- Header Section -->
        <div>
          <label class="block text-sm font-semibold text-n-slate-12 mb-2">
            {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.HEADER_LABEL') }}
          </label>
          <div class="flex gap-2 mb-2.5">
            <button
              v-for="opt in HEADER_TYPE_OPTIONS"
              :key="opt.value"
              type="button"
              class="flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium rounded-lg outline outline-1 transition-colors cursor-pointer"
              :class="
                headerType === opt.value
                  ? 'bg-n-brand/10 outline-n-brand text-n-brand'
                  : 'bg-n-alpha-black2 outline-n-weak text-n-slate-11 hover:outline-n-slate-6'
              "
              @click="headerType = opt.value"
            >
              <Icon :icon="opt.icon" class="size-3.5" />
              {{ t(opt.labelKey) }}
            </button>
          </div>

          <input
            v-if="headerType === 'text'"
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

          <div
            v-if="headerType === 'image'"
            class="rounded-xl border border-dashed border-n-weak p-4 bg-n-alpha-black2"
          >
            <div class="flex items-center gap-3 flex-wrap">
              <label
                class="inline-flex items-center gap-2 px-3 py-2 rounded-lg bg-n-brand text-white text-sm font-medium cursor-pointer hover:brightness-110 transition-all"
              >
                <Icon
                  :icon="
                    isPublishingImage
                      ? 'i-lucide-loader-circle'
                      : 'i-lucide-upload'
                  "
                  class="size-4"
                  :class="{ 'animate-spin': isPublishingImage }"
                />
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
              <span class="text-xs text-n-slate-10 flex-1 min-w-[12rem]">
                {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.IMAGE_HINT') }}
              </span>
            </div>
            <p
              v-if="headerImageUrl"
              class="mt-3 text-xs text-n-slate-11 break-all"
            >
              {{ headerImageUrl }}
            </p>
            <p v-if="errors.headerImage" class="mt-2 text-xs text-n-ruby-11">
              {{ errors.headerImage }}
            </p>
          </div>
        </div>

        <!-- Body -->
        <div>
          <label class="block text-sm font-semibold text-n-slate-12 mb-1.5">
            {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.BODY_LABEL') }}
            <span class="text-n-ruby-11">*</span>
          </label>
          <textarea
            v-model="bodyText"
            rows="4"
            :maxlength="BODY_MAX"
            :placeholder="t('WHATSAPP_TEMPLATES.INTERACTIVE.BODY_PLACEHOLDER')"
            class="reset-base w-full px-3 py-2.5 rounded-xl bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand resize-none transition-all"
          />
          <div class="flex justify-between mt-1">
            <p v-if="errors.body" class="text-xs text-n-ruby-11">
              {{ errors.body }}
            </p>
            <p
              class="text-xs ml-auto"
              :class="
                BODY_MAX - bodyText.length < 50
                  ? 'text-n-ruby-11'
                  : 'text-n-slate-10'
              "
            >
              {{
                t('WHATSAPP_TEMPLATES.CREATOR.CHARS_REMAINING', {
                  count: BODY_MAX - bodyText.length,
                })
              }}
            </p>
          </div>
        </div>

        <!-- Footer -->
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

        <!-- CTA Button + URL (cta_url only) -->
        <div v-if="isCta" class="space-y-3">
          <div class="grid grid-cols-1 sm:grid-cols-[10rem_1fr] gap-2">
            <div>
              <label
                class="block text-xs font-semibold text-n-slate-11 uppercase tracking-wider mb-1.5"
              >
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
            </div>
            <div>
              <div class="flex items-center justify-between mb-1.5">
                <label
                  class="text-xs font-semibold text-n-slate-11 uppercase tracking-wider"
                >
                  {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.URL_MODE_LABEL') }}
                </label>
                <div
                  class="flex p-0.5 rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak"
                >
                  <button
                    type="button"
                    class="flex items-center gap-1 px-2 py-0.5 rounded-md text-xs font-medium transition-all cursor-pointer"
                    :class="
                      urlMode === URL_MODE_DYNAMIC
                        ? 'bg-white dark:bg-n-solid-3 text-n-brand shadow-sm'
                        : 'text-n-slate-11 hover:text-n-slate-12'
                    "
                    @click="urlMode = URL_MODE_DYNAMIC"
                  >
                    <Icon icon="i-lucide-zap" class="size-3" />
                    {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.URL_MODE_DYNAMIC') }}
                  </button>
                  <button
                    type="button"
                    class="flex items-center gap-1 px-2 py-0.5 rounded-md text-xs font-medium transition-all cursor-pointer"
                    :class="
                      urlMode === URL_MODE_STATIC
                        ? 'bg-white dark:bg-n-solid-3 text-n-brand shadow-sm'
                        : 'text-n-slate-11 hover:text-n-slate-12'
                    "
                    @click="urlMode = URL_MODE_STATIC"
                  >
                    <Icon icon="i-lucide-link" class="size-3" />
                    {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.URL_MODE_STATIC') }}
                  </button>
                </div>
              </div>
              <input
                v-if="urlMode === URL_MODE_STATIC"
                v-model="staticUrl"
                type="url"
                :placeholder="
                  t('WHATSAPP_TEMPLATES.INTERACTIVE.URL_STATIC_PLACEHOLDER')
                "
                class="reset-base w-full h-10 px-3 rounded-xl bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand transition-all"
                autocomplete="off"
              />
              <div
                v-else
                class="flex items-center gap-2 h-10 px-3 rounded-xl bg-n-slate-3 dark:bg-n-solid-2 text-n-slate-11 text-sm outline outline-1 outline-n-weak"
              >
                <Icon
                  icon="i-lucide-zap"
                  class="size-3.5 text-n-amber-9 shrink-0"
                />
                <span class="truncate">
                  {{
                    t('WHATSAPP_TEMPLATES.INTERACTIVE.URL_MODE_DYNAMIC_HINT')
                  }}
                </span>
              </div>
            </div>
          </div>
          <p v-if="errors.button" class="text-xs text-n-ruby-11">
            {{ errors.button }}
          </p>
          <p v-if="errors.staticUrl" class="text-xs text-n-ruby-11">
            {{ errors.staticUrl }}
          </p>
        </div>

        <!-- Quick Replies Section -->
        <div v-if="!isRichText">
          <div class="flex items-center justify-between mb-2">
            <label class="text-sm font-semibold text-n-slate-12">
              {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.QUICK_REPLIES_LABEL') }}
            </label>
            <span class="text-xs text-n-slate-10">
              {{ quickReplies.length }} / {{ maxQuickReplies }}
            </span>
          </div>
          <p class="text-xs text-n-slate-10 mb-2">
            {{
              isCta
                ? t(
                    'WHATSAPP_TEMPLATES.INTERACTIVE.QUICK_REPLIES_HINT_WITH_CTA'
                  )
                : t(
                    'WHATSAPP_TEMPLATES.INTERACTIVE.QUICK_REPLIES_HINT_STANDALONE'
                  )
            }}
          </p>

          <div v-if="quickReplies.length" class="space-y-2 mb-2">
            <div
              v-for="(qr, idx) in quickReplies"
              :key="idx"
              class="flex flex-col gap-1"
            >
              <div class="flex gap-2 items-center">
                <input
                  v-model="qr.text"
                  type="text"
                  :maxlength="QUICK_REPLY_MAX"
                  :placeholder="
                    t('WHATSAPP_TEMPLATES.INTERACTIVE.QUICK_REPLY_PLACEHOLDER')
                  "
                  class="reset-base flex-1 h-10 px-3 rounded-xl bg-n-alpha-black2 text-n-slate-12 text-sm outline outline-1 outline-n-weak hover:outline-n-slate-6 focus:outline-n-brand transition-all"
                />
                <button
                  type="button"
                  class="flex items-center justify-center w-10 h-10 rounded-xl hover:bg-n-alpha-2 dark:hover:bg-n-solid-2 text-n-slate-10 hover:text-n-ruby-11 transition-colors cursor-pointer"
                  :aria-label="
                    t('WHATSAPP_TEMPLATES.INTERACTIVE.REMOVE_QUICK_REPLY')
                  "
                  @click="removeQuickReply(idx)"
                >
                  <Icon icon="i-lucide-trash-2" class="size-4" />
                </button>
              </div>
              <p v-if="errors[`qr_${idx}`]" class="text-xs text-n-ruby-11 ml-1">
                {{ errors[`qr_${idx}`] }}
              </p>
            </div>
          </div>

          <button
            v-if="canAddQuickReply"
            type="button"
            class="flex items-center gap-1.5 text-sm font-medium text-n-brand hover:text-n-brand-dark transition-colors cursor-pointer"
            @click="addQuickReply"
          >
            <Icon icon="i-lucide-plus" class="size-4" />
            {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.ADD_QUICK_REPLY') }}
          </button>
          <p v-if="errors.quickReplies" class="mt-1.5 text-xs text-n-ruby-11">
            {{ errors.quickReplies }}
          </p>
        </div>

        <!-- Submit -->
        <div class="flex justify-end pt-3 pb-1 border-t border-n-weak">
          <Button
            :is-loading="isSubmitting || uiFlags.isCreating"
            :disabled="isSubmitting || uiFlags.isCreating"
            :label="t('WHATSAPP_TEMPLATES.INTERACTIVE.SUBMIT')"
            icon="i-lucide-save"
            @click="handleSubmit"
          />
        </div>
      </div>

      <!-- Preview Column -->
      <div
        class="w-64 shrink-0 self-start space-y-4 max-h-full overflow-y-auto pb-1"
      >
        <div>
          <p class="text-sm font-semibold text-n-slate-12 mb-3">
            {{ t('WHATSAPP_TEMPLATES.INTERACTIVE.PREVIEW_TITLE') }}
          </p>
          <div
            class="rounded-2xl p-4 space-y-2 bg-[linear-gradient(135deg,#e8ded3_0%,#d4cabe_100%)]"
          >
            <div class="rounded-xl bg-white dark:bg-n-solid-3 p-3.5 shadow-sm">
              <img
                v-if="headerType === 'image' && headerImageUrl"
                :src="headerImageUrl"
                alt="header preview"
                class="w-full rounded-lg max-h-44 object-cover mb-2"
              />
              <p
                v-else-if="previewHeaderText"
                class="font-semibold text-sm text-n-slate-12 mb-1.5"
              >
                {{ previewHeaderText }}
              </p>
              <p
                class="text-sm text-n-slate-12 whitespace-pre-wrap leading-relaxed"
              >
                {{ previewBodyText }}
              </p>
              <p
                v-if="footerText"
                class="text-xs text-n-slate-10 mt-2.5 pt-1.5 border-t border-n-weak/50"
              >
                {{ footerText }}
              </p>
            </div>

            <!-- CTA URL button (single, blue with arrow icon) -->
            <div
              v-if="isCta"
              class="flex items-center justify-center gap-1.5 py-2 rounded-xl bg-white dark:bg-n-solid-3 text-sm font-medium text-[#0088cc] shadow-sm"
            >
              <Icon icon="i-lucide-external-link" class="size-3.5" />
              {{
                buttonText ||
                t('WHATSAPP_TEMPLATES.INTERACTIVE.BUTTON_PLACEHOLDER')
              }}
            </div>

            <!-- Quick reply buttons -->
            <div
              v-for="(qr, idx) in quickReplies"
              :key="`qr-${idx}`"
              class="text-center py-2 rounded-xl bg-white dark:bg-n-solid-3 text-sm font-medium text-[#0088cc] shadow-sm"
            >
              {{
                qr.text ||
                `${t('WHATSAPP_TEMPLATES.INTERACTIVE.QUICK_REPLY_PLACEHOLDER')} ${idx + 1}`
              }}
            </div>
          </div>
        </div>

        <!-- Saved Messages -->
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
            <button
              v-for="template in templates"
              :key="template.id"
              type="button"
              class="w-full text-left rounded-xl outline outline-1 outline-n-weak p-3 bg-white dark:bg-n-solid-3 hover:outline-n-brand hover:bg-n-brand/5 transition-all cursor-pointer group disabled:opacity-50 disabled:cursor-wait"
              :disabled="uiFlags.isDispatching"
              @click="sendTemplate(template)"
            >
              <div class="flex items-start justify-between gap-2">
                <div class="min-w-0 flex-1">
                  <div class="flex items-center gap-1.5">
                    <p class="text-sm font-medium text-n-slate-12 truncate">
                      {{ template.name }}
                    </p>
                    <Icon
                      icon="i-lucide-send"
                      class="size-3 text-n-brand opacity-0 group-hover:opacity-100 transition-opacity shrink-0"
                    />
                  </div>
                  <p class="text-xs text-n-slate-10 mt-1 line-clamp-2">
                    {{ template.body_text }}
                  </p>
                </div>
                <span
                  role="button"
                  tabindex="0"
                  class="text-n-slate-10 hover:text-n-ruby-11 transition-colors cursor-pointer shrink-0"
                  :aria-label="
                    t('WHATSAPP_TEMPLATES.INTERACTIVE.DELETE_SUCCESS')
                  "
                  @click="deleteTemplate($event, template.id)"
                  @keydown.enter="deleteTemplate($event, template.id)"
                  @keydown.space="deleteTemplate($event, template.id)"
                >
                  <Icon icon="i-lucide-trash-2" class="size-4" />
                </span>
              </div>
              <div class="mt-2 flex gap-1.5 flex-wrap">
                <span
                  class="px-2 py-0.5 rounded-md bg-n-slate-3 dark:bg-n-solid-2 text-xs text-n-slate-11 font-medium"
                >
                  {{
                    template.template_type === 'rich_text'
                      ? t('WHATSAPP_TEMPLATES.INTERACTIVE.TYPE_BODY_LINK')
                      : template.template_type === 'quick_replies'
                        ? t('WHATSAPP_TEMPLATES.INTERACTIVE.TYPE_QUICK_REPLIES')
                        : t('WHATSAPP_TEMPLATES.INTERACTIVE.TYPE_CTA')
                  }}
                </span>
                <span
                  v-if="template.header_type && template.header_type !== 'none'"
                  class="px-2 py-0.5 rounded-md bg-n-slate-3 dark:bg-n-solid-2 text-xs text-n-slate-11 font-medium"
                >
                  {{ template.header_type }}
                </span>
              </div>
            </button>
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
