<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onBeforeMount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters } from 'dashboard/composables/store';
import { useRouter, useRoute } from 'vue-router';

import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'shared/components/Spinner.vue';

const getters = useStoreGetters();
const router = useRouter();
const route = useRoute();
const { t } = useI18n();
const isLoading = ref(false);
const stickers = ref([]);
const totalStickers = ref(0);
const showUploadModal = ref(false);

const accountId = computed(() => getters.getCurrentAccountId.value);
const packName = computed(() => route.params.packName);

const fetchPackDetails = async () => {
  isLoading.value = true;
  try {
    const response = await fetch(
      `/api/v1/accounts/${accountId.value}/sticker_packs/${packName.value}`
    );
    const data = await response.json();
    stickers.value = data.stickers;
    totalStickers.value = data.total_count;
  } catch (error) {
    useAlert(t('STICKER_MANAGEMENT.FETCH_PACK_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const goBack = () => {
  router.push({ name: 'sticker_management' });
};

onBeforeMount(() => {
  fetchPackDetails();
});
</script>

<template>
  <SettingsLayout>
    <BaseSettingsHeader
      :title="packName"
      :description="$t('STICKER_MANAGEMENT.PACK_DESCRIPTION')"
      feature-name="sticker_management"
    >
      <template #actions>
        <Button variant="hollow" icon="arrow-left" @click="goBack">
          {{ $t('STICKER_MANAGEMENT.BACK') }}
        </Button>
        <Button
          color-scheme="primary"
          icon="add"
          @click="showUploadModal = true"
        >
          {{ $t('STICKER_MANAGEMENT.ADD_STICKER') }}
        </Button>
      </template>
    </BaseSettingsHeader>

    <!-- Pack Stats -->
    <div class="pack-stats">
      <div class="stat-item">
        <span class="stat-label">{{
          $t('STICKER_MANAGEMENT.TOTAL_STICKERS')
        }}</span>
        <span class="stat-value">{{ totalStickers }}</span>
      </div>
    </div>

    <!-- Stickers Grid -->
    <div class="stickers-container">
      <div v-if="isLoading" class="loading-state">
        <Spinner />
        <p>{{ $t('STICKER_MANAGEMENT.LOADING_STICKERS') }}</p>
      </div>

      <div v-else-if="stickers.length === 0" class="empty-state">
        <fluent-icon icon="sticker" size="64" />
        <h3>{{ $t('STICKER_MANAGEMENT.EMPTY_PACK.TITLE') }}</h3>
        <p>{{ $t('STICKER_MANAGEMENT.EMPTY_PACK.MESSAGE') }}</p>
        <Button color-scheme="primary" @click="showUploadModal = true">
          {{ $t('STICKER_MANAGEMENT.ADD_FIRST_STICKER') }}
        </Button>
      </div>

      <div v-else class="stickers-grid">
        <div v-for="sticker in stickers" :key="sticker.id" class="sticker-item">
          <div class="sticker-preview">
            <img :src="sticker.url" :alt="sticker.filename" />
          </div>
          <div class="sticker-info">
            <span class="sticker-filename">{{ sticker.filename }}</span>
          </div>
        </div>
      </div>
    </div>
  </SettingsLayout>
</template>

<style lang="scss" scoped>
.sticker-pack-details {
  padding: var(--space-normal);

  .header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: var(--space-large);

    .header-left {
      display: flex;
      align-items: center;
      gap: var(--space-normal);

      .page-title {
        margin: 0;
        font-size: var(--font-size-large);
        font-weight: var(--font-weight-bold);
      }
    }

    .header-actions {
      display: flex;
      gap: var(--space-small);
    }
  }

  .pack-stats {
    display: flex;
    gap: var(--space-large);
    margin-bottom: var(--space-large);

    .stat-item {
      display: flex;
      flex-direction: column;

      .stat-label {
        font-size: var(--font-size-mini);
        color: var(--s-600);
        margin-bottom: var(--space-micro);
      }

      .stat-value {
        font-size: var(--font-size-medium);
        font-weight: var(--font-weight-bold);
        color: var(--s-800);
      }
    }
  }

  .loading-state,
  .empty-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: var(--space-jumbo);
    text-align: center;

    p {
      margin-top: var(--space-normal);
      color: var(--s-600);
    }

    h3 {
      margin: var(--space-normal) 0 var(--space-small);
      color: var(--s-800);
    }
  }

  .stickers-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: var(--space-normal);
  }

  .sticker-item {
    border: 1px solid var(--color-border);
    border-radius: var(--border-radius-medium);
    overflow: hidden;
    transition: all 0.2s ease;

    &:hover {
      border-color: var(--w-500);
      box-shadow: var(--shadow-small);

      .sticker-overlay {
        opacity: 1;
      }
    }

    .sticker-preview {
      position: relative;
      aspect-ratio: 1;
      overflow: hidden;

      img {
        width: 100%;
        height: 100%;
        object-fit: cover;
      }

      .sticker-overlay {
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        gap: var(--space-small);
        opacity: 0;
        transition: opacity 0.2s ease;
      }
    }

    .sticker-info {
      padding: var(--space-small);

      .sticker-filename {
        display: block;
        font-size: var(--font-size-mini);
        font-weight: var(--font-weight-medium);
        color: var(--s-800);
        margin-bottom: var(--space-micro);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
      }

      .sticker-size {
        font-size: var(--font-size-micro);
        color: var(--s-600);
      }
    }
  }

  .modal-content {
    padding: var(--space-normal);

    h3 {
      margin: 0 0 var(--space-normal);
      font-size: var(--font-size-medium);
      font-weight: var(--font-weight-medium);
    }

    .upload-area {
      margin-bottom: var(--space-normal);

      .drop-zone {
        border: 2px dashed var(--color-border);
        border-radius: var(--border-radius-medium);
        padding: var(--space-large);
        text-align: center;
        cursor: pointer;
        transition: all 0.2s ease;

        &:hover,
        &.drag-over {
          border-color: var(--w-500);
          background-color: var(--w-25);
        }

        p {
          margin: var(--space-normal) 0;
          color: var(--s-600);
        }
      }
    }

    .file-preview {
      display: flex;
      gap: var(--space-normal);
      padding: var(--space-normal);
      border: 1px solid var(--color-border);
      border-radius: var(--border-radius-medium);
      margin-bottom: var(--space-normal);

      .preview-image {
        width: 100px;
        height: 100px;
        border-radius: var(--border-radius-small);
        overflow: hidden;

        img {
          width: 100%;
          height: 100%;
          object-fit: cover;
        }
      }

      .file-info {
        flex: 1;

        h4 {
          margin: 0 0 var(--space-smaller);
          font-size: var(--font-size-small);
          font-weight: var(--font-weight-medium);
        }

        p {
          margin: 0 0 var(--space-normal);
          font-size: var(--font-size-mini);
          color: var(--s-600);
        }
      }
    }

    .form-group {
      margin-bottom: var(--space-normal);

      label {
        display: block;
        margin-bottom: var(--space-smaller);
        font-weight: var(--font-weight-medium);
        color: var(--s-700);
      }

      .form-control {
        width: 100%;
        padding: var(--space-small);
        border: 1px solid var(--color-border);
        border-radius: var(--border-radius-small);
        font-size: var(--font-size-small);

        &:focus {
          outline: none;
          border-color: var(--w-500);
          box-shadow: 0 0 0 2px var(--w-100);
        }
      }

      .help-text {
        display: block;
        margin-top: var(--space-smaller);
        font-size: var(--font-size-micro);
        color: var(--s-500);
      }
    }

    .validation-result {
      margin-bottom: var(--space-normal);
      padding: var(--space-small);
      border-radius: var(--border-radius-small);

      .validation-success {
        display: flex;
        align-items: center;
        gap: var(--space-smaller);
        color: var(--g-700);
        background-color: var(--g-50);
        border: 1px solid var(--g-200);
      }

      .validation-error {
        display: flex;
        align-items: center;
        gap: var(--space-smaller);
        color: var(--r-700);
        background-color: var(--r-50);
        border: 1px solid var(--r-200);
      }
    }

    .selected-files {
      margin-bottom: var(--space-normal);

      h4 {
        margin: 0 0 var(--space-normal);
        font-size: var(--font-size-small);
        font-weight: var(--font-weight-medium);
      }

      .files-list {
        max-height: 300px;
        overflow-y: auto;
        border: 1px solid var(--color-border);
        border-radius: var(--border-radius-small);
      }

      .file-item {
        display: flex;
        align-items: center;
        gap: var(--space-small);
        padding: var(--space-small);
        border-bottom: 1px solid var(--color-border);

        &:last-child {
          border-bottom: none;
        }

        .file-preview {
          width: 40px;
          height: 40px;
          border-radius: var(--border-radius-small);
          overflow: hidden;

          img {
            width: 100%;
            height: 100%;
            object-fit: cover;
          }
        }

        .file-details {
          flex: 1;

          .file-name {
            display: block;
            font-size: var(--font-size-mini);
            font-weight: var(--font-weight-medium);
            margin-bottom: var(--space-micro);
          }

          .file-size {
            font-size: var(--font-size-micro);
            color: var(--s-600);
          }
        }
      }
    }

    .upload-progress {
      margin-bottom: var(--space-normal);

      h4 {
        margin: 0 0 var(--space-normal);
        font-size: var(--font-size-small);
        font-weight: var(--font-weight-medium);
      }

      .progress-list {
        max-height: 200px;
        overflow-y: auto;
        border: 1px solid var(--color-border);
        border-radius: var(--border-radius-small);
      }

      .progress-item {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: var(--space-small);
        border-bottom: 1px solid var(--color-border);

        &:last-child {
          border-bottom: none;
        }

        &.success {
          background-color: var(--g-25);
        }

        &.error {
          background-color: var(--r-25);
        }

        .file-name {
          font-size: var(--font-size-mini);
        }

        .progress-status {
          .success-icon {
            color: var(--g-600);
          }

          .error-icon {
            color: var(--r-600);
          }
        }
      }
    }

    .modal-actions {
      display: flex;
      justify-content: flex-end;
      gap: var(--space-small);
      margin-top: var(--space-large);
    }
  }
}
</style>
