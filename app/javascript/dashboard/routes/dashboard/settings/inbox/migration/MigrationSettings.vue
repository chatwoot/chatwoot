<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import InboxMigrationsAPI from 'dashboard/api/inboxMigrations';
import SettingsSection from 'dashboard/components/SettingsSection.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import MigrationConfirmModal from './MigrationConfirmModal.vue';
import MigrationStatus from './MigrationStatus.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const isLoading = ref(false);
const eligibleDestinations = ref([]);
const selectedDestinationId = ref(null);
const previewData = ref(null);
const isLoadingPreview = ref(false);
const showConfirmModal = ref(false);
const migrations = ref([]);
const activeMigration = ref(null);
const pollInterval = ref(null);

const hasEligibleDestinations = computed(
  () => eligibleDestinations.value.length > 0
);

const selectedDestination = computed(() => {
  if (!selectedDestinationId.value) return null;
  return eligibleDestinations.value.find(
    d => d.id === selectedDestinationId.value
  );
});

const canStartMigration = computed(() => {
  return (
    selectedDestinationId.value &&
    previewData.value &&
    !activeMigration.value?.status?.match(/queued|running/)
  );
});

// Define polling functions first (they're called by other functions below)
function stopPolling() {
  if (pollInterval.value) {
    clearInterval(pollInterval.value);
    pollInterval.value = null;
  }
}

function startPolling() {
  if (pollInterval.value) return;

  pollInterval.value = setInterval(async () => {
    if (activeMigration.value) {
      try {
        const response = await InboxMigrationsAPI.getMigration(
          props.inbox.id,
          activeMigration.value.id
        );
        activeMigration.value = response.data;

        // Stop polling if migration is complete
        if (!['queued', 'running'].includes(activeMigration.value.status)) {
          stopPolling();
          fetchMigrations(); // eslint-disable-line no-use-before-define
        }
      } catch {
        // Silently ignore polling errors
      }
    }
  }, 3000);
}

async function fetchEligibleDestinations() {
  try {
    isLoading.value = true;
    const response = await InboxMigrationsAPI.getEligibleDestinations(
      props.inbox.id
    );
    eligibleDestinations.value = response.data.inboxes || [];
  } catch (error) {
    useAlert(
      error.message || t('INBOX_MGMT.MIGRATION.ERRORS.FETCH_DESTINATIONS')
    );
  } finally {
    isLoading.value = false;
  }
}

async function fetchMigrations() {
  try {
    const response = await InboxMigrationsAPI.getMigrations(props.inbox.id);
    migrations.value = response.data.migrations || [];

    // Find active migration (queued or running)
    activeMigration.value = migrations.value.find(
      m => m.status === 'queued' || m.status === 'running'
    );

    // Start polling if there's an active migration
    if (activeMigration.value && !pollInterval.value) {
      startPolling();
    } else if (!activeMigration.value && pollInterval.value) {
      stopPolling();
    }
  } catch {
    // Silently ignore fetch errors
  }
}

async function fetchPreview() {
  if (!selectedDestinationId.value) {
    previewData.value = null;
    return;
  }

  try {
    isLoadingPreview.value = true;
    const response = await InboxMigrationsAPI.getPreview(
      props.inbox.id,
      selectedDestinationId.value
    );
    previewData.value = response.data;
  } catch (error) {
    useAlert(error.message || t('INBOX_MGMT.MIGRATION.ERRORS.FETCH_PREVIEW'));
    previewData.value = null;
  } finally {
    isLoadingPreview.value = false;
  }
}

function onDestinationChange() {
  fetchPreview();
}

function openConfirmModal() {
  showConfirmModal.value = true;
}

async function startMigration() {
  try {
    isLoading.value = true;
    const response = await InboxMigrationsAPI.createMigration(
      props.inbox.id,
      selectedDestinationId.value
    );

    activeMigration.value = response.data;
    showConfirmModal.value = false;

    // Clear preview data to hide the preview panel (it shows outdated data after migration)
    previewData.value = null;
    selectedDestinationId.value = null;

    useAlert(t('INBOX_MGMT.MIGRATION.SUCCESS.STARTED'));

    // Start polling for updates
    startPolling();
    fetchMigrations();
  } catch (error) {
    useAlert(
      error.response?.data?.errors?.join(', ') ||
        error.message ||
        t('INBOX_MGMT.MIGRATION.ERRORS.START_FAILED')
    );
  } finally {
    isLoading.value = false;
  }
}

onMounted(() => {
  fetchEligibleDestinations();
  fetchMigrations();
});

onUnmounted(() => {
  stopPolling();
});
</script>

<template>
  <div class="flex flex-col gap-6">
    <!-- Active Migration Status -->
    <MigrationStatus
      v-if="activeMigration"
      :migration="activeMigration"
      class="mb-4"
    />

    <!-- Migration Form -->
    <SettingsSection
      :title="$t('INBOX_MGMT.MIGRATION.TITLE')"
      :sub-title="$t('INBOX_MGMT.MIGRATION.DESCRIPTION')"
      :show-border="false"
    >
      <div class="flex flex-col gap-4">
        <!-- Destination Selector -->
        <div>
          <label class="mb-1 text-sm font-medium text-n-slate-12">
            {{ $t('INBOX_MGMT.MIGRATION.DESTINATION_LABEL') }}
          </label>
          <select
            v-model="selectedDestinationId"
            class="w-full"
            :disabled="isLoading || activeMigration?.status === 'running'"
            @change="onDestinationChange"
          >
            <option :value="null">
              {{ $t('INBOX_MGMT.MIGRATION.SELECT_DESTINATION') }}
            </option>
            <option
              v-for="dest in eligibleDestinations"
              :key="dest.id"
              :value="dest.id"
            >
              {{ dest.name }} ({{
                $t('INBOX_MGMT.MIGRATION.DESTINATION_CONVERSATIONS', {
                  count: dest.conversations_count,
                })
              }})
            </option>
          </select>
          <p
            v-if="!hasEligibleDestinations && !isLoading"
            class="mt-1 text-sm text-n-ruby-11"
          >
            {{ $t('INBOX_MGMT.MIGRATION.NO_ELIGIBLE_DESTINATIONS') }}
          </p>
        </div>

        <!-- Preview Data -->
        <div
          v-if="previewData"
          class="p-4 rounded-lg bg-n-alpha-1 border border-n-weak"
        >
          <h4 class="mb-3 text-sm font-medium text-n-slate-12">
            {{ $t('INBOX_MGMT.MIGRATION.PREVIEW_TITLE') }}
          </h4>

          <div class="grid grid-cols-2 gap-4 mb-4">
            <div>
              <span class="text-xs text-n-slate-11">{{
                $t('INBOX_MGMT.MIGRATION.CONVERSATIONS')
              }}</span>
              <p class="text-lg font-semibold text-n-slate-12">
                {{ previewData.counts.conversations }}
              </p>
            </div>
            <div>
              <span class="text-xs text-n-slate-11">{{
                $t('INBOX_MGMT.MIGRATION.MESSAGES')
              }}</span>
              <p class="text-lg font-semibold text-n-slate-12">
                {{ previewData.counts.messages }}
              </p>
            </div>
            <div>
              <span class="text-xs text-n-slate-11">{{
                $t('INBOX_MGMT.MIGRATION.ATTACHMENTS')
              }}</span>
              <p class="text-lg font-semibold text-n-slate-12">
                {{ previewData.counts.attachments }}
              </p>
            </div>
            <div>
              <span class="text-xs text-n-slate-11">{{
                $t('INBOX_MGMT.MIGRATION.CONTACTS')
              }}</span>
              <p class="text-lg font-semibold text-n-slate-12">
                {{ previewData.counts.contact_inboxes }}
              </p>
            </div>
          </div>

          <div
            v-if="previewData.conflicts.overlapping_contacts > 0"
            class="p-3 mb-3 rounded bg-n-amber-2 border border-n-amber-6"
          >
            <p class="text-sm text-n-amber-11">
              <strong>{{ previewData.conflicts.overlapping_contacts }}</strong>
              {{ $t('INBOX_MGMT.MIGRATION.CONTACTS_WILL_MERGE') }}
            </p>
          </div>

          <!-- eslint-disable vue/no-bare-strings-in-template -->
          <div
            v-for="(warning, idx) in previewData.warnings"
            :key="idx"
            class="p-2 mb-2 rounded bg-n-alpha-2"
          >
            <p class="text-xs text-n-slate-11">
              ⚠️
              {{
                $t(
                  `INBOX_MGMT.MIGRATION.WARNINGS.${warning.key}`,
                  warning.params || {}
                )
              }}
            </p>
          </div>
          <!-- eslint-enable vue/no-bare-strings-in-template -->
        </div>

        <!-- Loading Preview -->
        <div
          v-if="isLoadingPreview"
          class="p-4 rounded-lg bg-n-alpha-1 border border-n-weak"
        >
          <p class="text-sm text-n-slate-11">
            {{ $t('INBOX_MGMT.MIGRATION.LOADING_PREVIEW') }}
          </p>
        </div>

        <!-- Start Migration Button -->
        <div class="flex flex-col gap-2">
          <div class="flex gap-2">
            <NextButton
              :label="$t('INBOX_MGMT.MIGRATION.START_BUTTON')"
              :disabled="!canStartMigration"
              :is-loading="isLoading"
              @click="openConfirmModal"
            />
          </div>
          <p
            v-if="
              activeMigration &&
              ['queued', 'running'].includes(activeMigration.status)
            "
            class="text-sm text-n-amber-11"
          >
            {{ $t('INBOX_MGMT.MIGRATION.ACTIVE_MIGRATION_BLOCKED') }}
          </p>
        </div>
      </div>
    </SettingsSection>

    <!-- Migration History -->
    <SettingsSection
      v-if="migrations.length > 0"
      :title="$t('INBOX_MGMT.MIGRATION.HISTORY_TITLE')"
      :show-border="false"
    >
      <div class="flex flex-col gap-2">
        <div
          v-for="migration in migrations"
          :key="migration.id"
          class="p-3 rounded-lg bg-n-alpha-1 border border-n-weak"
        >
          <!-- eslint-disable vue/no-bare-strings-in-template -->
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-n-slate-12">
                {{ migration.source_inbox.name }} →
                {{ migration.destination_inbox.name }}
              </p>
              <!-- eslint-enable vue/no-bare-strings-in-template -->
              <p class="text-xs text-n-slate-11">
                {{ new Date(migration.timing.created_at).toLocaleString() }}
              </p>
            </div>
            <span
              class="px-2 py-1 text-xs font-medium rounded"
              :class="{
                'bg-n-jade-3 text-n-jade-11': migration.status === 'completed',
                'bg-n-ruby-3 text-n-ruby-11': migration.status === 'failed',
                'bg-n-blue-3 text-n-blue-11': migration.status === 'running',
                'bg-n-slate-3 text-n-slate-11': migration.status === 'queued',
                'bg-n-amber-3 text-n-amber-11':
                  migration.status === 'cancelled',
              }"
            >
              {{
                $t(
                  `INBOX_MGMT.MIGRATION.STATUS.${migration.status.toUpperCase()}`
                )
              }}
            </span>
          </div>
          <div
            v-if="migration.status === 'completed'"
            class="mt-2 text-xs text-n-slate-11"
          >
            {{
              $t('INBOX_MGMT.MIGRATION.HISTORY_SUMMARY', {
                conversations: migration.progress.conversations.moved,
                messages: migration.progress.messages.moved,
                contactsMerged: migration.progress.contacts_merged,
              })
            }}
          </div>
          <div v-if="migration.error" class="mt-2 text-xs text-n-ruby-11">
            {{ migration.error }}
          </div>
        </div>
      </div>
    </SettingsSection>

    <!-- Confirmation Modal -->
    <MigrationConfirmModal
      v-if="showConfirmModal"
      :source-inbox="inbox"
      :destination-inbox="selectedDestination"
      :preview-data="previewData"
      :is-loading="isLoading"
      @confirm="startMigration"
      @close="showConfirmModal = false"
    />
  </div>
</template>
