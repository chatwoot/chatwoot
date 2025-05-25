<template>
  <div class="dataset-management">
    <div class="page-header">
      <div class="header-content">
        <h1 class="page-title">
          {{ $t('DATASET_MANAGEMENT.TITLE') }}
        </h1>
        <p class="page-description">
          {{ $t('DATASET_MANAGEMENT.DESCRIPTION') }}
        </p>
      </div>
      <div class="header-actions">
        <woot-button
          color-scheme="primary"
          icon="add"
          @click="showCreateModal = true"
        >
          {{ $t('DATASET_MANAGEMENT.CREATE_NEW') }}
        </woot-button>
      </div>
    </div>

    <div v-if="isLoading" class="loading-container">
      <spinner />
    </div>

    <div v-else class="datasets-container">
      <div v-if="datasets.length === 0" class="empty-state">
        <div class="empty-state-content">
          <i class="icon ion-stats-bars empty-state-icon"></i>
          <h3>{{ $t('DATASET_MANAGEMENT.EMPTY_STATE.TITLE') }}</h3>
          <p>{{ $t('DATASET_MANAGEMENT.EMPTY_STATE.DESCRIPTION') }}</p>
          <woot-button
            color-scheme="primary"
            @click="showCreateModal = true"
          >
            {{ $t('DATASET_MANAGEMENT.CREATE_FIRST') }}
          </woot-button>
        </div>
      </div>

      <div v-else class="datasets-grid">
        <dataset-card
          v-for="dataset in datasets"
          :key="dataset.id"
          :dataset="dataset"
          @edit="editDataset"
          @delete="confirmDelete"
          @test="testConnection"
          @toggle="toggleDataset"
        />
      </div>
    </div>

    <!-- Create/Edit Modal -->
    <dataset-form-modal
      v-if="showCreateModal || showEditModal"
      :show="showCreateModal || showEditModal"
      :dataset="selectedDataset"
      :is-edit="showEditModal"
      @close="closeModals"
      @saved="onDatasetSaved"
    />

    <!-- Delete Confirmation Modal -->
    <woot-delete-modal
      v-if="showDeleteModal"
      :show="showDeleteModal"
      :on-close="closeDeleteModal"
      :on-confirm="deleteDataset"
      :title="$t('DATASET_MANAGEMENT.DELETE_MODAL.TITLE')"
      :message="$t('DATASET_MANAGEMENT.DELETE_MODAL.MESSAGE', { name: selectedDataset?.name })"
      :confirm-text="$t('DATASET_MANAGEMENT.DELETE_MODAL.CONFIRM')"
      :reject-text="$t('DATASET_MANAGEMENT.DELETE_MODAL.CANCEL')"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import DatasetCard from './components/DatasetCard.vue';
import DatasetFormModal from './components/DatasetFormModal.vue';
import DatasetAPI from '../../../../api/datasets';
import { useAlert } from 'dashboard/composables';

export default {
  name: 'DatasetManagement',
  components: {
    Spinner,
    DatasetCard,
    DatasetFormModal,
  },
  data() {
    return {
      isLoading: true,
      datasets: [],
      showCreateModal: false,
      showEditModal: false,
      showDeleteModal: false,
      selectedDataset: null,
    };
  },
  computed: {
    ...mapGetters({
      currentAccount: 'accounts/getAccount',
    }),
  },
  mounted() {
    this.loadDatasets();
  },
  methods: {
    async loadDatasets() {
      try {
        this.isLoading = true;
        const response = await DatasetAPI.getAll();
        this.datasets = response.data.data;
      } catch (error) {
        console.error('Error loading datasets:', error);
        useAlert(this.$t('DATASET_MANAGEMENT.LOAD_ERROR'));
      } finally {
        this.isLoading = false;
      }
    },

    editDataset(dataset) {
      this.selectedDataset = dataset;
      this.showEditModal = true;
    },

    confirmDelete(dataset) {
      this.selectedDataset = dataset;
      this.showDeleteModal = true;
    },

    async deleteDataset() {
      try {
        await DatasetAPI.delete(this.selectedDataset.id);
        useAlert(this.$t('DATASET_MANAGEMENT.DELETE_SUCCESS'));
        await this.loadDatasets();
        this.closeDeleteModal();
      } catch (error) {
        console.error('Error deleting dataset:', error);
        useAlert(this.$t('DATASET_MANAGEMENT.DELETE_ERROR'));
      }
    },

    async testConnection(dataset) {
      try {
        const response = await DatasetAPI.testConnection(dataset.id);
        if (response.data.success) {
          useAlert(this.$t('DATASET_MANAGEMENT.TEST_SUCCESS'));
        } else {
          useAlert(response.data.error || this.$t('DATASET_MANAGEMENT.TEST_ERROR'));
        }
      } catch (error) {
        console.error('Error testing connection:', error);
        useAlert(this.$t('DATASET_MANAGEMENT.TEST_ERROR'));
      }
    },

    async toggleDataset(dataset) {
      try {
        await DatasetAPI.update(dataset.id, {
          dataset_configuration: {
            enabled: !dataset.enabled
          }
        });
        useAlert(this.$t('DATASET_MANAGEMENT.TOGGLE_SUCCESS'));
        await this.loadDatasets();
      } catch (error) {
        console.error('Error toggling dataset:', error);
        useAlert(this.$t('DATASET_MANAGEMENT.TOGGLE_ERROR'));
      }
    },

    closeModals() {
      this.showCreateModal = false;
      this.showEditModal = false;
      this.selectedDataset = null;
    },

    closeDeleteModal() {
      this.showDeleteModal = false;
      this.selectedDataset = null;
    },

    async onDatasetSaved() {
      this.closeModals();
      await this.loadDatasets();
    },
  },
};
</script>

<style scoped lang="scss">
.dataset-management {
  padding: 1.5rem;
  max-width: 1200px;
  margin: 0 auto;

  .page-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 2rem;
    gap: 1rem;

    .header-content {
      flex: 1;

      .page-title {
        font-size: 1.75rem;
        font-weight: 600;
        margin-bottom: 0.5rem;
        color: var(--color-heading);
      }

      .page-description {
        color: var(--color-body);
        line-height: 1.5;
        margin: 0;
      }
    }

    .header-actions {
      flex-shrink: 0;
    }
  }

  .loading-container {
    display: flex;
    justify-content: center;
    padding: 3rem;
  }

  .empty-state {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 400px;

    .empty-state-content {
      text-align: center;
      max-width: 400px;

      .empty-state-icon {
        font-size: 4rem;
        color: var(--color-body-light);
        margin-bottom: 1rem;
      }

      h3 {
        font-size: 1.25rem;
        font-weight: 600;
        margin-bottom: 0.5rem;
        color: var(--color-heading);
      }

      p {
        color: var(--color-body);
        margin-bottom: 1.5rem;
        line-height: 1.5;
      }
    }
  }

  .datasets-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
    gap: 1.5rem;
  }
}

@media (max-width: 768px) {
  .dataset-management {
    padding: 1rem;

    .page-header {
      flex-direction: column;
      align-items: stretch;
    }

    .datasets-grid {
      grid-template-columns: 1fr;
    }
  }
}
</style>
