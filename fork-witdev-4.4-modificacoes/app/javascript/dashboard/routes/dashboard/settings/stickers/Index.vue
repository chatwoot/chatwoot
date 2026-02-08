<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onBeforeMount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStoreGetters } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';

import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'shared/components/Spinner.vue';

const getters = useStoreGetters();
const router = useRouter();
const { t } = useI18n();
const isLoading = ref(false);
const stickerPacks = ref([]);
const showCreatePackModal = ref(false);
const showEditPackModal = ref(false);
const showDeleteModal = ref(false);
const newPackName = ref('');
const editingPack = ref(null);
const editingPackName = ref('');
const deletingPack = ref(null);
const isCreatingPack = ref(false);
// const isUpdatingPack = ref(false);

const accountId = computed(() => getters.getCurrentAccountId.value);

const fetchStickerPacks = async () => {
  isLoading.value = true;
  try {
    const response = await fetch(
      `/api/v1/accounts/${accountId.value}/sticker_packs`
    );
    const data = await response.json();
    stickerPacks.value = data.sticker_packs;
  } catch (error) {
    useAlert(t('STICKER_MANAGEMENT.FETCH_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

onBeforeMount(() => {
  fetchStickerPacks();
});

const openPackDetails = pack => {
  router.push({
    name: 'sticker_pack_details',
    params: { packName: pack.name },
  });
};

const editPack = pack => {
  editingPack.value = pack;
  editingPackName.value = pack.name;
  showEditPackModal.value = true;
};

const deletePack = pack => {
  deletingPack.value = pack;
  showDeleteModal.value = true;
};

const closeCreatePackModal = () => {
  showCreatePackModal.value = false;
  newPackName.value = '';
};

// const closeEditPackModal = () => {
//   showEditPackModal.value = false;
//   editingPack.value = null;
//   editingPackName.value = '';
// };

// const closeDeleteModal = () => {
//   showDeleteModal.value = false;
//   deletingPack.value = null;
// };

const createPack = async () => {
  if (!newPackName.value.trim()) return;

  isCreatingPack.value = true;
  try {
    const response = await fetch(
      `/api/v1/accounts/${accountId.value}/sticker_packs`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          sticker_pack: {
            name: newPackName.value.trim(),
          },
        }),
      }
    );

    if (response.ok) {
      useAlert(t('STICKER_MANAGEMENT.PACK_CREATED_SUCCESS'));
      closeCreatePackModal();
      fetchStickerPacks();
    } else {
      const errorData = await response.json();
      useAlert(errorData.error || t('STICKER_MANAGEMENT.PACK_CREATE_ERROR'));
    }
  } catch (error) {
    useAlert(t('STICKER_MANAGEMENT.PACK_CREATE_ERROR'));
  } finally {
    isCreatingPack.value = false;
  }
};

// const updatePack = async () => {
//   if (!editingPackName.value.trim() || !editingPack.value) return;

//   isUpdatingPack.value = true;
//   try {
//     const response = await fetch(`/api/v1/accounts/${accountId.value}/sticker_packs/${editingPack.value.name}`, {
//       method: 'PUT',
//       headers: {
//         'Content-Type': 'application/json',
//       },
//       body: JSON.stringify({
//         sticker_pack: {
//           name: editingPackName.value.trim(),
//         },
//       }),
//     });

//     if (response.ok) {
//       useAlert(t('STICKER_MANAGEMENT.PACK_UPDATED_SUCCESS'));
//       closeEditPackModal();
//       fetchStickerPacks();
//     } else {
//       const errorData = await response.json();
//       useAlert(errorData.error || t('STICKER_MANAGEMENT.PACK_UPDATE_ERROR'));
//     }
//   } catch (error) {
//     useAlert(t('STICKER_MANAGEMENT.PACK_UPDATE_ERROR'));
//   } finally {
//     isUpdatingPack.value = false;
//   }
// };

// const confirmDeletePack = async () => {
//   if (!deletingPack.value) return;

//   try {
//     const response = await fetch(`/api/v1/accounts/${accountId.value}/sticker_packs/${deletingPack.value.name}`, {
//       method: 'DELETE',
//     });

//     if (response.ok) {
//       useAlert(t('STICKER_MANAGEMENT.PACK_DELETED_SUCCESS'));
//       closeDeleteModal();
//       fetchStickerPacks();
//     } else {
//       const errorData = await response.json();
//       useAlert(errorData.error || t('STICKER_MANAGEMENT.PACK_DELETE_ERROR'));
//     }
//   } catch (error) {
//     useAlert(t('STICKER_MANAGEMENT.PACK_DELETE_ERROR'));
//   }
// };

const formatDate = dateString => {
  if (!dateString) return '';
  return new Date(dateString).toLocaleDateString();
};
</script>

<template>
  <SettingsLayout>
    <BaseSettingsHeader
      :title="$t('STICKER_MANAGEMENT.TITLE')"
      :description="$t('STICKER_MANAGEMENT.DESCRIPTION')"
      :link-text="$t('STICKER_MANAGEMENT.LEARN_MORE')"
      feature-name="sticker_management"
    >
      <template #actions>
        <Button
          color-scheme="primary"
          icon="add"
          @click="showCreatePackModal = true"
        >
          {{ $t('STICKER_MANAGEMENT.CREATE_PACK') }}
        </Button>
      </template>
    </BaseSettingsHeader>

    <!-- Sticker Packs List -->
    <div class="sticker-packs-container">
      <div v-if="isLoading" class="loading-state">
        <Spinner />
        <p>{{ $t('STICKER_MANAGEMENT.LOADING') }}</p>
      </div>

      <div v-else-if="stickerPacks.length === 0" class="empty-state">
        <fluent-icon icon="sticker" size="64" />
        <h3>{{ $t('STICKER_MANAGEMENT.EMPTY_STATE.TITLE') }}</h3>
        <p>{{ $t('STICKER_MANAGEMENT.EMPTY_STATE.MESSAGE') }}</p>
        <Button color-scheme="primary" @click="showCreatePackModal = true">
          {{ $t('STICKER_MANAGEMENT.CREATE_FIRST_PACK') }}
        </Button>
      </div>

      <div v-else class="sticker-packs-grid">
        <div
          v-for="pack in stickerPacks"
          :key="pack.name"
          class="sticker-pack-card"
          @click="openPackDetails(pack)"
        >
          <div class="pack-header">
            <h3>{{ pack.name }}</h3>
            <div class="pack-actions">
              <Button
                variant="hollow"
                size="tiny"
                icon="edit"
                @click.stop="editPack(pack)"
              />
              <Button
                variant="hollow"
                size="tiny"
                icon="delete"
                color-scheme="alert"
                @click.stop="deletePack(pack)"
              />
            </div>
          </div>
          <div class="pack-info">
            <span class="sticker-count">
              {{ pack.sticker_count }} {{ $t('STICKER_MANAGEMENT.STICKERS') }}
            </span>
            <span class="created-date">
              {{ formatDate(pack.created_at) }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- Simple Create Pack Form -->
    <div v-if="showCreatePackModal" class="modal-overlay">
      <div class="modal-content">
        <h3>{{ $t('STICKER_MANAGEMENT.CREATE_PACK_MODAL.TITLE') }}</h3>
        <form @submit.prevent="createPack">
          <div class="form-group">
            <label>{{
              $t('STICKER_MANAGEMENT.CREATE_PACK_MODAL.PACK_NAME')
            }}</label>
            <input
              v-model="newPackName"
              type="text"
              class="form-control"
              :placeholder="
                $t('STICKER_MANAGEMENT.CREATE_PACK_MODAL.PACK_NAME_PLACEHOLDER')
              "
              required
            />
          </div>
          <div class="modal-actions">
            <Button variant="hollow" @click="closeCreatePackModal">
              {{ $t('STICKER_MANAGEMENT.CANCEL') }}
            </Button>
            <Button
              type="submit"
              color-scheme="primary"
              :loading="isCreatingPack"
            >
              {{ $t('STICKER_MANAGEMENT.CREATE') }}
            </Button>
          </div>
        </form>
      </div>
    </div>
  </SettingsLayout>
</template>

<style lang="scss" scoped>
.sticker-management {
  padding: var(--space-normal);

  .header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: var(--space-large);

    .page-title {
      margin: 0;
      font-size: var(--font-size-large);
      font-weight: var(--font-weight-bold);
    }
  }

  .loading-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: var(--space-jumbo);

    p {
      margin-top: var(--space-normal);
      color: var(--s-600);
    }
  }

  .empty-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: var(--space-jumbo);
    text-align: center;

    h3 {
      margin: var(--space-normal) 0 var(--space-small);
      color: var(--s-800);
    }

    p {
      margin-bottom: var(--space-large);
      color: var(--s-600);
    }
  }

  .sticker-packs-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: var(--space-normal);
  }

  .sticker-pack-card {
    border: 1px solid var(--color-border);
    border-radius: var(--border-radius-medium);
    padding: var(--space-normal);
    cursor: pointer;
    transition: all 0.2s ease;

    &:hover {
      border-color: var(--w-500);
      box-shadow: var(--shadow-small);
    }

    .pack-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: var(--space-small);

      h3 {
        margin: 0;
        font-size: var(--font-size-medium);
        font-weight: var(--font-weight-medium);
        color: var(--s-800);
      }

      .pack-actions {
        display: flex;
        gap: var(--space-smaller);
        opacity: 0;
        transition: opacity 0.2s ease;
      }
    }

    &:hover .pack-actions {
      opacity: 1;
    }

    .pack-info {
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: var(--font-size-mini);
      color: var(--s-600);

      .sticker-count {
        font-weight: var(--font-weight-medium);
      }
    }
  }

  .modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
  }

  .modal-content {
    background: white;
    border-radius: var(--border-radius-medium);
    padding: var(--space-large);
    min-width: 400px;
    max-width: 90vw;

    h3 {
      margin: 0 0 var(--space-normal);
      font-size: var(--font-size-medium);
      font-weight: var(--font-weight-medium);
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
