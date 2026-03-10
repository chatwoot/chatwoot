<script>
import { mapGetters } from 'vuex';
import PaymentLinksAPI from 'dashboard/api/paymentLinks';
import { useAlert } from 'dashboard/composables';

export default {
  props: {
    show: { type: Boolean, default: false },
    conversationId: { type: Number, default: undefined },
  },
  emits: ['close', 'onSend', 'update:show'],
  setup() {
    const { showAlert } = useAlert();
    return { showAlert };
  },
  data() {
    return {
      amountInput: '',
      description: '',
      saveAsPreset: false,
      presetName: '',
      selectedPresetId: null,
      isSending: false,
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      currentAccount: 'getCurrentAccount',
    }),
    presets() {
      return this.$store.getters['paymentPresets/getPresets'];
    },
    uiFlags() {
      return this.$store.getters['paymentPresets/getUIFlags'];
    },
    localShow: {
      get() {
        return this.show;
      },
      set(value) {
        this.$emit('update:show', value);
      },
    },
    hasHandle() {
      return !!this.currentAccount?.custom_attributes?.infinitepay_handle;
    },
    amountCents() {
      const cleaned = this.amountInput.replace(/[^\d.,]/g, '').replace(',', '.');
      const value = parseFloat(cleaned);
      if (Number.isNaN(value) || value <= 0) return 0;
      return Math.round(value * 100);
    },
    isFormValid() {
      return this.amountCents > 0 && this.description.trim().length > 0;
    },
  },
  watch: {
    show(newVal) {
      if (newVal) {
        this.$store.dispatch('paymentPresets/get');
      }
    },
  },
  methods: {
    selectPreset(preset) {
      this.selectedPresetId = preset.id;
      this.amountInput = (preset.amount_cents / 100).toFixed(2);
      this.description = preset.description;
    },
    clearPresetSelection() {
      this.selectedPresetId = null;
    },
    async deletePreset(presetId) {
      try {
        await this.$store.dispatch('paymentPresets/delete', presetId);
        this.showAlert(this.$t('PAYMENT_LINK.PRESET_DELETED'));
        if (this.selectedPresetId === presetId) {
          this.selectedPresetId = null;
          this.amountInput = '';
          this.description = '';
        }
      } catch (error) {
        this.showAlert(this.$t('PAYMENT_LINK.PRESET_DELETE_ERROR'));
      }
    },
    async onSend() {
      if (!this.isFormValid || this.isSending) return;

      this.isSending = true;
      try {
        if (this.saveAsPreset && this.presetName.trim()) {
          await this.$store.dispatch('paymentPresets/create', {
            payment_preset: {
              name: this.presetName.trim(),
              amount_cents: this.amountCents,
              description: this.description.trim(),
            },
          });
        }

        await PaymentLinksAPI.create({
          conversation_id: this.conversationId,
          amount_cents: this.amountCents,
          description: this.description.trim(),
        });

        this.showAlert(this.$t('PAYMENT_LINK.SENT'));
        this.$emit('onSend');
        this.onClose();
      } catch (error) {
        const msg =
          error?.response?.data?.error || this.$t('PAYMENT_LINK.SEND_ERROR');
        this.showAlert(msg);
      } finally {
        this.isSending = false;
      }
    },
    onClose() {
      this.resetForm();
      this.$emit('close');
    },
    resetForm() {
      this.amountInput = '';
      this.description = '';
      this.saveAsPreset = false;
      this.presetName = '';
      this.selectedPresetId = null;
    },
  },
};
</script>

<template>
  <woot-modal v-model:show="localShow" :on-close="onClose" size="modal-big">
    <woot-modal-header
      :header-title="$t('PAYMENT_LINK.MODAL.TITLE')"
      :header-content="$t('PAYMENT_LINK.MODAL.SUBTITLE')"
    />
    <div class="flex flex-col gap-4 p-6">
      <div
        v-if="!hasHandle"
        class="p-3 text-sm rounded-lg bg-n-amber-2 text-n-amber-11"
      >
        {{ $t('PAYMENT_LINK.MODAL.NO_HANDLE') }}
      </div>

      <template v-else>
        <!-- Presets (Favorites) -->
        <div v-if="presets.length > 0" class="flex flex-col gap-2">
          <label class="text-xs font-medium text-n-slate-11">
            {{ $t('PAYMENT_LINK.MODAL.PRESETS_TITLE') }}
          </label>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="preset in presets"
              :key="preset.id"
              class="group flex items-center gap-1.5 px-3 py-1.5 text-sm rounded-lg border transition-colors"
              :class="
                selectedPresetId === preset.id
                  ? 'border-n-blue-7 bg-n-blue-3 text-n-blue-11'
                  : 'border-n-slate-6 bg-n-slate-2 text-n-slate-11 hover:bg-n-slate-3'
              "
              @click="selectPreset(preset)"
            >
              <span>{{ preset.name }}</span>
              <span class="text-xs opacity-60">
                R$ {{ (preset.amount_cents / 100).toFixed(2) }}
              </span>
              <span
                class="hidden ml-1 cursor-pointer group-hover:inline text-n-red-9 hover:text-n-red-11"
                @click.stop="deletePreset(preset.id)"
              >
                &times;
              </span>
            </button>
          </div>
        </div>

        <!-- Amount -->
        <label class="flex flex-col gap-1">
          <span class="text-xs font-medium text-n-slate-11">
            {{ $t('PAYMENT_LINK.MODAL.AMOUNT_LABEL') }}
          </span>
          <input
            v-model="amountInput"
            type="text"
            inputmode="decimal"
            :placeholder="$t('PAYMENT_LINK.MODAL.AMOUNT_PLACEHOLDER')"
            class="w-full px-3 py-2 text-sm border rounded-lg border-n-slate-6 bg-n-slate-1 text-n-slate-12 focus:border-n-blue-7 focus:outline-none"
            @input="clearPresetSelection"
          />
        </label>

        <!-- Description -->
        <label class="flex flex-col gap-1">
          <span class="text-xs font-medium text-n-slate-11">
            {{ $t('PAYMENT_LINK.MODAL.DESCRIPTION_LABEL') }}
          </span>
          <input
            v-model="description"
            type="text"
            :placeholder="$t('PAYMENT_LINK.MODAL.DESCRIPTION_PLACEHOLDER')"
            class="w-full px-3 py-2 text-sm border rounded-lg border-n-slate-6 bg-n-slate-1 text-n-slate-12 focus:border-n-blue-7 focus:outline-none"
            @input="clearPresetSelection"
          />
        </label>

        <!-- Save as favorite -->
        <div class="flex flex-col gap-2">
          <label class="flex items-center gap-2 cursor-pointer">
            <input
              v-model="saveAsPreset"
              type="checkbox"
              class="accent-n-blue-9"
            />
            <span class="text-sm text-n-slate-11">
              {{ $t('PAYMENT_LINK.MODAL.SAVE_PRESET') }}
            </span>
          </label>
          <input
            v-if="saveAsPreset"
            v-model="presetName"
            type="text"
            :placeholder="$t('PAYMENT_LINK.MODAL.PRESET_NAME')"
            class="w-full px-3 py-2 text-sm border rounded-lg border-n-slate-6 bg-n-slate-1 text-n-slate-12 focus:border-n-blue-7 focus:outline-none"
          />
        </div>

        <!-- Send button -->
        <div class="flex justify-end gap-2 pt-2">
          <button
            class="px-4 py-2 text-sm rounded-lg text-n-slate-11 bg-n-slate-3 hover:bg-n-slate-4"
            @click="onClose"
          >
            {{ $t('PAYMENT_LINK.MODAL.CANCEL') }}
          </button>
          <button
            :disabled="!isFormValid || isSending"
            class="px-4 py-2 text-sm font-medium text-white rounded-lg bg-n-blue-9 hover:bg-n-blue-10 disabled:opacity-50 disabled:cursor-not-allowed"
            @click="onSend"
          >
            {{ isSending ? $t('PAYMENT_LINK.MODAL.SENDING') : $t('PAYMENT_LINK.MODAL.SEND') }}
          </button>
        </div>
      </template>
    </div>
  </woot-modal>
</template>
