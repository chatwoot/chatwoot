<script setup>
import { computed, ref } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import ConversationApi from 'dashboard/api/conversations';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const props = defineProps({
  conversation: { type: Object, required: true },
  name: { type: String, required: true },
});

const store = useStore();
const { t } = useI18n();
const isSaving = ref(false);
const enabled = computed(
  () =>
    props.conversation.additional_attributes?.user_identifier_enabled !== false
);

const toggleIdentifier = async () => {
  if (isSaving.value) return;
  isSaving.value = true;
  try {
    const { data } = await ConversationApi.update(props.conversation.id, {
      user_identifier_enabled: !enabled.value,
    });
    await store.dispatch('updateConversation', data);
  } catch {
    useAlert(t('CONVERSATION.USER_IDENTIFIER.ERROR'));
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <div class="flex items-center gap-3 px-4 pt-3">
    <strong
      class="min-w-0 flex-1 truncate text-sm font-bold text-n-slate-12"
      :class="{ invisible: !enabled }"
      :aria-hidden="!enabled"
    >
      {{ name }}
    </strong>
    <div
      v-tooltip="$t('CONVERSATION.USER_IDENTIFIER.HELP')"
      class="ms-auto flex shrink-0 items-center gap-2"
    >
      <span class="text-sm text-n-slate-11">
        {{ $t('CONVERSATION.USER_IDENTIFIER.LABEL') }}
      </span>
      <Switch
        :model-value="enabled"
        :aria-label="$t('CONVERSATION.USER_IDENTIFIER.HELP')"
        :aria-busy="isSaving"
        :disabled="isSaving"
        @update:model-value="toggleIdentifier"
      />
    </div>
  </div>
</template>
