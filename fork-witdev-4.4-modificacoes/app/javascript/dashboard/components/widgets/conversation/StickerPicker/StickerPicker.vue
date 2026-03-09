<script>
import { debounce } from '@chatwoot/utils';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';

export default {
  name: 'StickerPicker',
  props: {
    conversationId: {
      type: [String, Number],
      required: true,
    },
    isVisible: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['close', 'stickerSelected'],
  data() {
    return {
      activeTab: 'library',
      searchTerm: '',
      stickers: [],
      isLoading: false,
      isSearching: false,
      error: null,
      customPacks: [],
      isEditMode: false,
      selectedStickers: [],
      isDeleting: false,
      tabs: [
        {
          key: 'library',
          label: this.$t('CONVERSATION.STICKER_PICKER.TABS.LIBRARY'),
          icon: 'i-ph-sticker',
        },
        {
          key: 'trending',
          label: this.$t('CONVERSATION.STICKER_PICKER.TABS.TRENDING'),
        },
        {
          key: 'search',
          label: this.$t('CONVERSATION.STICKER_PICKER.TABS.SEARCH'),
        },
        {
          key: 'recent',
          label: this.$t('CONVERSATION.STICKER_PICKER.TABS.RECENT'),
        },
      ],
    };
  },
  computed: {
    ...mapGetters({
      currentAccount: 'getCurrentAccount',
    }),
    emptyStateMessage() {
      switch (this.activeTab) {
        case 'library':
          return this.$t('CONVERSATION.STICKER_PICKER.EMPTY_STATES.LIBRARY');
        case 'trending':
          return this.$t('CONVERSATION.STICKER_PICKER.EMPTY_STATES.TRENDING');
        case 'search':
          return this.searchTerm
            ? this.$t('CONVERSATION.STICKER_PICKER.EMPTY_STATES.SEARCH_RESULTS')
            : this.$t('CONVERSATION.STICKER_PICKER.EMPTY_STATES.SEARCH_PROMPT');
        case 'recent':
          return this.$t('CONVERSATION.STICKER_PICKER.EMPTY_STATES.RECENT');
        default:
          return this.$t('CONVERSATION.STICKER_PICKER.EMPTY_STATES.DEFAULT');
      }
    },
    canEdit() {
      // Only allow editing for custom stickers (library tab and custom packs)
      return this.activeTab === 'library' || this.activeTab.startsWith('pack_');
    },
    selectedStickersCount() {
      return this.selectedStickers.length;
    },
    // Computed para forçar reatividade na verificação de seleção
    selectedStickerIds() {
      return this.selectedStickers.map(s => s.id);
    },
  },
  watch: {
    isVisible(newValue) {
      if (newValue) {
        this.loadInitialData();
      }
    },
    activeTab() {
      this.loadTabData();
      this.exitEditMode();
    },
  },
  created() {
    this.debouncedSearch = debounce(this.performSearch, 500);
  },
  mounted() {
    if (this.isVisible) {
      this.loadInitialData();
    }
  },
  methods: {
    async loadInitialData() {
      await this.loadCustomPacks();
      await this.loadTabData();
    },
    async loadCustomPacks() {
      try {
        const response = await window.axios.get(
          `/api/v1/accounts/${this.currentAccount.id}/stickers`,
          {
            params: { provider: 'custom', pack_name: null },
          }
        );

        // Group custom stickers by pack
        const packGroups = {};
        response.data.stickers.forEach(sticker => {
          const stickerPackName = sticker.meta?.sticker_pack || 'Default';
          if (!packGroups[stickerPackName]) {
            packGroups[stickerPackName] = [];
          }
          packGroups[stickerPackName].push(sticker);
        });

        // Add custom pack tabs
        this.customPacks = Object.keys(packGroups).map(stickerPackName => ({
          key: `pack_${stickerPackName}`,
          label: stickerPackName,
          stickers: packGroups[stickerPackName],
        }));

        // Add custom pack tabs to tabs array with shorter labels
        this.tabs = [
          {
            key: 'library',
            label: this.$t('CONVERSATION.STICKER_PICKER.TABS.LIBRARY'),
            icon: 'i-ph-sticker',
          },
          {
            key: 'trending',
            label: this.$t('CONVERSATION.STICKER_PICKER.TABS.TRENDING'),
          },
          {
            key: 'search',
            label: this.$t('CONVERSATION.STICKER_PICKER.TABS.SEARCH'),
          },
          {
            key: 'recent',
            label: this.$t('CONVERSATION.STICKER_PICKER.TABS.RECENT'),
          },
          ...this.customPacks.map(pack => ({
            ...pack,
            label:
              pack.label.length > 8
                ? pack.label.substring(0, 8) + '...'
                : pack.label,
          })),
        ];
      } catch (error) {
        // Failed to load custom packs
      }
    },
    async loadTabData() {
      this.error = null;
      this.isLoading = true;

      try {
        let response;

        if (this.activeTab === 'library') {
          response = await window.axios.get(
            `/api/v1/accounts/${this.currentAccount.id}/stickers`,
            {
              params: { provider: 'custom' },
            }
          );
        } else if (this.activeTab === 'trending') {
          response = await window.axios.get(
            `/api/v1/accounts/${this.currentAccount.id}/stickers`,
            {
              params: { provider: 'giphy' },
            }
          );
        } else if (this.activeTab === 'recent') {
          response = await window.axios.get(
            `/api/v1/accounts/${this.currentAccount.id}/stickers`,
            {
              params: { provider: 'recent' },
            }
          );
        } else if (this.activeTab.startsWith('pack_')) {
          const pack = this.customPacks.find(p => p.key === this.activeTab);
          this.stickers = pack ? pack.stickers : [];
          this.isLoading = false;
          return;
        }

        // Handle API response with error checking
        if (response?.data?.error) {
          this.handleApiError(response.data);
          return;
        }

        this.stickers = response?.data?.stickers || [];

        // If no stickers and it's trending tab, show helpful message
        if (this.stickers.length === 0 && this.activeTab === 'trending') {
          // No trending stickers available - this might be due to missing Giphy API key
        }
      } catch (error) {
        // Failed to load stickers
        this.handleLoadError(error);
      } finally {
        this.isLoading = false;
      }
    },
    async performSearch() {
      if (!this.searchTerm.trim()) {
        this.stickers = [];
        return;
      }

      this.isSearching = true;
      this.error = null;

      try {
        const response = await window.axios.get(
          `/api/v1/accounts/${this.currentAccount.id}/stickers`,
          {
            params: {
              provider: 'giphy',
              search_term: this.searchTerm.trim(),
            },
          }
        );

        // Handle API response with error checking
        if (response?.data?.error) {
          this.handleApiError(response.data);
          return;
        }

        this.stickers = response.data.stickers || [];
      } catch (error) {
        // Search failed
        this.handleSearchError(error);
      } finally {
        this.isSearching = false;
      }
    },
    switchTab(tabKey) {
      this.activeTab = tabKey;
      this.searchTerm = '';
      this.error = null;
    },
    async selectSticker(sticker) {
      // If in edit mode, toggle selection instead of sending sticker
      if (this.isEditMode) {
        this.toggleStickerSelection(sticker);
        return;
      }

      // Close modal immediately for optimistic UI
      this.closeModal();
      this.$emit('stickerSelected', sticker);

      try {
        const response = await window.axios.post(
          `/api/v1/accounts/${this.currentAccount.id}/stickers/send_sticker`,
          {
            conversation_id: this.conversationId,
            sticker: {
              id: sticker.id,
              url: sticker.url,
              alt: sticker.alt,
              provider: sticker.provider,
            },
          }
        );

        if (response.data.success) {
          // Success is handled by backend message status updates via websocket
          // No need to show success alert as the message will appear with proper status
        } else {
          this.handleSendStickerError(response.data);
        }
      } catch (error) {
        // Failed to send sticker - show error to user
        this.handleSendStickerError(
          error.response?.data || { error: 'UNKNOWN_ERROR' }
        );
      }
    },
    enterEditMode() {
      this.isEditMode = true;
      this.selectedStickers = [];
    },
    exitEditMode() {
      this.isEditMode = false;
      this.selectedStickers = [];
    },
    toggleStickerSelection(sticker) {
      const index = this.selectedStickers.findIndex(s => s.id === sticker.id);
      if (index > -1) {
        this.selectedStickers.splice(index, 1);
      } else {
        this.selectedStickers.push(sticker);
      }
    },
    isStickerSelected(sticker) {
      return this.selectedStickerIds.includes(sticker.id);
    },
    async deleteSelectedStickers() {
      if (this.selectedStickers.length === 0) return;

      this.isDeleting = true;

      // Save count before clearing selection
      const deletedCount = this.selectedStickers.length;

      try {
        const deletePromises = this.selectedStickers.map(sticker =>
          window.axios.delete(
            `/api/v1/accounts/${this.currentAccount.id}/stickers/${sticker.id}`
          )
        );

        await Promise.all(deletePromises);

        // Remove deleted stickers from local arrays
        this.stickers = this.stickers.filter(
          sticker => !this.selectedStickers.some(s => s.id === sticker.id)
        );

        // Update custom packs if needed
        if (this.activeTab.startsWith('pack_')) {
          const pack = this.customPacks.find(p => p.key === this.activeTab);
          if (pack) {
            pack.stickers = pack.stickers.filter(
              sticker => !this.selectedStickers.some(s => s.id === sticker.id)
            );
          }
        }

        this.exitEditMode();

        useAlert(
          this.$t('CONVERSATION.STICKER_PICKER.STICKERS_DELETED_SUCCESS', {
            count: deletedCount,
          })
        );
      } catch (error) {
        this.handleDeleteError(error);
      } finally {
        this.isDeleting = false;
      }
    },
    closeModal() {
      this.$emit('close');
    },
    retryLoad() {
      this.loadTabData();
    },
    handleImageError(event) {
      // Hide broken images
      event.target.style.display = 'none';
    },
    handleApiError(errorData) {
      const errorCode = errorData.error_code || errorData.error;
      const userMessage = errorData.user_message || errorData.message;

      switch (errorCode) {
        case 'GIPHY_API_KEY_MISSING':
          this.error = this.$t(
            'CONVERSATION.STICKER_PICKER.ERRORS.GIPHY_NOT_CONFIGURED'
          );
          break;
        case 'GIPHY_RATE_LIMIT':
          this.error = this.$t('CONVERSATION.STICKER_PICKER.ERRORS.RATE_LIMIT');
          break;
        case 'GIPHY_UNAVAILABLE':
          this.error = this.$t(
            'CONVERSATION.STICKER_PICKER.ERRORS.SERVICE_UNAVAILABLE'
          );
          break;
        case 'CUSTOM_STICKERS_ERROR':
          this.error = this.$t(
            'CONVERSATION.STICKER_PICKER.ERRORS.CUSTOM_STICKERS_FAILED'
          );
          break;
        default:
          this.error =
            userMessage ||
            this.$t('CONVERSATION.STICKER_PICKER.ERRORS.LOAD_FAILED');
      }
    },
    handleLoadError(error) {
      if (error.response?.status === 503) {
        this.error = this.$t(
          'CONVERSATION.STICKER_PICKER.ERRORS.SERVICE_UNAVAILABLE'
        );
      } else if (error.response?.status === 429) {
        this.error = this.$t('CONVERSATION.STICKER_PICKER.ERRORS.RATE_LIMIT');
      } else if (error.response?.status >= 500) {
        this.error = this.$t('CONVERSATION.STICKER_PICKER.ERRORS.SERVER_ERROR');
      } else if (error.code === 'NETWORK_ERROR' || !navigator.onLine) {
        this.error = this.$t(
          'CONVERSATION.STICKER_PICKER.ERRORS.NETWORK_ERROR'
        );
      } else {
        this.error = this.$t('CONVERSATION.STICKER_PICKER.ERRORS.LOAD_FAILED');
      }
    },
    handleSearchError(error) {
      if (error.response?.status === 503) {
        this.error = this.$t(
          'CONVERSATION.STICKER_PICKER.ERRORS.SEARCH_SERVICE_UNAVAILABLE'
        );
      } else if (error.response?.status === 429) {
        this.error = this.$t(
          'CONVERSATION.STICKER_PICKER.ERRORS.SEARCH_RATE_LIMIT'
        );
      } else if (error.code === 'NETWORK_ERROR' || !navigator.onLine) {
        this.error = this.$t(
          'CONVERSATION.STICKER_PICKER.ERRORS.NETWORK_ERROR'
        );
      } else {
        this.error = this.$t(
          'CONVERSATION.STICKER_PICKER.ERRORS.SEARCH_FAILED'
        );
      }
    },
    handleSendStickerError(errorData) {
      const errorCode = errorData.error_code || errorData.error;
      const userMessage = errorData.user_message || errorData.message;

      let alertMessage;

      switch (errorCode) {
        case 'INVALID_CHANNEL_TYPE':
          alertMessage = this.$t(
            'CONVERSATION.STICKER_PICKER.ERRORS.INVALID_CHANNEL'
          );
          break;
        case 'CONVERSATION_NOT_FOUND':
          alertMessage = this.$t(
            'CONVERSATION.STICKER_PICKER.ERRORS.CONVERSATION_NOT_FOUND'
          );
          break;
        case 'MEDIA_UPLOAD_FAILED':
          alertMessage = this.$t(
            'CONVERSATION.STICKER_PICKER.ERRORS.UPLOAD_FAILED'
          );
          break;
        case 'WHATSAPP_RATE_LIMIT':
          alertMessage = this.$t(
            'CONVERSATION.STICKER_PICKER.ERRORS.WHATSAPP_RATE_LIMIT'
          );
          break;
        case 'WHATSAPP_INVALID_MEDIA':
          alertMessage = this.$t(
            'CONVERSATION.STICKER_PICKER.ERRORS.INVALID_STICKER_FORMAT'
          );
          break;
        case 'WHATSAPP_AUTH_ERROR':
          alertMessage = this.$t(
            'CONVERSATION.STICKER_PICKER.ERRORS.WHATSAPP_AUTH_ERROR'
          );
          break;
        case 'NETWORK_ERROR':
          alertMessage = this.$t(
            'CONVERSATION.STICKER_PICKER.ERRORS.NETWORK_ERROR'
          );
          break;
        case 'TIMEOUT_ERROR':
          alertMessage = this.$t(
            'CONVERSATION.STICKER_PICKER.ERRORS.TIMEOUT_ERROR'
          );
          break;
        default:
          alertMessage =
            userMessage ||
            this.$t('CONVERSATION.STICKER_PICKER.ERRORS.SEND_FAILED');
      }

      useAlert(alertMessage);
    },
    handleDeleteError(error) {
      let alertMessage;

      if (error.response?.status === 403) {
        alertMessage = this.$t(
          'CONVERSATION.STICKER_PICKER.ERRORS.DELETE_PERMISSION_DENIED'
        );
      } else if (error.response?.status === 404) {
        alertMessage = this.$t(
          'CONVERSATION.STICKER_PICKER.ERRORS.STICKER_NOT_FOUND'
        );
      } else if (error.code === 'NETWORK_ERROR' || !navigator.onLine) {
        alertMessage = this.$t(
          'CONVERSATION.STICKER_PICKER.ERRORS.NETWORK_ERROR'
        );
      } else {
        alertMessage = this.$t(
          'CONVERSATION.STICKER_PICKER.ERRORS.DELETE_FAILED'
        );
      }

      useAlert(alertMessage);
    },
  },
};
</script>

<template>
  <div v-if="isVisible" class="sticker-picker-modal">
    <!-- Modal Overlay -->
    <div
      class="fixed inset-0 z-50 flex items-end justify-center bg-black bg-opacity-50"
      @click="closeModal"
    >
      <div
        class="bg-white rounded-t-lg shadow-lg w-full max-w-md h-96 flex flex-col"
        @click.stop
      >
        <!-- Header with Tabs -->
        <div
          class="flex border-b border-gray-200 bg-gray-50 rounded-t-lg overflow-x-auto"
        >
          <!-- Tabs -->
          <div class="flex flex-1 overflow-x-auto">
            <button
              v-for="tab in tabs"
              :key="tab.key"
              class="flex-shrink-0 py-3 px-3 text-xs font-medium text-center border-b-2 transition-colors flex items-center justify-center gap-1 min-w-0"
              :class="[
                activeTab === tab.key
                  ? 'border-blue-500 text-blue-600 bg-white'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:bg-gray-100',
              ]"
              @click="switchTab(tab.key)"
            >
              <i
                v-if="tab.icon"
                :class="tab.icon"
                class="text-xs flex-shrink-0"
              />
              <span class="truncate">{{ tab.label }}</span>
            </button>
          </div>

          <!-- Edit/Cancel Button -->
          <div
            v-if="canEdit && stickers.length > 0"
            class="flex-shrink-0 px-3 py-3"
          >
            <button
              v-if="!isEditMode"
              class="text-gray-600 hover:text-gray-800 transition-colors"
              :title="$t('CONVERSATION.STICKER_PICKER.EDIT_MODE')"
              @click="enterEditMode"
            >
              <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path
                  d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"
                />
              </svg>
            </button>
            <button
              v-else
              class="text-blue-600 hover:text-blue-800 transition-colors text-sm font-medium"
              @click="exitEditMode"
            >
              {{ $t('CONVERSATION.STICKER_PICKER.CANCEL') }}
            </button>
          </div>
        </div>

        <!-- Search Input (only for search tab) -->
        <div v-if="activeTab === 'search'" class="p-3 border-b border-gray-200">
          <div class="relative">
            <input
              v-model="searchTerm"
              type="text"
              :placeholder="
                $t('CONVERSATION.STICKER_PICKER.SEARCH_PLACEHOLDER')
              "
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              @keyup.enter="performSearch"
              @input="debouncedSearch"
            />
            <div v-if="isSearching" class="absolute right-3 top-2.5">
              <div
                class="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-500"
              />
            </div>
          </div>
        </div>

        <!-- Content Area -->
        <div class="flex-1 overflow-y-auto p-3">
          <!-- Loading State -->
          <div v-if="isLoading" class="flex items-center justify-center h-full">
            <div class="text-center">
              <div
                class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500 mx-auto mb-2"
              />
              <p class="text-gray-500 text-sm">
                {{ $t('CONVERSATION.STICKER_PICKER.LOADING') }}
              </p>
            </div>
          </div>

          <!-- Error State -->
          <div
            v-else-if="error"
            class="flex items-center justify-center h-full"
          >
            <div class="text-center">
              <div class="text-red-500 mb-2">
                <i class="i-ph-warning-circle text-2xl" />
              </div>
              <p class="text-gray-600 text-sm">{{ error }}</p>
              <button
                class="mt-2 px-3 py-1 bg-blue-500 text-white text-xs rounded hover:bg-blue-600"
                @click="retryLoad"
              >
                {{ $t('CONVERSATION.STICKER_PICKER.RETRY') }}
              </button>
            </div>
          </div>

          <!-- Empty State -->
          <div
            v-else-if="stickers.length === 0"
            class="flex items-center justify-center h-full"
          >
            <div class="text-center">
              <div class="text-gray-400 mb-2">
                <i class="i-ph-smiley-sad text-2xl" />
              </div>
              <p class="text-gray-500 text-sm">{{ emptyStateMessage }}</p>
            </div>
          </div>

          <!-- Stickers Grid -->
          <div v-else class="grid grid-cols-4 gap-2">
            <div
              v-for="sticker in stickers"
              :key="sticker.id"
              class="aspect-square bg-gray-100 rounded-lg overflow-hidden cursor-pointer hover:bg-gray-200 transition-colors relative"
              @click="selectSticker(sticker)"
            >
              <img
                :src="sticker.url"
                :alt="sticker.alt"
                class="w-full h-full object-cover"
                @error="handleImageError"
              />

              <!-- Selection Circle (only in edit mode) -->
              <div
                v-if="isEditMode"
                class="absolute top-2 right-2 w-6 h-6 rounded-full border-2 shadow-lg flex items-center justify-center transition-all duration-200 z-10"
                :class="[
                  isStickerSelected(sticker)
                    ? 'bg-green-500 border-green-500 scale-110'
                    : 'bg-white border-gray-400 hover:border-gray-600',
                ]"
              >
                <!-- Check Mark -->
                <svg
                  v-if="isStickerSelected(sticker)"
                  class="w-4 h-4 text-white"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path
                    fill-rule="evenodd"
                    d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
            </div>
          </div>
        </div>

        <!-- Edit Mode Footer -->
        <div
          v-if="isEditMode && selectedStickersCount > 0"
          class="flex items-center justify-between p-3 border-t border-gray-200 bg-gray-50"
        >
          <span class="text-sm text-gray-600">
            {{
              $t('CONVERSATION.STICKER_PICKER.SELECTED_COUNT', {
                count: selectedStickersCount,
              })
            }}
          </span>
          <button
            :disabled="isDeleting"
            class="flex items-center gap-2 px-3 py-1.5 bg-red-500 text-white text-sm rounded hover:bg-red-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            @click="deleteSelectedStickers"
          >
            <!-- Loading spinner when deleting -->
            <div
              v-if="isDeleting"
              class="animate-spin rounded-full w-3 h-3 border-2 border-white border-t-transparent"
            />
            <!-- Trash icon -->
            <svg v-else class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
              <path
                fill-rule="evenodd"
                d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z"
                clip-rule="evenodd"
              />
            </svg>
            {{
              isDeleting
                ? $t('CONVERSATION.STICKER_PICKER.DELETING')
                : $t('CONVERSATION.STICKER_PICKER.DELETE')
            }}
          </button>
        </div>
      </div>
    </div>
  </div>
  <div v-else />
</template>

<style scoped>
.sticker-picker-modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 1000;
}

/* Custom scrollbar for stickers grid */
.sticker-picker-modal ::-webkit-scrollbar {
  width: 6px;
}

.sticker-picker-modal ::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 3px;
}

.sticker-picker-modal ::-webkit-scrollbar-thumb {
  background: #c1c1c1;
  border-radius: 3px;
}

.sticker-picker-modal ::-webkit-scrollbar-thumb:hover {
  background: #a8a8a8;
}
</style>
