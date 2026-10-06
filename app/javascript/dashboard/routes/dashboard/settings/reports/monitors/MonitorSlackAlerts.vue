<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import MonitorsAPI from 'dashboard/api/monitors';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Label from 'dashboard/components-next/label/Label.vue';

const props = defineProps({
  monitorId: { type: [String, Number], required: true },
  channelId: { type: String, default: '' },
});

const emit = defineEmits(['saved']);

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const channels = ref([]);
const selectedChannelId = ref(props.channelId);
const isReady = ref(false);
const isConnected = ref(false);
const areChannelsLoaded = ref(false);
const isSaving = ref(false);

const options = computed(() => [
  { value: '', label: t('MONITORS.SLACK_ALERT.NONE') },
  ...channels.value.map(({ id, name }) => ({ value: id, label: `#${name}` })),
]);

watch(
  () => props.channelId,
  channelId => {
    selectedChannelId.value = channelId;
  }
);

// Listing a workspace's channels is slow, so wait until the name of a saved channel is needed or the picker opens.
const loadChannels = async () => {
  if (areChannelsLoaded.value) return;
  channels.value =
    (await store.dispatch('integrations/listAllSlackChannels')) || [];
  areChannelsLoaded.value = true;
};

onMounted(async () => {
  await store.dispatch('integrations/get');
  const { hooks = [] } = store.getters['integrations/getIntegration']('slack');
  isConnected.value = hooks.length > 0;
  isReady.value = true;
  if (isConnected.value && props.channelId) loadChannels();
});

const save = async channelId => {
  if (channelId === props.channelId || isSaving.value) return;
  isSaving.value = true;
  try {
    await MonitorsAPI.update(props.monitorId, { slack_channel_id: channelId });
    useAlert(t('MONITORS.SLACK_ALERT.SAVED'));
    emit('saved');
  } catch {
    selectedChannelId.value = props.channelId;
    useAlert(t('MONITORS.SLACK_ALERT.SAVE_FAILED'));
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <section class="rounded-xl border border-n-weak bg-n-solid-1 p-5">
    <div class="flex flex-wrap items-center justify-between gap-4">
      <div class="flex items-start min-w-0 gap-3">
        <div
          class="flex items-center justify-center rounded-lg size-10 shrink-0 bg-n-alpha-2"
        >
          <Icon icon="i-logos-slack-icon" class="size-5" />
        </div>
        <div class="min-w-0">
          <div class="flex items-center gap-2">
            <h2 class="text-heading-3 text-n-slate-12">
              {{ t('MONITORS.SLACK_ALERT.TITLE') }}
            </h2>
            <Label
              v-if="isConnected"
              compact
              :color="channelId ? 'teal' : 'slate'"
              :label="
                channelId
                  ? t('MONITORS.SLACK_ALERT.ON')
                  : t('MONITORS.SLACK_ALERT.OFF')
              "
            >
              <template v-if="channelId" #icon>
                <span class="size-1.5 rounded-full bg-n-teal-9" />
              </template>
            </Label>
          </div>
          <p class="mb-0 text-body-main text-n-slate-11">
            {{ t('MONITORS.SLACK_ALERT.DESCRIPTION') }}
          </p>
        </div>
      </div>
      <template v-if="isReady">
        <ComboBox
          v-if="isConnected"
          v-model="selectedChannelId"
          :options="options"
          :disabled="isSaving"
          :display-label="t('MONITORS.SLACK_ALERT.LOADING')"
          :placeholder="t('MONITORS.SLACK_ALERT.PLACEHOLDER')"
          class="w-56 shrink-0"
          open-upwards
          @open="loadChannels"
          @update:model-value="save"
        />
        <Button
          v-else
          slate
          faded
          size="sm"
          icon="i-logos-slack-icon"
          :label="t('MONITORS.SLACK_ALERT.CONNECT')"
          @click="router.push({ name: 'settings_integrations_slack' })"
        />
      </template>
    </div>
  </section>
</template>
