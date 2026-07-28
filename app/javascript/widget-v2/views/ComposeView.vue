<script setup>
import { computed, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useConfigStore } from 'widget-v2/stores/config';
import { useConversationsStore } from 'widget-v2/stores/conversations';
import WidgetHeader from 'widget-v2/components/WidgetHeader.vue';
import BaseInput from 'widget-v2/components/base/BaseInput.vue';
import BaseButton from 'widget-v2/components/base/BaseButton.vue';
import BaseAvatar from 'widget-v2/components/base/BaseAvatar.vue';

const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const configStore = useConfigStore();
const conversationsStore = useConversationsStore();

const isValidEmail = value => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);

const section = computed(() => (route.meta.section === 'ai' ? 'ai' : 'human'));
const isAi = computed(() => section.value === 'ai');

const name = ref('');
const email = ref('');
const message = ref('');
const emailError = ref('');
const submitting = ref(false);

// Pre-chat fields apply to human conversations for still-anonymous contacts.
const showContactFields = computed(
  () =>
    !isAi.value &&
    configStore.channel.pre_chat_form_enabled &&
    !configStore.contact.email
);

const headerTitle = computed(() =>
  isAi.value
    ? configStore.aiAgent?.name || t('AI_STATE.AI_DEFAULT_NAME')
    : t('HOME.START_CONVERSATION')
);

const submit = async () => {
  if (!message.value.trim() || submitting.value) return;
  emailError.value = '';
  if (showContactFields.value && email.value && !isValidEmail(email.value)) {
    emailError.value = t('PRE_CHAT.EMAIL_INVALID');
    return;
  }

  submitting.value = true;
  try {
    const conversation = await conversationsStore.create({
      section: section.value,
      content: message.value.trim(),
      contact: showContactFields.value
        ? { name: name.value || undefined, email: email.value || undefined }
        : undefined,
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
        <BaseAvatar
          :src="configStore.aiAgent?.avatar_url"
          :name="configStore.aiAgent?.name || 'AI'"
          :size="48"
        />
        <p class="mt-3 text-sm text-cw-text-muted max-w-64">
          {{
            configStore.aiAgent?.welcome_message || $t('AI.WELCOME_FALLBACK')
          }}
        </p>
      </div>

      <form class="flex flex-col gap-4" @submit.prevent="submit">
        <template v-if="showContactFields">
          <BaseInput
            v-model="name"
            :label="$t('PRE_CHAT.NAME_LABEL')"
            :placeholder="$t('PRE_CHAT.NAME_PLACEHOLDER')"
          />
          <BaseInput
            v-model="email"
            type="email"
            :label="$t('PRE_CHAT.EMAIL_LABEL')"
            :placeholder="$t('PRE_CHAT.EMAIL_PLACEHOLDER')"
            :error="emailError"
          />
        </template>

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
            class="w-full px-3 py-2.5 text-base rounded-token-sm bg-cw-solid text-cw-text placeholder:text-cw-text-faint border border-cw-border outline-none resize-none transition-shadow focus-visible:ring-[3px] focus-visible:ring-cw-ring focus-visible:border-transparent"
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
