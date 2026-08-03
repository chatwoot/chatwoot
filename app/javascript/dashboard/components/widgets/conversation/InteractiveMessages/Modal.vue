<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { CONTENT_TYPES } from 'dashboard/components-next/message/constants';
import { isValidURL } from 'dashboard/helper/URLHelper';
import Button from 'dashboard/components-next/button/Button.vue';
import CtaUrlForm from './CtaUrlForm.vue';
import ButtonsForm from './ButtonsForm.vue';
import ListForm from './ListForm.vue';
import CarouselForm from './CarouselForm.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  allowListType: {
    type: Boolean,
    default: false,
  },
  isInstagram: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['onSend', 'cancel', 'update:show']);

const BUTTON_TITLE_MAX_LENGTH = 20;
const LIST_HEADER_TEXT_MAX_LENGTH = 60;
const LIST_FOOTER_TEXT_MAX_LENGTH = 60;
const LIST_SECTION_TITLE_MAX_LENGTH = 24;
const MIN_CARDS = 2;

const { t } = useI18n();

const localShow = computed({
  get() {
    return props.show;
  },
  set(value) {
    emit('update:show', value);
  },
});

const typeOptions = computed(() =>
  [
    {
      value: CONTENT_TYPES.CTA_URL,
      label: t('INTERACTIVE_MESSAGES.TYPES.CTA_URL'),
    },
    {
      value: CONTENT_TYPES.INTERACTIVE_BUTTONS,
      label: t('INTERACTIVE_MESSAGES.TYPES.INTERACTIVE_BUTTONS'),
    },
    props.allowListType && {
      value: CONTENT_TYPES.INTERACTIVE_LIST,
      label: t('INTERACTIVE_MESSAGES.TYPES.INTERACTIVE_LIST'),
    },
    {
      value: CONTENT_TYPES.CARDS,
      label: t('INTERACTIVE_MESSAGES.TYPES.CARDS'),
    },
  ].filter(Boolean)
);

const selectedType = ref(CONTENT_TYPES.CTA_URL);

// The modal instance persists across conversations. If an agent selects the
// list type on a WhatsApp conversation and then switches to a channel that
// doesn't support it, the list tab disappears from typeOptions but the form
// and onSend path would otherwise remain on interactive_list.
watch(
  () => props.allowListType,
  allowListType => {
    if (
      !allowListType &&
      selectedType.value === CONTENT_TYPES.INTERACTIVE_LIST
    ) {
      selectedType.value = CONTENT_TYPES.CTA_URL;
    }
  }
);

const ctaUrlForm = ref({
  bodyText: '',
  footerText: '',
  headerMediaUrl: '',
  buttonText: '',
  buttonUrl: '',
});

const buttonsForm = ref({
  bodyText: '',
  footerText: '',
  headerMediaUrl: '',
  buttons: [{ id: 'btn_1', text: '' }],
});

const listForm = ref({
  bodyText: '',
  footerText: '',
  headerText: '',
  listButtonText: '',
  sections: [{ title: '', rows: [{ title: '', description: '' }] }],
});

const carouselForm = ref({
  bodyText: '',
  cards: [
    {
      id: 'card_1',
      mediaUrl: '',
      title: '',
      description: '',
      actionType: 'reply',
      actionText: '',
      actionUrl: '',
    },
    {
      id: 'card_2',
      mediaUrl: '',
      title: '',
      description: '',
      actionType: 'reply',
      actionText: '',
      actionUrl: '',
    },
  ],
});

// Header images are optional, so they're valid until proven otherwise by
// the async load check in HeaderImageInput.vue.
const isCtaHeaderImageValid = ref(true);
const isButtonsHeaderImageValid = ref(true);
const isCardsMediaValid = ref(true);

const isCtaUrlValid = computed(
  () =>
    !!ctaUrlForm.value.bodyText &&
    !!ctaUrlForm.value.buttonText &&
    isValidURL(ctaUrlForm.value.buttonUrl) &&
    isCtaHeaderImageValid.value
);

const isButtonsValid = computed(
  () =>
    !!buttonsForm.value.bodyText &&
    buttonsForm.value.buttons.length > 0 &&
    buttonsForm.value.buttons.every(
      button => !!button.text && button.text.length <= BUTTON_TITLE_MAX_LENGTH
    ) &&
    // Header image is only shown (and sent) for non-Instagram channels, so
    // only gate on its validity there.
    (props.isInstagram || isButtonsHeaderImageValid.value)
);

const isListValid = computed(
  () =>
    !!listForm.value.bodyText &&
    !!listForm.value.listButtonText &&
    listForm.value.headerText.length <= LIST_HEADER_TEXT_MAX_LENGTH &&
    listForm.value.footerText.length <= LIST_FOOTER_TEXT_MAX_LENGTH &&
    listForm.value.sections.length > 0 &&
    listForm.value.sections.every(
      section =>
        section.title.length <= LIST_SECTION_TITLE_MAX_LENGTH &&
        section.rows.length > 0 &&
        section.rows.every(row => !!row.title)
    )
);

const isCardsValid = computed(
  () =>
    !!carouselForm.value.bodyText &&
    carouselForm.value.cards.length >= MIN_CARDS &&
    carouselForm.value.cards.every(
      card =>
        !!card.title &&
        !!card.actionText &&
        (card.actionType !== 'url' || isValidURL(card.actionUrl))
    ) &&
    isCardsMediaValid.value
);

const isFormValid = computed(() => {
  if (selectedType.value === CONTENT_TYPES.CTA_URL) return isCtaUrlValid.value;
  if (selectedType.value === CONTENT_TYPES.INTERACTIVE_BUTTONS)
    return isButtonsValid.value;
  if (selectedType.value === CONTENT_TYPES.INTERACTIVE_LIST)
    return isListValid.value;
  if (selectedType.value === CONTENT_TYPES.CARDS) return isCardsValid.value;
  return false;
});

const buildCtaUrlAttributes = () => {
  const { bodyText, footerText, headerMediaUrl, buttonText, buttonUrl } =
    ctaUrlForm.value;
  return {
    body_text: bodyText,
    footer_text: footerText || undefined,
    header: headerMediaUrl
      ? { type: 'image', media_url: headerMediaUrl }
      : undefined,
    action: { text: buttonText, uri: buttonUrl },
  };
};

const buildButtonsAttributes = () => {
  const { bodyText, footerText, headerMediaUrl, buttons } = buttonsForm.value;
  return {
    body_text: bodyText,
    footer_text: !props.isInstagram && footerText ? footerText : undefined,
    header:
      !props.isInstagram && headerMediaUrl
        ? { type: 'image', media_url: headerMediaUrl }
        : undefined,
    buttons: buttons.map((button, index) => ({
      id: button.id || `btn_${index + 1}`,
      text: button.text,
    })),
  };
};

const buildListAttributes = () => {
  const { bodyText, footerText, headerText, listButtonText, sections } =
    listForm.value;
  return {
    body_text: bodyText,
    footer_text: footerText || undefined,
    header: headerText ? { type: 'text', text: headerText } : undefined,
    action: { button_text: listButtonText },
    sections: sections.map((section, sectionIndex) => ({
      title: section.title || undefined,
      rows: section.rows.map((row, rowIndex) => ({
        id: `row_${sectionIndex + 1}_${rowIndex + 1}`,
        title: row.title,
        description: row.description || undefined,
      })),
    })),
  };
};

const buildCarouselAttributes = () => {
  const { bodyText, cards } = carouselForm.value;
  return {
    body_text: bodyText,
    items: cards.map(card => ({
      title: card.title,
      description: card.description || undefined,
      media_url: card.mediaUrl || undefined,
      actions: [
        card.actionType === 'url'
          ? { type: 'url', text: card.actionText, uri: card.actionUrl }
          : {
              type: 'reply',
              text: card.actionText,
              payload: card.id,
            },
      ],
    })),
  };
};

const currentBodyText = computed(() => {
  if (selectedType.value === CONTENT_TYPES.CTA_URL)
    return ctaUrlForm.value.bodyText;
  if (selectedType.value === CONTENT_TYPES.INTERACTIVE_BUTTONS)
    return buttonsForm.value.bodyText;
  if (selectedType.value === CONTENT_TYPES.CARDS)
    return carouselForm.value.bodyText;
  return listForm.value.bodyText;
});

const previewHeaderMediaUrl = computed(() => {
  if (selectedType.value === CONTENT_TYPES.CTA_URL)
    return ctaUrlForm.value.headerMediaUrl;
  if (
    selectedType.value === CONTENT_TYPES.INTERACTIVE_BUTTONS &&
    !props.isInstagram
  )
    return buttonsForm.value.headerMediaUrl;
  return '';
});

const previewHeaderText = computed(() =>
  selectedType.value === CONTENT_TYPES.INTERACTIVE_LIST
    ? listForm.value.headerText
    : ''
);

const previewFooterText = computed(() => {
  if (selectedType.value === CONTENT_TYPES.CTA_URL)
    return ctaUrlForm.value.footerText;
  if (selectedType.value === CONTENT_TYPES.INTERACTIVE_BUTTONS)
    return props.isInstagram ? '' : buttonsForm.value.footerText;
  return listForm.value.footerText;
});

const onSend = () => {
  if (!isFormValid.value) return;

  let contentAttributes = {};
  if (selectedType.value === CONTENT_TYPES.CTA_URL) {
    contentAttributes = buildCtaUrlAttributes();
  } else if (selectedType.value === CONTENT_TYPES.INTERACTIVE_BUTTONS) {
    contentAttributes = buildButtonsAttributes();
  } else if (selectedType.value === CONTENT_TYPES.INTERACTIVE_LIST) {
    contentAttributes = buildListAttributes();
  } else {
    contentAttributes = buildCarouselAttributes();
  }

  emit('onSend', {
    message: currentBodyText.value,
    contentType: selectedType.value,
    contentAttributes,
  });
};

const onClose = () => {
  emit('cancel');
};
</script>

<template>
  <woot-modal
    v-model:show="localShow"
    :on-close="onClose"
    size="!w-[calc(100vw-2rem)] !max-w-xl sm:!max-w-2xl"
  >
    <woot-modal-header
      :header-title="t('INTERACTIVE_MESSAGES.MODAL.TITLE')"
      :header-content="t('INTERACTIVE_MESSAGES.MODAL.SUBTITLE')"
    />
    <div class="flex flex-col gap-5 px-4 py-4 sm:px-8 sm:py-6">
      <div class="flex flex-wrap gap-2">
        <Button
          v-for="option in typeOptions"
          :key="option.value"
          :label="option.label"
          size="sm"
          :variant="selectedType === option.value ? 'solid' : 'faded'"
          :color="selectedType === option.value ? 'blue' : 'slate'"
          @click="selectedType = option.value"
        />
      </div>

      <div class="flex flex-col h-[min(28rem,55vh)] gap-5 sm:flex-row">
        <div class="flex-1 min-w-0 overflow-y-auto pr-1">
          <CtaUrlForm
            v-if="selectedType === CONTENT_TYPES.CTA_URL"
            v-model="ctaUrlForm"
            @update:header-image-valid="
              value => (isCtaHeaderImageValid = value)
            "
          />
          <ButtonsForm
            v-else-if="selectedType === CONTENT_TYPES.INTERACTIVE_BUTTONS"
            v-model="buttonsForm"
            :show-header-image="!isInstagram"
            :show-footer-text="!isInstagram"
            @update:header-image-valid="
              value => (isButtonsHeaderImageValid = value)
            "
          />
          <ListForm
            v-else-if="selectedType === CONTENT_TYPES.INTERACTIVE_LIST"
            v-model="listForm"
          />
          <CarouselForm
            v-else
            v-model="carouselForm"
            @update:header-image-valid="value => (isCardsMediaValid = value)"
          />
        </div>

        <div
          class="flex flex-col items-center flex-shrink-0 gap-2 pr-1 overflow-y-auto sm:w-56"
        >
          <p class="self-start text-sm font-medium text-n-slate-11">
            {{ t('INTERACTIVE_MESSAGES.PREVIEW.TITLE') }}
          </p>

          <div
            v-if="selectedType === CONTENT_TYPES.CARDS"
            class="flex flex-col w-full gap-3"
          >
            <div
              v-for="(card, cardIndex) in carouselForm.cards"
              :key="card.id"
              class="w-full overflow-hidden border rounded-xl border-n-container bg-n-solid-2"
            >
              <img
                v-if="card.mediaUrl"
                :src="card.mediaUrl"
                alt=""
                class="object-cover w-full h-24"
              />
              <div class="flex flex-col gap-1 px-3 py-2">
                <p
                  v-if="card.title"
                  class="text-sm font-semibold text-n-slate-12"
                >
                  {{ card.title }}
                </p>
                <p v-if="card.description" class="text-xs text-n-slate-11">
                  {{ card.description }}
                </p>
              </div>
              <div
                v-if="card.actionText"
                class="px-3 py-2 text-xs font-medium text-center border-t text-n-teal-11 border-n-container"
              >
                {{ card.actionText }}
              </div>
              <p v-else class="px-3 py-2 text-xs text-center text-n-slate-10">
                {{
                  t('INTERACTIVE_MESSAGES.FIELDS.CARD_TITLE') +
                  ' ' +
                  (cardIndex + 1)
                }}
              </p>
            </div>
          </div>

          <div
            v-else
            class="w-full overflow-hidden border rounded-xl border-n-container bg-n-solid-2"
          >
            <img
              v-if="previewHeaderMediaUrl"
              :src="previewHeaderMediaUrl"
              alt=""
              class="w-full h-40 object-cover"
            />
            <div class="flex flex-col gap-2 px-4 pt-4 pb-3">
              <h4
                v-if="previewHeaderText"
                class="text-lg font-semibold text-n-slate-12"
              >
                {{ previewHeaderText }}
              </h4>
              <p
                class="text-sm font-medium break-words whitespace-pre-line text-n-slate-12"
              >
                {{
                  currentBodyText ||
                  t('INTERACTIVE_MESSAGES.FIELDS.BODY_TEXT_PLACEHOLDER')
                }}
              </p>
              <p v-if="previewFooterText" class="text-xs text-n-slate-11">
                {{ previewFooterText }}
              </p>
            </div>

            <a
              v-if="
                selectedType === CONTENT_TYPES.CTA_URL && ctaUrlForm.buttonText
              "
              class="flex items-center justify-center px-4 py-3 font-medium border-t text-n-teal-11 border-n-container"
            >
              {{ ctaUrlForm.buttonText }}
            </a>

            <div
              v-else-if="
                selectedType === CONTENT_TYPES.INTERACTIVE_BUTTONS &&
                buttonsForm.buttons.some(button => button.text)
              "
              class="border-t border-n-container"
            >
              <div
                v-for="(button, index) in buttonsForm.buttons"
                v-show="button.text"
                :key="button.id"
                class="px-4 py-3 font-medium text-center text-n-teal-11"
                :class="{ 'border-t border-n-container': index !== 0 }"
              >
                {{ button.text }}
              </div>
            </div>

            <template
              v-else-if="selectedType === CONTENT_TYPES.INTERACTIVE_LIST"
            >
              <div
                v-if="listForm.listButtonText"
                class="flex items-center justify-center gap-2 px-4 py-3 font-medium border-y text-n-teal-11 border-n-container"
              >
                {{ listForm.listButtonText }}
              </div>
              <div class="flex flex-col gap-3 px-4 py-3 bg-n-alpha-1">
                <div
                  v-for="(section, sectionIndex) in listForm.sections"
                  :key="sectionIndex"
                  class="flex flex-col gap-1"
                >
                  <p
                    v-if="section.title"
                    class="text-sm font-semibold text-n-slate-11"
                  >
                    {{ section.title }}
                  </p>
                  <div
                    v-for="(row, rowIndex) in section.rows"
                    v-show="row.title"
                    :key="rowIndex"
                    class="px-3 py-2 border rounded-lg border-n-container bg-n-background"
                  >
                    <p class="font-medium text-n-slate-12">{{ row.title }}</p>
                    <p v-if="row.description" class="text-xs text-n-slate-11">
                      {{ row.description }}
                    </p>
                  </div>
                </div>
              </div>
            </template>
          </div>
        </div>
      </div>

      <div class="flex justify-end gap-2">
        <Button
          :label="t('INTERACTIVE_MESSAGES.CANCEL')"
          variant="faded"
          color="slate"
          @click="onClose"
        />
        <Button
          :label="t('INTERACTIVE_MESSAGES.SEND')"
          :disabled="!isFormValid"
          @click="onSend"
        />
      </div>
    </div>
  </woot-modal>
</template>
