<script setup>
import { computed } from 'vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import WhatsAppInteractivePreview from './WhatsAppInteractivePreview.vue';
import { isValidHttpUrl } from './urlValidation';

const props = defineProps({
  modelValue: { type: Object, required: true },
  type: { type: String, required: true },
  capabilities: { type: Object, default: () => ({}) },
  accountMode: { type: String, default: '' },
  limits: { type: Object, required: true },
  presets: { type: Array, default: () => [] },
  presetSearch: { type: String, default: '' },
  presetsLoading: { type: Boolean, default: false },
  selectedPreset: { type: Object, default: null },
  presetName: { type: String, default: '' },
  presetBusy: { type: Boolean, default: false },
  structurallyValid: { type: Boolean, default: false },
});
const emit = defineEmits([
  'update:modelValue',
  'selectType',
  'close',
  'upload',
  'searchPresets',
  'selectPreset',
  'update:presetName',
  'savePreset',
  'updatePreset',
  'deletePreset',
]);
let carouselKeySequence = 0;
const nextCarouselKey = prefix => {
  carouselKeySequence += 1;
  return `${prefix}-${carouselKeySequence}`;
};

const supportedTypes = computed(() =>
  Object.entries(props.capabilities).map(([type, capability]) => ({
    type,
    ...capability,
  }))
);
const mediaHeader = computed(() =>
  ['image', 'video', 'document'].includes(props.modelValue.headerType)
);
const duplicateTitles = computed(() => {
  const titles =
    props.modelValue.buttons?.map(button =>
      (typeof button === 'string' ? button : button.title).trim()
    ) ?? [];
  return titles.some(
    (title, index) => title && titles.indexOf(title) !== index
  );
});
const totalRows = computed(() =>
  (props.modelValue.sections ?? []).reduce(
    (count, section) => count + section.rows.length,
    0
  )
);
const normalizedLength = value => value?.trim().length ?? 0;
const isValidUrl = computed(() => {
  const value = props.modelValue.url?.trim();
  return isValidHttpUrl(value, props.limits.urlSchemes);
});
const carouselReplyCountMismatch = computed(() => {
  if (
    props.type !== 'carousel' ||
    props.modelValue.actionMode !== 'quick_reply'
  )
    return false;
  const counts = props.modelValue.cards.map(card => card.action.buttons.length);
  return counts.some(count => count !== counts[0]);
});
const hasDuplicateReplies = card => {
  const titles = card.action.buttons.map(button => button.title.trim());
  return titles.some(
    (title, index) => title && titles.indexOf(title) !== index
  );
};
const lineBreakCount = value => value?.match(/\r\n|\r|\n/g)?.length ?? 0;

const update = (field, value) => {
  emit('update:modelValue', { ...props.modelValue, [field]: value });
};
const updateHeaderType = headerType => {
  emit('update:modelValue', {
    ...props.modelValue,
    headerType,
    headerText: '',
    media: null,
    uploadFile: null,
  });
};
const upload = event => {
  const file = event.target.files?.[0];
  if (file) emit('upload', file);
  event.target.value = '';
};
const removeMedia = () => {
  emit('update:modelValue', {
    ...props.modelValue,
    media: null,
    uploadFile: null,
  });
};
const updateButton = (index, title) => {
  const buttons = [...props.modelValue.buttons];
  const current = buttons[index];
  buttons[index] = typeof current === 'string' ? title : { ...current, title };
  update('buttons', buttons);
};
const addButton = () => update('buttons', [...props.modelValue.buttons, '']);
const removeButton = index =>
  update(
    'buttons',
    props.modelValue.buttons.filter((_, buttonIndex) => buttonIndex !== index)
  );
const updateSection = (sectionIndex, field, value) => {
  const sections = props.modelValue.sections.map((section, index) =>
    index === sectionIndex ? { ...section, [field]: value } : section
  );
  update('sections', sections);
};
const updateRow = (sectionIndex, rowIndex, field, value) => {
  const rows = props.modelValue.sections[sectionIndex].rows.map((row, index) =>
    index === rowIndex ? { ...row, [field]: value } : row
  );
  updateSection(sectionIndex, 'rows', rows);
};
const addSection = () =>
  update('sections', [
    ...props.modelValue.sections,
    { title: '', rows: [{ title: '', description: '' }] },
  ]);
const removeSection = sectionIndex =>
  update(
    'sections',
    props.modelValue.sections.filter((_, index) => index !== sectionIndex)
  );
const addRow = sectionIndex =>
  updateSection(sectionIndex, 'rows', [
    ...props.modelValue.sections[sectionIndex].rows,
    { title: '', description: '' },
  ]);
const removeRow = (sectionIndex, rowIndex) =>
  updateSection(
    sectionIndex,
    'rows',
    props.modelValue.sections[sectionIndex].rows.filter(
      (_, index) => index !== rowIndex
    )
  );
const updateCarouselMode = actionMode => {
  const cards = props.modelValue.cards.map(card => ({
    ...card,
    action:
      actionMode === 'url'
        ? { button: '', url: '' }
        : { buttons: [{ clientKey: `${card.clientKey}-reply-1`, title: '' }] },
  }));
  emit('update:modelValue', { ...props.modelValue, actionMode, cards });
};
const updateCard = (cardIndex, field, value) => {
  const cards = props.modelValue.cards.map((card, index) =>
    index === cardIndex ? { ...card, [field]: value } : card
  );
  update('cards', cards);
};
const updateCardAction = (cardIndex, field, value) => {
  const card = props.modelValue.cards[cardIndex];
  updateCard(cardIndex, 'action', { ...card.action, [field]: value });
};
const addCard = () => {
  const existingKeys = new Set(
    props.modelValue.cards.map(card => card.clientKey).filter(Boolean)
  );
  let clientKey;
  do {
    clientKey = nextCarouselKey('carousel-card');
  } while (existingKeys.has(clientKey));
  update('cards', [
    ...props.modelValue.cards,
    {
      clientKey,
      body: '',
      action:
        props.modelValue.actionMode === 'url'
          ? { button: '', url: '' }
          : { buttons: [{ clientKey: `${clientKey}-reply-1`, title: '' }] },
    },
  ]);
};
const removeCard = cardIndex =>
  update(
    'cards',
    props.modelValue.cards.filter((_, index) => index !== cardIndex)
  );
const moveCard = (cardIndex, offset) => {
  const cards = [...props.modelValue.cards];
  const [card] = cards.splice(cardIndex, 1);
  cards.splice(cardIndex + offset, 0, card);
  update('cards', cards);
};
const uploadCard = (event, card) => {
  const file = event.target.files?.[0];
  if (file) emit('upload', file, card.clientKey);
  event.target.value = '';
};
const removeCardMedia = cardIndex => {
  const card = props.modelValue.cards[cardIndex];
  const cards = props.modelValue.cards.map((item, index) =>
    index === cardIndex ? { ...card, media: null, uploadFile: null } : item
  );
  update('cards', cards);
};
const updateReply = (cardIndex, replyIndex, title) => {
  const card = props.modelValue.cards[cardIndex];
  const buttons = card.action.buttons.map((button, index) =>
    index === replyIndex ? { ...button, title } : button
  );
  updateCardAction(cardIndex, 'buttons', buttons);
};
const addReply = cardIndex => {
  const card = props.modelValue.cards[cardIndex];
  const existingKeys = new Set(
    card.action.buttons.map(button => button.clientKey).filter(Boolean)
  );
  let sequence = 1;
  let clientKey = `${card.clientKey}-reply-${sequence}`;
  while (existingKeys.has(clientKey)) {
    sequence += 1;
    clientKey = `${card.clientKey}-reply-${sequence}`;
  }
  updateCardAction(cardIndex, 'buttons', [
    ...card.action.buttons,
    {
      clientKey,
      title: '',
    },
  ]);
};
const removeReply = (cardIndex, replyIndex) => {
  const buttons = props.modelValue.cards[cardIndex].action.buttons.filter(
    (_, index) => index !== replyIndex
  );
  updateCardAction(cardIndex, 'buttons', buttons);
};
const moveReply = (cardIndex, replyIndex, offset) => {
  const buttons = [...props.modelValue.cards[cardIndex].action.buttons];
  const [button] = buttons.splice(replyIndex, 1);
  buttons.splice(replyIndex + offset, 0, button);
  updateCardAction(cardIndex, 'buttons', buttons);
};
</script>

<template>
  <section
    class="flex flex-col gap-3 py-3"
    data-testid="whatsapp-interactive-composer"
    :inert="presetBusy || undefined"
    :aria-busy="presetBusy"
  >
    <div class="flex items-center justify-between gap-3">
      <div>
        <h3 class="mb-0 text-sm font-medium text-n-slate-12">
          {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.TITLE') }}
        </h3>
        <p class="mb-0 text-xs text-n-slate-11">
          {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.DESCRIPTION') }}
        </p>
      </div>
      <Button
        icon="i-ph-x"
        slate
        faded
        xs
        :aria-label="$t('CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.CLOSE')"
        @click="$emit('close')"
      />
    </div>

    <p
      v-if="accountMode === 'test'"
      class="mb-0 rounded-lg bg-n-amber-2 px-3 py-2 text-xs text-n-amber-11"
      data-testid="whatsapp-test-mode"
    >
      {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.TEST_MODE') }}
    </p>

    <section class="flex flex-col gap-2 rounded-lg border border-n-weak p-3">
      <h4 class="mb-0 text-sm font-medium text-n-slate-12">
        {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_PRESETS.TITLE') }}
      </h4>
      <label for="whatsapp-preset-search" class="text-sm text-n-slate-12">
        {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_PRESETS.SEARCH') }}
      </label>
      <input
        id="whatsapp-preset-search"
        type="search"
        :value="presetSearch"
        class="mb-0 rounded-lg border border-n-weak bg-n-surface-1 text-sm"
        @input="$emit('searchPresets', $event.target.value)"
      />
      <p v-if="presetsLoading" class="mb-0 text-xs text-n-slate-11">
        {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_PRESETS.LOADING') }}
      </p>
      <div v-else class="flex max-h-40 flex-col gap-1 overflow-y-auto">
        <button
          v-for="preset in presets"
          :key="preset.id"
          type="button"
          class="flex items-center justify-between gap-2 rounded-md px-2 py-2 text-left hover:bg-n-alpha-2"
          :class="{ 'bg-n-alpha-2': selectedPreset?.id === preset.id }"
          :data-testid="`whatsapp-preset-${preset.id}`"
          @click="$emit('selectPreset', preset)"
        >
          <span class="min-w-0">
            <span class="block truncate text-sm font-medium text-n-slate-12">
              {{ preset.name }}
            </span>
            <span class="block text-xs text-n-slate-11">
              <template v-if="preset.interactive_type === 'button'">
                {{
                  $t('CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.TYPES.button')
                }}
              </template>
              <template v-else-if="preset.interactive_type === 'list'">
                {{
                  $t('CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.TYPES.list')
                }}
              </template>
              <template v-else-if="preset.interactive_type === 'carousel'">
                {{
                  $t(
                    'CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.TYPES.carousel'
                  )
                }}
              </template>
              <template v-else>
                {{
                  $t('CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.TYPES.cta_url')
                }}
              </template>
              {{
                $t('CONVERSATION.REPLYBOX.WHATSAPP_PRESETS.CREATOR', {
                  creator: preset.creator.name,
                })
              }}
            </span>
          </span>
        </button>
        <p v-if="!presets.length" class="mb-0 text-xs text-n-slate-11">
          {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_PRESETS.EMPTY') }}
        </p>
      </div>
      <label for="whatsapp-preset-name" class="text-sm text-n-slate-12">
        {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_PRESETS.NAME') }}
      </label>
      <input
        id="whatsapp-preset-name"
        type="text"
        :value="presetName"
        class="mb-0 rounded-lg border border-n-weak bg-n-surface-1 text-sm"
        @input="$emit('update:presetName', $event.target.value)"
      />
      <div class="flex flex-wrap gap-2">
        <Button
          :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_PRESETS.SAVE_NEW')"
          :disabled="presetBusy || !structurallyValid || !presetName.trim()"
          slate
          faded
          sm
          @click="$emit('savePreset')"
        />
        <Button
          v-if="selectedPreset?.permissions.update"
          :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_PRESETS.UPDATE')"
          :disabled="presetBusy || !structurallyValid || !presetName.trim()"
          slate
          faded
          sm
          @click="$emit('updatePreset')"
        />
        <Button
          v-if="selectedPreset?.permissions.delete"
          :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_PRESETS.DELETE')"
          :disabled="presetBusy"
          ruby
          ghost
          sm
          @click="$emit('deletePreset')"
        />
      </div>
    </section>

    <fieldset class="flex flex-col gap-2">
      <legend class="text-sm text-n-slate-12">
        {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.TYPE') }}
      </legend>
      <label
        v-for="capability in supportedTypes"
        :key="capability.type"
        class="flex items-start gap-2 rounded-lg border border-n-weak p-3"
      >
        <input
          type="radio"
          name="whatsapp-interactive-type"
          :value="capability.type"
          :checked="type === capability.type"
          :disabled="!capability.available"
          @change="$emit('selectType', capability.type)"
        />
        <span class="flex flex-col gap-1">
          <span class="text-sm font-medium text-n-slate-12">
            <template v-if="capability.type === 'button'">
              {{
                $t('CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.TYPES.button')
              }}
            </template>
            <template v-else-if="capability.type === 'cta_url'">
              {{
                $t('CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.TYPES.cta_url')
              }}
            </template>
            <template v-else-if="capability.type === 'carousel'">
              {{
                $t('CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.TYPES.carousel')
              }}
            </template>
            <template v-else>
              {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.TYPES.list') }}
            </template>
          </span>
          <span
            v-if="!capability.available"
            class="text-xs text-n-ruby-9"
            :data-testid="`whatsapp-unavailable-${capability.type}`"
          >
            <template
              v-if="
                capability.unavailable_reason ===
                'test_recipient_not_allowlisted'
              "
            >
              {{
                $t(
                  'CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.UNAVAILABLE.test_recipient_not_allowlisted'
                )
              }}
            </template>
            <template
              v-else-if="
                capability.unavailable_reason === 'service_window_closed'
              "
            >
              {{
                $t(
                  'CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.UNAVAILABLE.service_window_closed'
                )
              }}
            </template>
            <template
              v-else-if="
                capability.unavailable_reason === 'temporarily_disabled'
              "
            >
              {{
                $t(
                  'CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.UNAVAILABLE.temporarily_disabled'
                )
              }}
            </template>
            <template v-else>
              {{
                $t(
                  'CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.UNAVAILABLE.generic'
                )
              }}
            </template>
          </span>
        </span>
      </label>
    </fieldset>

    <template v-if="type === 'button' || type === 'cta_url'">
      <label for="whatsapp-interactive-header" class="text-sm text-n-slate-12">
        {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.HEADER') }}
      </label>
      <select
        id="whatsapp-interactive-header"
        :value="modelValue.headerType || ''"
        class="rounded-lg border border-n-weak bg-n-surface-1 text-sm mb-0"
        @change="updateHeaderType($event.target.value)"
      >
        <option value="">
          {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.HEADER_NONE') }}
        </option>
        <option v-if="limits.headerTypes?.includes('text')" value="text">
          {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.HEADER_TEXT') }}
        </option>
        <option v-if="limits.headerTypes?.includes('image')" value="image">
          {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.HEADER_IMAGE') }}
        </option>
        <option v-if="limits.headerTypes?.includes('video')" value="video">
          {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.HEADER_VIDEO') }}
        </option>
        <option
          v-if="limits.headerTypes?.includes('document')"
          value="document"
        >
          {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.HEADER_DOCUMENT') }}
        </option>
      </select>
      <Input
        v-if="modelValue.headerType === 'text'"
        id="whatsapp-interactive-header-text"
        :model-value="modelValue.headerText"
        :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.HEADER_TEXT')"
        :maxlength="limits.headerMaxLength"
        :message="`${modelValue.headerText?.length || 0}/${limits.headerMaxLength}`"
        @update:model-value="update('headerText', $event)"
      />
      <div v-if="mediaHeader" class="flex flex-col gap-2">
        <label
          for="whatsapp-interactive-upload"
          class="text-sm text-n-slate-12"
        >
          {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.UPLOAD') }}
        </label>
        <input
          id="whatsapp-interactive-upload"
          :key="modelValue.headerType"
          type="file"
          :accept="
            modelValue.headerType === 'document'
              ? undefined
              : `${modelValue.headerType}/*`
          "
          class="text-sm text-n-slate-11"
          @change="upload"
        />
        <p v-if="modelValue.media" class="mb-0 text-xs text-n-slate-11">
          {{ modelValue.media.name }}
        </p>
        <Button
          v-if="modelValue.media"
          class="self-start"
          icon="i-ph-trash"
          :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.REMOVE_UPLOAD')"
          slate
          ghost
          xs
          @click="removeMedia"
        />
      </div>
    </template>

    <TextArea
      id="whatsapp-interactive-body"
      :model-value="modelValue.body"
      :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.BODY')"
      :placeholder="
        $t('CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.BODY_PLACEHOLDER')
      "
      :max-length="limits.bodyMaxLength"
      :show-character-count="type !== 'list'"
      :message="
        type === 'list'
          ? `${normalizedLength(modelValue.body)}/${limits.bodyMaxLength}`
          : ''
      "
      auto-height
      autofocus
      @update:model-value="update('body', $event)"
    />

    <Input
      v-if="type === 'list'"
      id="whatsapp-interactive-list-header"
      :model-value="modelValue.header || ''"
      :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_LIST.HEADER')"
      :message="`${normalizedLength(modelValue.header)}/${limits.headerMaxLength}`"
      @update:model-value="update('header', $event)"
    />
    <Input
      v-if="type !== 'carousel'"
      id="whatsapp-interactive-footer"
      :model-value="modelValue.footer || ''"
      :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.FOOTER')"
      :maxlength="type === 'list' ? undefined : limits.footerMaxLength"
      :message="`${
        type === 'list'
          ? normalizedLength(modelValue.footer)
          : modelValue.footer?.length || 0
      }/${limits.footerMaxLength}`"
      @update:model-value="update('footer', $event)"
    />

    <template v-if="type === 'button'">
      <div class="flex flex-col gap-2">
        <Input
          v-for="(button, index) in modelValue.buttons"
          :id="`whatsapp-interactive-button-${index}`"
          :key="index"
          :model-value="typeof button === 'string' ? button : button.title"
          :label="
            $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.BUTTON_LABEL', {
              number: index + 1,
            })
          "
          :placeholder="
            $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.BUTTON_PLACEHOLDER')
          "
          :maxlength="limits.buttonTitleMaxLength"
          :message="`${
            (typeof button === 'string' ? button : button.title).length
          }/${limits.buttonTitleMaxLength}`"
          @update:model-value="updateButton(index, $event)"
        >
          <template
            v-if="modelValue.buttons.length > limits.buttonMinCount"
            #prefix
          >
            <Button
              class="absolute z-10 ltr:right-1 rtl:left-1 top-7"
              icon="i-ph-trash"
              slate
              ghost
              xs
              :aria-label="
                $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.REMOVE_BUTTON', {
                  number: index + 1,
                })
              "
              @click="removeButton(index)"
            />
          </template>
        </Input>
      </div>
      <p v-if="duplicateTitles" role="alert" class="mb-0 text-xs text-n-ruby-9">
        {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.DUPLICATE_LABELS') }}
      </p>
      <Button
        v-if="modelValue.buttons.length < limits.buttonMaxCount"
        class="self-start"
        icon="i-ph-plus"
        :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.ADD_BUTTON')"
        slate
        faded
        sm
        @click="addButton"
      />
    </template>

    <template v-else-if="type === 'cta_url'">
      <Input
        id="whatsapp-interactive-cta-button"
        :model-value="modelValue.button"
        :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_CTA.BUTTON')"
        :maxlength="limits.buttonMaxLength"
        :message="`${normalizedLength(modelValue.button)}/${limits.buttonMaxLength}`"
        :message-type="
          normalizedLength(modelValue.button) > limits.buttonMaxLength
            ? 'error'
            : 'info'
        "
        @update:model-value="update('button', $event)"
      />
      <Input
        id="whatsapp-interactive-cta-url"
        type="url"
        :model-value="modelValue.url"
        :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_CTA.URL')"
        :placeholder="$t('CONVERSATION.REPLYBOX.WHATSAPP_CTA.URL_PLACEHOLDER')"
        :message="
          modelValue.url && !isValidUrl
            ? $t('CONVERSATION.REPLYBOX.WHATSAPP_CTA.INVALID_URL')
            : $t('CONVERSATION.REPLYBOX.WHATSAPP_CTA.URL_HELP')
        "
        :message-type="modelValue.url && !isValidUrl ? 'error' : 'info'"
        @update:model-value="update('url', $event)"
      />
    </template>

    <template v-else-if="type === 'carousel'">
      <fieldset class="flex flex-col gap-2">
        <legend class="text-sm text-n-slate-12">
          {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.ACTION_MODE') }}
        </legend>
        <label
          v-for="mode in limits.actionModes"
          :key="mode"
          class="flex items-center gap-2 text-sm text-n-slate-12"
        >
          <input
            type="radio"
            name="whatsapp-carousel-action-mode"
            :value="mode"
            :checked="modelValue.actionMode === mode"
            @change="updateCarouselMode(mode)"
          />
          <template v-if="mode === 'url'">
            {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.MODES.url') }}
          </template>
          <template v-else>
            {{
              $t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.MODES.quick_reply')
            }}
          </template>
        </label>
      </fieldset>

      <article
        v-for="(card, cardIndex) in modelValue.cards"
        :key="card.clientKey"
        class="flex flex-col gap-3 rounded-lg border border-n-weak p-3"
        :data-testid="`whatsapp-carousel-card-${cardIndex}`"
      >
        <div class="flex items-center justify-between gap-2">
          <h4 class="mb-0 text-sm font-medium text-n-slate-12">
            {{
              $t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.CARD', {
                number: cardIndex + 1,
              })
            }}
          </h4>
          <div class="flex gap-1">
            <Button
              v-if="cardIndex > 0"
              icon="i-ph-arrow-up"
              slate
              ghost
              xs
              :aria-label="
                $t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.MOVE_CARD_UP')
              "
              @click="moveCard(cardIndex, -1)"
            />
            <Button
              v-if="cardIndex < modelValue.cards.length - 1"
              icon="i-ph-arrow-down"
              slate
              ghost
              xs
              :aria-label="
                $t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.MOVE_CARD_DOWN')
              "
              @click="moveCard(cardIndex, 1)"
            />
            <Button
              v-if="modelValue.cards.length > limits.cardMinCount"
              icon="i-ph-trash"
              slate
              ghost
              xs
              :aria-label="
                $t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.REMOVE_CARD')
              "
              @click="removeCard(cardIndex)"
            />
          </div>
        </div>
        <label
          :for="`whatsapp-carousel-image-${cardIndex}`"
          class="text-sm text-n-slate-12"
        >
          {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.IMAGE') }}
        </label>
        <input
          :id="`whatsapp-carousel-image-${cardIndex}`"
          type="file"
          accept="image/*"
          class="text-sm text-n-slate-11"
          @change="uploadCard($event, card)"
        />
        <div v-if="card.media" class="flex items-center justify-between gap-2">
          <span class="text-xs text-n-slate-11">{{ card.media.name }}</span>
          <Button
            icon="i-ph-trash"
            slate
            ghost
            xs
            :aria-label="
              $t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.REMOVE_IMAGE')
            "
            @click="removeCardMedia(cardIndex)"
          />
        </div>
        <TextArea
          :id="`whatsapp-carousel-body-${cardIndex}`"
          :model-value="card.body"
          :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.CARD_BODY')"
          :max-length="limits.cardBodyMaxLength"
          show-character-count
          :message="
            lineBreakCount(card.body) > limits.cardBodyMaxLineBreaks
              ? $t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.TOO_MANY_LINES')
              : ''
          "
          :message-type="
            lineBreakCount(card.body) > limits.cardBodyMaxLineBreaks
              ? 'error'
              : 'info'
          "
          auto-height
          @update:model-value="updateCard(cardIndex, 'body', $event)"
        />
        <template v-if="modelValue.actionMode === 'url'">
          <Input
            :id="`whatsapp-carousel-button-${cardIndex}`"
            :model-value="card.action.button"
            :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.URL_LABEL')"
            :maxlength="limits.buttonMaxLength"
            :message="`${normalizedLength(card.action.button)}/${limits.buttonMaxLength}`"
            @update:model-value="updateCardAction(cardIndex, 'button', $event)"
          />
          <Input
            :id="`whatsapp-carousel-url-${cardIndex}`"
            type="url"
            :model-value="card.action.url"
            :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.URL')"
            :message="
              card.action.url &&
              !isValidHttpUrl(card.action.url.trim(), limits.urlSchemes)
                ? $t('CONVERSATION.REPLYBOX.WHATSAPP_CTA.INVALID_URL')
                : $t('CONVERSATION.REPLYBOX.WHATSAPP_CTA.URL_HELP')
            "
            :message-type="
              card.action.url &&
              !isValidHttpUrl(card.action.url.trim(), limits.urlSchemes)
                ? 'error'
                : 'info'
            "
            @update:model-value="updateCardAction(cardIndex, 'url', $event)"
          />
        </template>
        <template v-else>
          <div
            v-for="(reply, replyIndex) in card.action.buttons"
            :key="reply.clientKey || reply.preset_option_id || replyIndex"
            class="flex items-end gap-1"
          >
            <Input
              :id="`whatsapp-carousel-reply-${cardIndex}-${replyIndex}`"
              class="flex-1"
              :model-value="reply.title"
              :label="
                $t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.REPLY', {
                  number: replyIndex + 1,
                })
              "
              :maxlength="limits.buttonMaxLength"
              :message="`${normalizedLength(reply.title)}/${limits.buttonMaxLength}`"
              @update:model-value="updateReply(cardIndex, replyIndex, $event)"
            />
            <Button
              v-if="replyIndex > 0"
              icon="i-ph-arrow-up"
              slate
              ghost
              xs
              :aria-label="
                $t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.MOVE_REPLY_UP')
              "
              @click="moveReply(cardIndex, replyIndex, -1)"
            />
            <Button
              v-if="replyIndex < card.action.buttons.length - 1"
              icon="i-ph-arrow-down"
              slate
              ghost
              xs
              :aria-label="
                $t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.MOVE_REPLY_DOWN')
              "
              @click="moveReply(cardIndex, replyIndex, 1)"
            />
            <Button
              v-if="card.action.buttons.length > 1"
              icon="i-ph-trash"
              slate
              ghost
              xs
              :aria-label="
                $t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.REMOVE_REPLY')
              "
              @click="removeReply(cardIndex, replyIndex)"
            />
          </div>
          <Button
            class="self-start"
            icon="i-ph-plus"
            :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.ADD_REPLY')"
            slate
            faded
            sm
            @click="addReply(cardIndex)"
          />
          <p
            v-if="hasDuplicateReplies(card)"
            role="alert"
            class="mb-0 text-xs text-n-ruby-9"
          >
            {{
              $t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.DUPLICATE_REPLIES')
            }}
          </p>
        </template>
      </article>
      <p
        v-if="carouselReplyCountMismatch"
        role="alert"
        class="mb-0 text-xs text-n-ruby-9"
      >
        {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.REPLY_COUNT_MISMATCH') }}
      </p>
      <Button
        v-if="modelValue.cards.length < limits.cardMaxCount"
        class="self-start"
        icon="i-ph-plus"
        :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_CAROUSEL.ADD_CARD')"
        slate
        faded
        sm
        @click="addCard"
      />
    </template>

    <template v-else-if="type === 'list'">
      <Input
        id="whatsapp-interactive-list-button"
        :model-value="modelValue.button"
        :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_LIST.BUTTON')"
        :message="`${normalizedLength(modelValue.button)}/${limits.buttonMaxLength}`"
        @update:model-value="update('button', $event)"
      />
      <div
        v-for="(section, sectionIndex) in modelValue.sections"
        :key="section.clientKey || sectionIndex"
        class="flex flex-col gap-3 rounded-lg border border-n-weak p-3"
        :data-testid="`whatsapp-list-section-${sectionIndex}`"
      >
        <div class="flex items-center justify-between gap-2">
          <h4 class="mb-0 text-sm font-medium text-n-slate-12">
            {{
              $t('CONVERSATION.REPLYBOX.WHATSAPP_LIST.SECTION', {
                number: sectionIndex + 1,
              })
            }}
          </h4>
          <Button
            v-if="modelValue.sections.length > limits.sectionMinCount"
            icon="i-ph-trash"
            slate
            ghost
            xs
            :aria-label="
              $t('CONVERSATION.REPLYBOX.WHATSAPP_LIST.REMOVE_SECTION', {
                number: sectionIndex + 1,
              })
            "
            @click="removeSection(sectionIndex)"
          />
        </div>
        <Input
          :id="`whatsapp-list-section-title-${sectionIndex}`"
          :model-value="section.title"
          :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_LIST.SECTION_TITLE')"
          :message="`${normalizedLength(section.title)}/${limits.sectionTitleMaxLength}`"
          @update:model-value="updateSection(sectionIndex, 'title', $event)"
        />
        <div
          v-for="(row, rowIndex) in section.rows"
          :key="row.clientKey || row.preset_option_id || rowIndex"
          class="flex flex-col gap-2 rounded-lg bg-n-alpha-1 p-3"
        >
          <div class="flex items-center justify-between gap-2">
            <span class="text-sm text-n-slate-12">{{
              $t('CONVERSATION.REPLYBOX.WHATSAPP_LIST.ROW', {
                number: rowIndex + 1,
              })
            }}</span>
            <Button
              v-if="section.rows.length > 1"
              icon="i-ph-trash"
              slate
              ghost
              xs
              :aria-label="
                $t('CONVERSATION.REPLYBOX.WHATSAPP_LIST.REMOVE_ROW', {
                  number: rowIndex + 1,
                })
              "
              @click="removeRow(sectionIndex, rowIndex)"
            />
          </div>
          <Input
            :id="`whatsapp-list-row-title-${sectionIndex}-${rowIndex}`"
            :model-value="row.title"
            :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_LIST.ROW_TITLE')"
            :message="`${normalizedLength(row.title)}/${limits.rowTitleMaxLength}`"
            @update:model-value="
              updateRow(sectionIndex, rowIndex, 'title', $event)
            "
          />
          <Input
            :id="`whatsapp-list-row-description-${sectionIndex}-${rowIndex}`"
            :model-value="row.description"
            :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_LIST.ROW_DESCRIPTION')"
            :message="`${normalizedLength(row.description)}/${limits.rowDescriptionMaxLength}`"
            @update:model-value="
              updateRow(sectionIndex, rowIndex, 'description', $event)
            "
          />
        </div>
        <Button
          v-if="totalRows < limits.rowMaxCount"
          class="self-start"
          icon="i-ph-plus"
          :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_LIST.ADD_ROW')"
          slate
          faded
          sm
          @click="addRow(sectionIndex)"
        />
      </div>
      <Button
        v-if="
          modelValue.sections.length < limits.sectionMaxCount &&
          totalRows < limits.rowMaxCount
        "
        class="self-start"
        icon="i-ph-plus"
        :label="$t('CONVERSATION.REPLYBOX.WHATSAPP_LIST.ADD_SECTION')"
        slate
        faded
        sm
        @click="addSection"
      />
      <p class="mb-0 text-xs text-n-slate-11">
        {{
          $t('CONVERSATION.REPLYBOX.WHATSAPP_LIST.ROW_COUNT', {
            count: totalRows,
            maximum: limits.rowMaxCount,
          })
        }}
      </p>
    </template>

    <p class="mb-0 text-xs text-n-slate-11">
      {{ $t('CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.PREVIEW') }}
    </p>
    <WhatsAppInteractivePreview
      class="rounded-lg border border-n-weak p-3"
      :type="type"
      :body="modelValue.body"
      :header="
        (type === 'button' || type === 'cta_url') && modelValue.headerType
          ? { type: modelValue.headerType, text: modelValue.headerText }
          : type === 'list' && modelValue.header
            ? { type: 'text', text: modelValue.header }
            : null
      "
      :attachment="modelValue.media"
      :footer="modelValue.footer"
      :buttons="
        modelValue.buttons?.map(button => ({
          title: typeof button === 'string' ? button : button.title,
        }))
      "
      :opener="modelValue.button"
      :url="modelValue.url"
      :sections="modelValue.sections"
      :cards="modelValue.cards"
      :action-mode="modelValue.actionMode"
    />
  </section>
</template>
