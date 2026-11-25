<script setup>
import { computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore } from 'vuex';
import Whatsapp from './channels/Whatsapp.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { SESSION_PROVIDERS } from 'dashboard/helper/whatsappSession';

// Mirrors Settings.vue's `isConvertibleWhatsAppChannel` so a direct visit to
// /convert cannot bypass the provider allowlist exposed by the Convert button.
const CONVERTIBLE_WHATSAPP_PROVIDERS = [
  'whatsapp_cloud',
  'default',
  ...SESSION_PROVIDERS,
];

const route = useRoute();
const router = useRouter();
const store = useStore();

const inboxId = computed(() => Number(route.params.inboxId));
const inbox = computed(() => store.getters['inboxes/getInbox'](inboxId.value));

const redirectBackIfInvalid = () => {
  if (!inbox.value?.id) {
    // Inbox not found even after the store fetch: bounce to the inboxes list
    // rather than leaving the page blank waiting for a payload that is not
    // coming.
    router.replace({
      name: 'settings_inbox_list',
      params: { accountId: route.params.accountId },
    });
    return;
  }
  const isConvertible =
    inbox.value.channel_type === INBOX_TYPES.WHATSAPP &&
    CONVERTIBLE_WHATSAPP_PROVIDERS.includes(inbox.value.provider);
  if (!isConvertible) {
    router.replace({
      name: 'settings_inbox_show',
      params: {
        accountId: route.params.accountId,
        inboxId: inboxId.value,
      },
    });
  }
};

onMounted(async () => {
  if (!inbox.value?.id) {
    await store.dispatch('inboxes/get');
  }
  redirectBackIfInvalid();
});
</script>

<template>
  <div class="mx-auto flex flex-col gap-6 mb-8 max-w-7xl w-full !px-6">
    <div
      class="grid grid-cols-6 rounded-xl border border-n-weak h-full min-h-[50dvh]"
    >
      <Whatsapp v-if="inbox?.id" mode="convert" :inbox="inbox" />
    </div>
  </div>
</template>
