<template>
  <div class="dataset-card" :class="{ disabled: !dataset.enabled }">
    <div class="card-header">
      <div class="dataset-info">
        <h3 class="dataset-name">{{ dataset.name }}</h3>
        <div class="dataset-meta">
          <span class="platform-badge" :class="platformClass">
            <i :class="platformIcon"></i>
            {{ platformLabel }}
          </span>
          <span class="pixel-id">{{ dataset.pixel_id }}</span>
        </div>
      </div>
      <div class="card-actions">
        <woot-button
          variant="hollow"
          size="tiny"
          color-scheme="secondary"
          icon="settings"
          @click="$emit('edit', dataset)"
        >
          {{ $t('DATASET_MANAGEMENT.EDIT') }}
        </woot-button>
      </div>
    </div>

    <div class="card-content">
      <div class="dataset-stats">
        <div class="stat-item">
          <span class="stat-label">{{ $t('DATASET_MANAGEMENT.INBOXES_COUNT') }}</span>
          <span class="stat-value">{{ dataset.inboxes_count }}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">{{ $t('DATASET_MANAGEMENT.EVENT_NAME') }}</span>
          <span class="stat-value">{{ dataset.default_event_name }}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">{{ $t('DATASET_MANAGEMENT.EVENT_VALUE') }}</span>
          <span class="stat-value">{{ formatCurrency(dataset.default_event_value, dataset.default_currency) }}</span>
        </div>
      </div>

      <div v-if="dataset.description" class="dataset-description">
        {{ dataset.description }}
      </div>
    </div>

    <div class="card-footer">
      <div class="status-section">
        <label class="toggle-switch">
          <input
            type="checkbox"
            :checked="dataset.enabled"
            @change="$emit('toggle', dataset)"
          />
          <span class="toggle-slider"></span>
          <span class="toggle-label">
            {{ dataset.enabled ? $t('DATASET_MANAGEMENT.ENABLED') : $t('DATASET_MANAGEMENT.DISABLED') }}
          </span>
        </label>
      </div>

      <div class="action-buttons">
        <woot-button
          variant="hollow"
          size="tiny"
          color-scheme="primary"
          icon="checkmark-circle"
          @click="$emit('test', dataset)"
        >
          {{ $t('DATASET_MANAGEMENT.TEST') }}
        </woot-button>
        <woot-button
          variant="hollow"
          size="tiny"
          color-scheme="alert"
          icon="delete"
          @click="$emit('delete', dataset)"
        >
          {{ $t('DATASET_MANAGEMENT.DELETE_BUTTON') }}
        </woot-button>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'DatasetCard',
  props: {
    dataset: {
      type: Object,
      required: true,
    },
  },
  computed: {
    platformClass() {
      return `platform-${this.dataset.platform}`;
    },

    platformIcon() {
      const icons = {
        facebook: 'ion-social-facebook',
        instagram: 'ion-social-instagram',
        meta: 'ion-planet'
      };
      return icons[this.dataset.platform] || 'ion-help';
    },

    platformLabel() {
      const labels = {
        facebook: 'Facebook',
        instagram: 'Instagram',
        meta: 'Meta (FB/IG)'
      };
      return labels[this.dataset.platform] || this.dataset.platform;
    },
  },
  methods: {
    formatCurrency(value, currency) {
      if (!value && value !== 0) return '-';

      try {
        return new Intl.NumberFormat('en-US', {
          style: 'currency',
          currency: currency || 'USD',
          minimumFractionDigits: 0,
          maximumFractionDigits: 2,
        }).format(value);
      } catch (error) {
        return `${value} ${currency || 'USD'}`;
      }
    },
  },
};
</script>

<style scoped lang="scss">
.dataset-card {
  background: var(--color-background);
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 1.5rem;
  transition: all 0.2s ease;

  &:hover {
    border-color: var(--color-primary-light);
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  }

  &.disabled {
    opacity: 0.6;
    background: var(--color-background-light);
  }

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 1rem;
    gap: 1rem;

    .dataset-info {
      flex: 1;

      .dataset-name {
        font-size: 1.125rem;
        font-weight: 600;
        margin-bottom: 0.5rem;
        color: var(--color-heading);
      }

      .dataset-meta {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        flex-wrap: wrap;

        .platform-badge {
          display: inline-flex;
          align-items: center;
          gap: 0.25rem;
          padding: 0.25rem 0.5rem;
          border-radius: 12px;
          font-size: 0.75rem;
          font-weight: 500;

          &.platform-facebook {
            background: #1877f2;
            color: white;
          }

          &.platform-instagram {
            background: linear-gradient(45deg, #f09433 0%, #e6683c 25%, #dc2743 50%, #cc2366 75%, #bc1888 100%);
            color: white;
          }

          &.platform-meta {
            background: #0668e1;
            color: white;
          }
        }

        .pixel-id {
          font-family: monospace;
          font-size: 0.75rem;
          color: var(--color-body-light);
          background: var(--color-background-light);
          padding: 0.25rem 0.5rem;
          border-radius: 4px;
        }
      }
    }

    .card-actions {
      flex-shrink: 0;
    }
  }

  .card-content {
    margin-bottom: 1rem;

    .dataset-stats {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(100px, 1fr));
      gap: 1rem;
      margin-bottom: 1rem;

      .stat-item {
        text-align: center;

        .stat-label {
          display: block;
          font-size: 0.75rem;
          color: var(--color-body-light);
          margin-bottom: 0.25rem;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }

        .stat-value {
          display: block;
          font-size: 0.875rem;
          font-weight: 600;
          color: var(--color-heading);
        }
      }
    }

    .dataset-description {
      font-size: 0.875rem;
      color: var(--color-body);
      line-height: 1.4;
      padding: 0.75rem;
      background: var(--color-background-light);
      border-radius: 4px;
      border-left: 3px solid var(--color-primary-light);
    }
  }

  .card-footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding-top: 1rem;
    border-top: 1px solid var(--color-border-light);

    .status-section {
      .toggle-switch {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        cursor: pointer;

        input[type="checkbox"] {
          display: none;
        }

        .toggle-slider {
          width: 40px;
          height: 20px;
          background: var(--color-border);
          border-radius: 10px;
          position: relative;
          transition: background 0.2s;

          &::before {
            content: '';
            position: absolute;
            width: 16px;
            height: 16px;
            background: white;
            border-radius: 50%;
            top: 2px;
            left: 2px;
            transition: transform 0.2s;
          }
        }

        input:checked + .toggle-slider {
          background: var(--color-success);

          &::before {
            transform: translateX(20px);
          }
        }

        .toggle-label {
          font-size: 0.875rem;
          font-weight: 500;
          color: var(--color-heading);
        }
      }
    }

    .action-buttons {
      display: flex;
      gap: 0.5rem;
    }
  }
}

@media (max-width: 768px) {
  .dataset-card {
    .card-header {
      flex-direction: column;
      align-items: stretch;
    }

    .card-footer {
      flex-direction: column;
      gap: 1rem;
      align-items: stretch;

      .action-buttons {
        justify-content: center;
      }
    }
  }
}
</style>
