<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  assistantId: {
    type: [String, Number],
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();
const getters = useStoreGetters();

const isLoading = ref(true);
const searchQuery = ref('');
const assignedInboxIds = ref([]);

const inboxes = computed(() => getters['inboxes/getInboxes'].value);

const filteredInboxes = computed(() => {
  if (!searchQuery.value) return inboxes.value;
  const query = searchQuery.value.toLowerCase();
  return inboxes.value.filter(
    inbox =>
      inbox.name.toLowerCase().includes(query) ||
      inbox.channel_type.toLowerCase().includes(query)
  );
});

onMounted(async () => {
  try {
    await Promise.all([
      store.dispatch('inboxes/get'),
      store.dispatch('alooAssistants/show', props.assistantId),
    ]);

    const assistant = getters['alooAssistants/getRecord'].value(
      props.assistantId
    );
    if (assistant?.assigned_inboxes) {
      assignedInboxIds.value = assistant.assigned_inboxes.map(i => i.id);
    }
  } catch (error) {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  } finally {
    isLoading.value = false;
  }
});

const toggleInbox = async inboxId => {
  const isAssigned = assignedInboxIds.value.includes(inboxId);
  try {
    if (isAssigned) {
      await store.dispatch('alooAssistants/unassignInbox', {
        assistantId: props.assistantId,
        inboxId,
      });
      assignedInboxIds.value = assignedInboxIds.value.filter(
        id => id !== inboxId
      );
      useAlert(t('ALOO.MESSAGES.INBOX_UNASSIGNED'));
    } else {
      await store.dispatch('alooAssistants/assignInbox', {
        assistantId: props.assistantId,
        inboxId,
      });
      assignedInboxIds.value.push(inboxId);
      useAlert(t('ALOO.MESSAGES.INBOX_ASSIGNED'));
    }
    // Refresh inboxes store to keep aloo_assistant data in sync
    await store.dispatch('inboxes/get');
  } catch (error) {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  }
};

const getInboxIcon = inbox => {
  const iconMap = {
    'Channel::WebWidget': 'i-lucide-globe',
    'Channel::FacebookPage': 'i-lucide-facebook',
    'Channel::Whatsapp': 'i-lucide-message-circle',
    'Channel::Email': 'i-lucide-mail',
    'Channel::Telegram': 'i-lucide-send',
    'Channel::Sms': 'i-lucide-smartphone',
    'Channel::TwitterProfile': 'i-lucide-twitter',
    'Channel::Line': 'i-lucide-message-square',
    'Channel::Api': 'i-lucide-code',
  };
  return iconMap[inbox.channel_type] || 'i-lucide-inbox';
};

const getChannelName = channelType => {
  return channelType?.replace('Channel::', '') || 'Unknown';
};

const getOtherAssignedAssistant = inbox => {
  if (!inbox.aloo_assistant) return null;
  if (inbox.aloo_assistant.id === Number(props.assistantId)) return null;
  return inbox.aloo_assistant;
};
</script>

<template>
  <div>
    <div v-if="isLoading" class="flex items-center justify-center py-12">
      <woot-loading-state :message="$t('ALOO.INBOXES.LOADING')" />
    </div>

    <template v-else>
      <SettingsSection
        :title="$t('ALOO.INBOXES.TITLE')"
        :sub-title="$t('ALOO.INBOXES.DESCRIPTION')"
        :show-border="false"
      >
        <!-- Search -->
        <div class="mb-4">
          <Input
            v-model="searchQuery"
            :placeholder="$t('ALOO.INBOXES.SEARCH_PLACEHOLDER')"
            icon="i-lucide-search"
          />
        </div>

        <!-- Inboxes List -->
        <div
          v-if="filteredInboxes.length"
          class="space-y-2 border rounded-lg border-n-weak divide-y divide-n-weak"
        >
          <div
            v-for="inbox in filteredInboxes"
            :key="inbox.id"
            class="flex items-center gap-4 p-4 cursor-pointer hover:bg-n-alpha-1 transition-colors"
            :class="{
              'bg-n-blue-2': assignedInboxIds.includes(inbox.id),
            }"
            @click="toggleInbox(inbox.id)"
          >
            <Checkbox :model-value="assignedInboxIds.includes(inbox.id)" />
            <div
              class="flex items-center justify-center w-10 h-10 rounded-lg bg-n-alpha-2"
            >
              <span
                class="text-xl text-n-slate-11"
                :class="[getInboxIcon(inbox)]"
              />
            </div>
            <div class="flex-1">
              <p class="text-sm font-medium text-n-slate-12">
                {{ inbox.name }}
              </p>
              <p class="text-xs text-n-slate-10">
                {{ getChannelName(inbox.channel_type) }}
              </p>
            </div>
            <span
              v-if="getOtherAssignedAssistant(inbox)"
              class="px-2 py-1 text-xs font-medium rounded bg-n-amber-3 text-n-amber-11"
            >
              {{
                $t('ALOO.INBOXES.ASSIGNED_TO', {
                  name: getOtherAssignedAssistant(inbox).name,
                })
              }}
            </span>
            <span
              v-if="assignedInboxIds.includes(inbox.id)"
              class="px-2 py-1 text-xs font-medium rounded bg-n-green-3 text-n-green-11"
            >
              {{ $t('ALOO.INBOXES.ASSIGNED') }}
            </span>
          </div>
        </div>

        <!-- Empty States -->
        <div
          v-else-if="searchQuery && !filteredInboxes.length"
          class="p-8 text-center bg-n-alpha-1 rounded-lg border border-n-weak"
        >
          <span class="i-lucide-search text-3xl text-n-slate-9" />
          <p class="text-sm text-n-slate-11 mt-2">
            {{ $t('ALOO.INBOXES.NO_RESULTS') }}
          </p>
        </div>
        <div
          v-else
          class="p-8 text-center bg-n-alpha-1 rounded-lg border border-n-weak"
        >
          <span class="i-lucide-inbox text-3xl text-n-slate-9" />
          <p class="text-sm text-n-slate-11 mt-2">
            {{ $t('ALOO.INBOXES.NO_INBOXES') }}
          </p>
        </div>

        <!-- Summary -->
        <p v-if="assignedInboxIds.length" class="mt-4 text-sm text-n-slate-10">
          {{
            $t('ALOO.INBOXES.ASSIGNED_COUNT', {
              count: assignedInboxIds.length,
            })
          }}
        </p>
      </SettingsSection>
    </template>
  </div>
</template>
