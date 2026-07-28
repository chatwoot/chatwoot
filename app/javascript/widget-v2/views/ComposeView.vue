<script setup>
import { computed, reactive, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useConfigStore } from 'widget-v2/stores/config';
import { useConversationsStore } from 'widget-v2/stores/conversations';
import WidgetHeader from 'widget-v2/components/WidgetHeader.vue';
import PreChatFields from 'widget-v2/components/PreChatFields.vue';
import BaseButton from 'widget-v2/components/base/BaseButton.vue';
import AiAvatar from 'widget-v2/components/AiAvatar.vue';

const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const configStore = useConfigStore();
const conversationsStore = useConversationsStore();

const isValidEmail = value => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);

const section = computed(() => (route.meta.section === 'ai' ? 'ai' : 'human'));
const isAi = computed(() => section.value === 'ai');

const message = ref('');
const submitting = ref(false);
const values = reactive({});
const errors = reactive({});

const preChatOptions = computed(
  () => configStore.channel.pre_chat_form_options || {}
);

// The pre-chat form gates human conversations only; AI chats skip it.
const preChatFields = computed(() => {
  if (isAi.value || !configStore.channel.pre_chat_form_enabled) return [];
  return (preChatOptions.value.pre_chat_fields || []).filter(
    field => field.enabled
  );
});

const headerTitle = computed(() =>
  isAi.value
    ? configStore.aiAgent?.name || t('AI_STATE.AI_DEFAULT_NAME')
    : t('HOME.START_CONVERSATION')
);

const validate = () => {
  Object.keys(errors).forEach(key => delete errors[key]);
  preChatFields.value.forEach(field => {
    const value = values[field.name];
    const isEmpty =
      field.type === 'checkbox' ? !value : !String(value || '').trim();
    if (field.required && isEmpty) {
      errors[field.name] = t('PRE_CHAT.FIELD_REQUIRED');
    } else if (field.type === 'email' && value && !isValidEmail(value)) {
      errors[field.name] = t('PRE_CHAT.EMAIL_INVALID');
    }
  });
  return Object.keys(errors).length === 0;
};

// Standard fields map onto contact columns; the rest are custom attributes,
// split by whether they belong to the contact or the conversation.
const buildPayload = () => {
  const contact = {};
  const contactCustomAttributes = {};
  const conversationCustomAttributes = {};

  preChatFields.value.forEach(field => {
    const value = values[field.name];
    if (value === undefined || value === '') return;

    if (field.name === 'emailAddress') contact.email = value;
    else if (field.name === 'fullName') contact.name = value;
    else if (field.name === 'phoneNumber') contact.phone_number = value;
    else if (field.field_type === 'conversation_attribute') {
      conversationCustomAttributes[field.name] = value;
    } else {
      contactCustomAttributes[field.name] = value;
    }
  });

  if (Object.keys(contactCustomAttributes).length) {
    contact.custom_attributes = contactCustomAttributes;
  }
  return { contact, conversationCustomAttributes };
};

const submit = async () => {
  if (!message.value.trim() || submitting.value) return;
  if (!validate()) return;

  submitting.value = true;
  try {
    const { contact, conversationCustomAttributes } = buildPayload();
    const conversation = await conversationsStore.create({
      section: section.value,
      content: message.value.trim(),
      contact: Object.keys(contact).length ? contact : undefined,
      customAttributes: conversationCustomAttributes,
    });
    router.replace({
      name: 'conversation-detail',
      params: { id: conversation.id },
    });
  } finally {
    submitting.value = false;
  }
};
</script>

<template>
  <div class="flex flex-col h-full bg-cw-solid">
    <WidgetHeader :title="headerTitle" show-back />

    <div class="flex-1 overflow-y-auto scrollbar-thin px-5 py-5">
      <div v-if="isAi" class="flex flex-col items-center text-center mb-6">
        <AiAvatar :size="48" />
        <p class="mt-3 text-sm text-cw-text-muted max-w-64">
          {{
            configStore.aiAgent?.welcome_message || $t('AI.WELCOME_FALLBACK')
          }}
        </p>
      </div>

      <p
        v-else-if="preChatOptions.pre_chat_message && preChatFields.length"
        class="mb-5 text-sm leading-relaxed text-cw-text-muted"
      >
        {{ preChatOptions.pre_chat_message }}
      </p>

      <form class="flex flex-col gap-4" @submit.prevent="submit">
        <PreChatFields
          v-if="preChatFields.length"
          v-model="values"
          :fields="preChatFields"
          :errors="errors"
        />

        <label class="block">
          <span class="block mb-1.5 text-xs font-medium text-cw-text-muted">
            {{ $t('PRE_CHAT.MESSAGE_LABEL') }}
          </span>
          <textarea
            v-model="message"
            rows="4"
            :placeholder="
              isAi ? $t('AI.NEW_CHAT') : $t('PRE_CHAT.MESSAGE_PLACEHOLDER')
            "
            class="w-full px-3 py-2.5 text-base rounded-token-sm bg-cw-solid text-cw-text placeholder:text-cw-text-faint border border-cw-border outline-none resize-none transition-shadow focus-visible:ring-[3px] focus-visible:ring-cw-ring"
          />
        </label>

        <BaseButton
          size="lg"
          :disabled="!message.trim() || submitting"
          @click="submit"
        >
          <span v-if="isAi" class="i-ph-sparkle" />
          {{ isAi ? $t('AI.NEW_CHAT') : $t('PRE_CHAT.START') }}
        </BaseButton>
      </form>
    </div>
  </div>
</template>
