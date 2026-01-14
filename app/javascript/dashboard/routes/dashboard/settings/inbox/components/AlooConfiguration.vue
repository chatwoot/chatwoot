<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  inbox: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();
const store = useStore();

const selectedAssistantId = ref(null);
const isLoading = ref(true);
const isApplying = ref(false);
const isDisconnecting = ref(false);

const assistants = computed(
  () => store.getters['alooAssistants/getRecords'] || []
);

const currentAssistant = computed(() => props.inbox?.aloo_assistant);

const hasCurrentAssistant = computed(
  () => currentAssistant.value && currentAssistant.value.id
);

const canApply = computed(
  () => selectedAssistantId.value && !isApplying.value && !isDisconnecting.value
);

const canDisconnect = computed(
  () => hasCurrentAssistant.value && !isApplying.value && !isDisconnecting.value
);

watch(
  () => currentAssistant.value,
  newVal => {
    if (newVal?.id) {
      selectedAssistantId.value = newVal.id;
    }
  },
  { immediate: true }
);

onMounted(async () => {
  try {
    await store.dispatch('alooAssistants/get');
  } catch (error) {
    useAlert(t('ALOO.MESSAGES.ERROR'));
  } finally {
    isLoading.value = false;
  }
});

const applyAssistant = async () => {
  if (!selectedAssistantId.value) return;

  isApplying.value = true;
  try {
    await store.dispatch('alooAssistants/assignInbox', {
      assistantId: selectedAssistantId.value,
      inboxId: props.inbox.id,
    });
    await store.dispatch('inboxes/get');
    useAlert(t('ALOO.INBOX_CONFIGURATION.APPLY_SUCCESS'));
  } catch (error) {
    useAlert(error?.message || t('ALOO.INBOX_CONFIGURATION.APPLY_ERROR'));
  } finally {
    isApplying.value = false;
  }
};

const disconnectAssistant = async () => {
  if (!hasCurrentAssistant.value) return;

  isDisconnecting.value = true;
  try {
    await store.dispatch('alooAssistants/unassignInbox', {
      assistantId: currentAssistant.value.id,
      inboxId: props.inbox.id,
    });
    await store.dispatch('inboxes/get');
    selectedAssistantId.value = null;
    useAlert(t('ALOO.INBOX_CONFIGURATION.DISCONNECT_SUCCESS'));
  } catch (error) {
    useAlert(error?.message || t('ALOO.INBOX_CONFIGURATION.DISCONNECT_ERROR'));
  } finally {
    isDisconnecting.value = false;
  }
};
</script>

<template>
  <div class="mx-8">
    <LoadingState v-if="isLoading" />
    <form v-else class="flex flex-wrap mx-0" @submit.prevent="applyAssistant">
      <SettingsSection
        :title="$t('ALOO.INBOX_CONFIGURATION.TITLE')"
        :sub-title="$t('ALOO.INBOX_CONFIGURATION.DESCRIPTION')"
      >
        <div v-if="assistants.length === 0" class="py-4">
          <p class="text-n-slate-11 text-sm">
            {{ $t('ALOO.INBOX_CONFIGURATION.NO_ASSISTANTS') }}
          </p>
        </div>

        <div v-else>
          <div class="flex flex-col gap-3 mb-6">
            <label
              v-for="assistant in assistants"
              :key="assistant.id"
              class="relative flex items-center gap-3 p-4 border rounded-lg cursor-pointer transition-all"
              :class="{
                'border-woot-500 bg-woot-25 dark:bg-woot-800/20':
                  selectedAssistantId === assistant.id,
                'border-n-slate-6 hover:border-n-slate-8':
                  selectedAssistantId !== assistant.id,
              }"
            >
              <input
                v-model="selectedAssistantId"
                type="radio"
                :value="assistant.id"
                class="w-4 h-4 text-woot-500 border-n-slate-6 focus:ring-woot-500"
              />
              <div class="flex-1">
                <div class="flex items-center gap-2">
                  <span class="font-medium text-n-slate-12">
                    {{ assistant.name }}
                  </span>
                  <span
                    v-if="
                      hasCurrentAssistant &&
                      currentAssistant.id === assistant.id
                    "
                    class="px-2 py-0.5 text-xs font-medium rounded-full bg-n-teal-3 text-n-teal-11"
                  >
                    {{ $t('ALOO.INBOX_CONFIGURATION.CURRENT_ASSISTANT') }}
                  </span>
                </div>
                <p
                  v-if="assistant.description"
                  class="mt-1 text-sm text-n-slate-11"
                >
                  {{ assistant.description }}
                </p>
              </div>
            </label>
          </div>

          <div class="flex gap-2">
            <NextButton
              type="submit"
              :disabled="!canApply"
              :is-loading="isApplying"
              :label="$t('ALOO.INBOX_CONFIGURATION.APPLY')"
            />
            <NextButton
              v-if="hasCurrentAssistant"
              type="button"
              :disabled="!canDisconnect"
              :is-loading="isDisconnecting"
              faded
              ruby
              @click="disconnectAssistant"
            >
              {{ $t('ALOO.INBOX_CONFIGURATION.DISCONNECT') }}
            </NextButton>
          </div>
        </div>
      </SettingsSection>
    </form>
  </div>
</template>
