<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ConversationCard from 'dashboard/components-next/Conversation/ConversationCard/ConversationCard.vue';

const { t } = useI18n();
const route = useRoute();

const conversations = useMapGetter(
  'contactConversations/getAllConversationsByContactId'
);

const uiFlags = useMapGetter('contactConversations/getUIFlags');
const isFetching = computed(() => uiFlags.value.isFetching);

const contactConversations = computed(() =>
  conversations.value(route.params.contactId)
);
</script>

<template>
  <div
    v-if="isFetching"
    class="flex items-center justify-center py-10 text-n-slate-11"
  >
    <Spinner />
  </div>
  <div
    v-else-if="contactConversations.length > 0"
    class="px-6 pt-4 pb-6 divide-y divide-n-weak"
  >
    <ConversationCard
      v-for="conversation in contactConversations"
      :key="conversation.id"
      :chat="useSnakeCase(conversation, { deep: true })"
      enable-context-menu
      compact
      show-assignee
      :allowed-context-menu-options="['open-new-tab', 'copy-link']"
      :enable-selection="false"
    />
  </div>
  <p v-else class="px-6 py-10 text-sm leading-6 text-center text-n-slate-11">
    {{ t('CONTACTS_LAYOUT.SIDEBAR.HISTORY.EMPTY_STATE') }}
  </p>
</template>
