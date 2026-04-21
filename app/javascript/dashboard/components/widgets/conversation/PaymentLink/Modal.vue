<script>
import { mapGetters } from 'vuex';
import PaymentLinksAPI from 'dashboard/api/paymentLinks';
import { useAlert } from 'dashboard/composables';

function formatBRL(cents) {
  return (cents / 100).toLocaleString('pt-BR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
}

export default {
  props: {
    show: { type: Boolean, default: false },
    conversationId: { type: Number, default: undefined },
  },
  emits: ['close', 'onSend', 'update:show'],
  setup() {
    return { showAlert: useAlert };
  },
  data() {
    return {
      amountCentsRaw: 0,
      description: '',
      saveAsPreset: false,
      presetName: '',
      selectedPresetId: null,
      selectedInteractiveTemplateId: null,
      isSending: false,
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
    currentAccount() {
      return this.$store.getters['accounts/getAccount'](this.accountId);
    },
    presets() {
      return this.$store.getters['paymentPresets/getPresets'];
    },
    uiFlags() {
      return this.$store.getters['paymentPresets/getUIFlags'];
    },
    interactiveTemplates() {
      return this.$store.getters['whatsappInteractiveTemplates/getTemplates'];
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
      return this.amountCentsRaw;
    },
    displayAmount() {
      return `R$ ${formatBRL(this.amountCentsRaw)}`;
    },
    isFormValid() {
      return this.amountCents > 0 && this.description.trim().length > 0;
    },
  },
  watch: {
    show(newVal) {
      if (newVal) {
        this.$store.dispatch('paymentPresets/get');
        this.$store.dispatch('whatsappInteractiveTemplates/get');
        this.$nextTick(() => {
          this.$refs.amountInput?.focus();
        });
      }
    },
  },
  methods: {
    handleAmountKeydown(event) {
      if ([8, 46, 9, 27, 13].includes(event.keyCode)) {
        if (event.keyCode === 8) {
          event.preventDefault();
          this.amountCentsRaw = Math.floor(this.amountCentsRaw / 10);
          this.clearPresetSelection();
        }
        return;
      }
      const digit = event.key;
      if (!/^\d$/.test(digit)) {
        event.preventDefault();
        return;
      }
      event.preventDefault();
      const next = this.amountCentsRaw * 10 + parseInt(digit, 10);
      if (next <= 99999999) {
        this.amountCentsRaw = next;
      }
      this.clearPresetSelection();
    },
    handleAmountPaste(event) {
      event.preventDefault();
      const text = (event.clipboardData || window.clipboardData).getData(
        'text'
      );
      const digits = text.replace(/\D/g, '');
      if (digits.length > 0) {
        const val = parseInt(digits, 10);
        if (val <= 99999999) {
          this.amountCentsRaw = val;
        }
      }
    },
    selectPreset(preset) {
      this.selectedPresetId = preset.id;
      this.amountCentsRaw = preset.amount_cents;
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
          this.amountCentsRaw = 0;
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
          whatsapp_interactive_template_id: this.selectedInteractiveTemplateId,
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
      this.amountCentsRaw = 0;
      this.description = '';
      this.saveAsPreset = false;
      this.presetName = '';
      this.selectedPresetId = null;
      this.selectedInteractiveTemplateId = null;
    },
    formatBRL,
  },
};
</script>

<template>
  <woot-modal v-model:show="localShow" :on-close="onClose" size="modal-big">
    <woot-modal-header
      :header-title="$t('PAYMENT_LINK.MODAL.TITLE')"
      :header-content="$t('PAYMENT_LINK.MODAL.SUBTITLE')"
    />
    <div class="flex flex-col gap-4 p-6 overflow-y-auto max-h-[75vh]">
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
                {{ `R$ ${(preset.amount_cents / 100).toFixed(2)}` }}
              </span>
              <span
                class="hidden ml-1 cursor-pointer group-hover:inline text-n-red-9 hover:text-n-red-11"
                @click.stop="deletePreset(preset.id)"
              >
                {{ '×' }}
              </span>
            </button>
          </div>
        </div>

        <!-- Amount (currency mask) -->
        <label class="flex flex-col gap-1">
          <span class="text-xs font-medium text-n-slate-11">
            {{ $t('PAYMENT_LINK.MODAL.AMOUNT_LABEL') }}
          </span>
          <input
            ref="amountInput"
            :value="displayAmount"
            type="text"
            inputmode="numeric"
            class="w-full px-3 py-2.5 text-xl font-bold tracking-wide border rounded-lg border-n-slate-6 bg-n-slate-1 text-n-slate-12 focus:border-n-blue-7 focus:outline-none"
            @keydown="handleAmountKeydown"
            @paste="handleAmountPaste"
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

        <label class="flex flex-col gap-1">
          <span class="text-xs font-medium text-n-slate-11">
            {{ $t('PAYMENT_LINK.MODAL.INTERACTIVE_TEMPLATE_LABEL') }}
          </span>
          <select
            v-model="selectedInteractiveTemplateId"
            class="w-full px-3 py-2 text-sm border rounded-lg border-n-slate-6 bg-n-slate-1 text-n-slate-12 focus:border-n-blue-7 focus:outline-none"
          >
            <option :value="null">
              {{ $t('PAYMENT_LINK.MODAL.INTERACTIVE_TEMPLATE_NONE') }}
            </option>
            <option
              v-for="template in interactiveTemplates"
              :key="template.id"
              :value="template.id"
            >
              {{ template.name }} ({{
                template.template_type === 'rich_text'
                  ? 'Link no corpo'
                  : 'CTA'
              }})
            </option>
          </select>
          <span class="text-xs text-n-slate-9">
            {{ $t('PAYMENT_LINK.MODAL.INTERACTIVE_TEMPLATE_HINT') }}
          </span>
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

        <!-- Checkout note -->
        <div
          class="flex items-start gap-2 p-2 rounded-lg text-[11px] bg-n-slate-2 text-n-slate-9"
        >
          <!-- eslint-disable-next-line vue/no-bare-strings-in-template -->
          <span class="mt-px shrink-0" aria-hidden="true">&#9432;</span>
          <span>{{ $t('PAYMENT_LINK.MODAL.CHECKOUT_NOTE') }}</span>
        </div>

        <!-- Actions -->
        <div class="flex justify-end gap-2 pt-1">
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
            {{
              isSending
                ? $t('PAYMENT_LINK.MODAL.SENDING')
                : $t('PAYMENT_LINK.MODAL.SEND')
            }}
          </button>
        </div>
      </template>
    </div>
  </woot-modal>
</template>
