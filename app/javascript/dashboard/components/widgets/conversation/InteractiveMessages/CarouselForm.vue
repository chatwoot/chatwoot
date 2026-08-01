<script setup>
import { reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import HeaderImageInput from './HeaderImageInput.vue';

const props = defineProps({
  modelValue: {
    type: Object,
    required: true,
  },
});
const emit = defineEmits(['update:modelValue', 'update:headerImageValid']);
const BODY_TEXT_MAX_LENGTH = 1024;
const ACTION_TEXT_MAX_LENGTH = 20;
const MIN_CARDS = 2;
const MAX_CARDS = 10;

const { t } = useI18n();

// Tracks per-card media URL validity so the parent can gate Send until
// every card's image (if provided) actually loads.
const mediaValidity = reactive({});

const updateField = (field, value) => {
  emit('update:modelValue', { ...props.modelValue, [field]: value });
};

const updateCards = cards => updateField('cards', cards);

const updateCard = (index, card) => {
  updateCards(
    props.modelValue.cards.map((existing, cardIndex) =>
      cardIndex === index ? card : existing
    )
  );
};

// Card ids double as the reply payload sent back on button click, so they
// must stay unique for the lifetime of the form. Deriving them from the
// current array length breaks that guarantee once a card is removed and a
// new one is added (the length-based id can collide with a surviving card).
let nextCardNumber =
  props.modelValue.cards.reduce((max, card) => {
    const match = /^card_(\d+)$/.exec(card.id);
    return match ? Math.max(max, Number(match[1])) : max;
  }, 0) + 1;

const addCard = () => {
  if (props.modelValue.cards.length >= MAX_CARDS) return;
  const cardId = `card_${nextCardNumber}`;
  nextCardNumber += 1;
  updateCards([
    ...props.modelValue.cards,
    {
      id: cardId,
      mediaUrl: '',
      title: '',
      description: '',
      actionType: 'reply',
      actionText: '',
      actionUrl: '',
    },
  ]);
};

const removeCard = index => {
  const removed = props.modelValue.cards[index];
  delete mediaValidity[removed.id];
  updateCards(props.modelValue.cards.filter((_, i) => i !== index));
};

const allMediaValid = computed(() =>
  Object.values(mediaValidity).every(Boolean)
);

watch(allMediaValid, value => emit('update:headerImageValid', value), {
  immediate: true,
});
</script>

<template>
  <div class="flex flex-col gap-4">
    <TextArea
      :model-value="modelValue.bodyText"
      :label="t('INTERACTIVE_MESSAGES.FIELDS.BODY_TEXT')"
      :placeholder="t('INTERACTIVE_MESSAGES.FIELDS.BODY_TEXT_PLACEHOLDER')"
      :max-length="BODY_TEXT_MAX_LENGTH"
      show-character-count
      auto-height
      @update:model-value="value => updateField('bodyText', value)"
    />

    <div class="flex flex-col gap-3">
      <div
        v-for="(card, index) in modelValue.cards"
        :key="card.id"
        class="flex flex-col gap-3 p-4 rounded-lg bg-n-alpha-1"
      >
        <div class="flex items-center justify-between">
          <p class="text-xs font-medium text-n-slate-11">
            {{ t('INTERACTIVE_MESSAGES.FIELDS.CARD_TITLE') }} {{ index + 1 }}
          </p>
          <Button
            v-if="modelValue.cards.length > MIN_CARDS"
            icon="i-lucide-trash"
            color="ruby"
            variant="faded"
            size="xs"
            :aria-label="t('INTERACTIVE_MESSAGES.BUTTONS.REMOVE_CARD')"
            @click="removeCard(index)"
          />
        </div>

        <HeaderImageInput
          :model-value="card.mediaUrl"
          :label="t('INTERACTIVE_MESSAGES.FIELDS.CARD_IMAGE_URL')"
          :placeholder="
            t('INTERACTIVE_MESSAGES.FIELDS.CARD_IMAGE_URL_PLACEHOLDER')
          "
          @update:model-value="
            value => updateCard(index, { ...card, mediaUrl: value })
          "
          @update:valid="value => (mediaValidity[card.id] = value)"
        />
        <Input
          :model-value="card.title"
          :label="t('INTERACTIVE_MESSAGES.FIELDS.CARD_TITLE')"
          :placeholder="t('INTERACTIVE_MESSAGES.FIELDS.CARD_TITLE_PLACEHOLDER')"
          @update:model-value="
            value => updateCard(index, { ...card, title: value })
          "
        />
        <TextArea
          :model-value="card.description"
          :label="t('INTERACTIVE_MESSAGES.FIELDS.CARD_DESCRIPTION')"
          :placeholder="
            t('INTERACTIVE_MESSAGES.FIELDS.CARD_DESCRIPTION_PLACEHOLDER')
          "
          auto-height
          @update:model-value="
            value => updateCard(index, { ...card, description: value })
          "
        />

        <div
          class="flex flex-col gap-2 p-3 border rounded-lg border-n-weak bg-n-solid-2"
        >
          <p class="text-xs font-medium text-n-slate-11">
            {{ t('INTERACTIVE_MESSAGES.FIELDS.CARD_ACTION') }}
          </p>
          <div class="flex gap-2">
            <Button
              :label="t('INTERACTIVE_MESSAGES.FIELDS.ACTION_TYPE_REPLY')"
              size="sm"
              :variant="card.actionType === 'reply' ? 'solid' : 'faded'"
              :color="card.actionType === 'reply' ? 'blue' : 'slate'"
              @click="updateCard(index, { ...card, actionType: 'reply' })"
            />
            <Button
              :label="t('INTERACTIVE_MESSAGES.FIELDS.ACTION_TYPE_URL')"
              size="sm"
              :variant="card.actionType === 'url' ? 'solid' : 'faded'"
              :color="card.actionType === 'url' ? 'blue' : 'slate'"
              @click="updateCard(index, { ...card, actionType: 'url' })"
            />
          </div>
          <Input
            :model-value="card.actionText"
            :label="t('INTERACTIVE_MESSAGES.FIELDS.BUTTON_TEXT')"
            :placeholder="
              t('INTERACTIVE_MESSAGES.FIELDS.BUTTON_TEXT_PLACEHOLDER')
            "
            :maxlength="ACTION_TEXT_MAX_LENGTH"
            @update:model-value="
              value => updateCard(index, { ...card, actionText: value })
            "
          />
          <Input
            v-if="card.actionType === 'url'"
            :model-value="card.actionUrl"
            :label="t('INTERACTIVE_MESSAGES.FIELDS.BUTTON_URL')"
            :placeholder="
              t('INTERACTIVE_MESSAGES.FIELDS.BUTTON_URL_PLACEHOLDER')
            "
            @update:model-value="
              value => updateCard(index, { ...card, actionUrl: value })
            "
          />
        </div>
      </div>

      <Button
        v-if="modelValue.cards.length < MAX_CARDS"
        icon="i-lucide-plus"
        color="slate"
        variant="faded"
        size="sm"
        class="self-start"
        :label="t('INTERACTIVE_MESSAGES.BUTTONS.ADD_CARD')"
        @click="addCard"
      />
      <p v-else class="text-xs text-n-slate-11">
        {{ t('INTERACTIVE_MESSAGES.BUTTONS.MAX_CARDS_REACHED') }}
      </p>
    </div>
  </div>
</template>
