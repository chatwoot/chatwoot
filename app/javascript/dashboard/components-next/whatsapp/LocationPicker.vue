<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import WhatsappLocationsAPI from 'dashboard/api/whatsappLocations';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  conversationId: { type: Number, required: true },
  locations: { type: Array, default: () => [] },
});

const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const isSending = ref(false);
// Identifies the capture in progress; any newer value makes older ones stale.
let operationId = 0;

const hasLocations = computed(() => props.locations.length > 0);

const send = async (conversationId, payload) => {
  isSending.value = true;
  try {
    const { data } = await WhatsappLocationsAPI.sendMessage(
      conversationId,
      payload
    );
    store.dispatch('addMessage', data);
    dialogRef.value.close();
  } catch (error) {
    useAlert(
      error?.response?.data?.error ||
        t('WHATSAPP_LOCATIONS.SELECTOR.SEND_ERROR')
    );
  } finally {
    isSending.value = false;
  }
};

const sendCurrentLocation = () => {
  if (!navigator.geolocation) {
    useAlert(t('WHATSAPP_LOCATIONS.SELECTOR.UNSUPPORTED'));
    return;
  }
  isSending.value = true;
  operationId += 1;
  const currentOperation = operationId;
  const { conversationId } = props;
  navigator.geolocation.getCurrentPosition(
    ({ coords }) => {
      if (currentOperation !== operationId) return;
      send(conversationId, {
        latitude: coords.latitude,
        longitude: coords.longitude,
      });
    },
    () => {
      if (currentOperation !== operationId) return;
      isSending.value = false;
      useAlert(t('WHATSAPP_LOCATIONS.SELECTOR.PERMISSION_DENIED'));
    }
  );
};

const cancelPendingLocation = () => {
  operationId += 1;
  isSending.value = false;
};

watch(() => props.conversationId, cancelPendingLocation);

defineExpose({ open: () => dialogRef.value.open() });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('WHATSAPP_LOCATIONS.SELECTOR.TITLE')"
    :show-confirm-button="false"
    @close="cancelPendingLocation"
  >
    <ul class="flex flex-col gap-1 m-0 list-none max-h-80 overflow-y-auto">
      <li>
        <button
          type="button"
          class="flex gap-3 items-center px-3 py-2 w-full rounded-lg text-start hover:bg-n-alpha-2 disabled:opacity-50"
          :disabled="isSending"
          @click="sendCurrentLocation"
        >
          <Icon icon="i-lucide-locate-fixed" class="size-5 text-n-blue-text" />
          <span class="flex flex-col min-w-0">
            <span class="text-sm font-medium text-n-slate-12">
              {{ t('WHATSAPP_LOCATIONS.CURRENT_LOCATION') }}
            </span>
            <span class="text-xs text-n-slate-11">
              {{ t('WHATSAPP_LOCATIONS.SELECTOR.CURRENT_LOCATION_HINT') }}
            </span>
          </span>
        </button>
      </li>
      <li v-for="location in locations" :key="location.id">
        <button
          type="button"
          class="flex gap-3 items-center px-3 py-2 w-full rounded-lg text-start hover:bg-n-alpha-2 disabled:opacity-50"
          :disabled="isSending"
          @click="send(conversationId, { location_id: location.id })"
        >
          <Icon icon="i-lucide-map-pin" class="size-5 text-n-slate-11" />
          <span class="flex flex-col min-w-0">
            <span class="text-sm font-medium truncate text-n-slate-12">
              {{ location.name }}
            </span>
            <span class="text-xs truncate text-n-slate-11">
              {{ location.address }}
            </span>
          </span>
        </button>
      </li>
    </ul>
    <p v-if="!hasLocations" class="mb-0 text-sm text-center text-n-slate-11">
      {{ t('WHATSAPP_LOCATIONS.SELECTOR.EMPTY_SAVED') }}
    </p>
  </Dialog>
</template>
