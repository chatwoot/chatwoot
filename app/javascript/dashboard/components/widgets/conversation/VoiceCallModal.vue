<script>
import { useToast } from '@/dashboard/helper/toast';
import Modal from '@/dashboard/components/Modal.vue';
import FluentIcon from '@/shared/components/FluentIcon/DashboardIcon.vue';
import Wavoip from 'wavoip-api';

export default {
  components: {
    Modal,
    FluentIcon,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    currentChat: {
      type: Object,
      required: true,
    },
  },
  emits: ['close'],
  setup() {
    const toast = useToast();
    return { toast };
  },
  data() {
    return {
      displayNumber: '',
      isCallActive: false,
      wavoip: null,
      wavoipInstance: null,
      dialpadItems: [
        { digit: '1', letters: '', key: '1' },
        { digit: '2', letters: 'ABC', key: '2' },
        { digit: '3', letters: 'DEF', key: '3' },
        { digit: '4', letters: 'GHI', key: '4' },
        { digit: '5', letters: 'JKL', key: '5' },
        { digit: '6', letters: 'MNO', key: '6' },
        { digit: '7', letters: 'PQRS', key: '7' },
        { digit: '8', letters: 'TUV', key: '8' },
        { digit: '9', letters: 'WXYZ', key: '9' },
        { digit: '*', letters: '', key: '*' },
        { digit: '0', letters: '+', key: '0' },
        { digit: '#', letters: '', key: '#' },
      ],
    };
  },
  computed: {
    contactName() {
      return (
        this.currentChat?.meta?.sender?.name ||
        this.$t('CONVERSATION.UNKNOWN_CALLER')
      );
    },
    phoneNumber() {
      return this.currentChat?.meta?.sender?.phone_number || '';
    },
  },
  mounted() {
    this.wavoip = new Wavoip();
  },
  beforeUnmount() {
    if (this.wavoipInstance?.socket) {
      this.wavoipInstance.socket.disconnect();
    }
  },
  methods: {
    handleKeydown(event) {
      if (!this.show) return;

      const key = event.key;
      // Números de 0-9
      if (/^[0-9]$/.test(key)) {
        this.appendNumber(key);
      }
      // Teclas especiais
      switch (key) {
        case '#':
          this.appendNumber('#');
          break;
        case '*':
          this.appendNumber('*');
          break;
        case '+':
          this.appendNumber('0');
          break;
        case 'Backspace':
          this.deleteLastNumber();
          break;
        case 'Delete':
          this.clearNumber();
          break;
        case 'Enter':
          if (!this.isCallActive) {
            this.startCall();
          } else {
            this.endCall();
          }
          break;
        default:
          break;
      }
    },
    onClose() {
      if (this.isCallActive) {
        this.endCall();
      }
      this.$emit('close');
    },
    appendNumber(number) {
      if (number) {
        this.displayNumber += number;
      }
    },
    clearNumber() {
      this.displayNumber = '';
    },
    deleteLastNumber() {
      this.displayNumber = this.displayNumber.slice(0, -1);
    },
    async startCall() {
      if (this.isCallActive) return;

      try {
        this.isCallActive = true;

        if (!this.wavoip) {
          this.wavoip = new Wavoip();
        }

        this.wavoipInstance = await this.wavoip.connect(
          import.meta.env.VITE_WAVOIP_TOKEN
        );

        if (!this.wavoipInstance) {
          throw new Error('Falha ao conectar com Wavoip');
        }

        if (!this.wavoipInstance.socket) {
          throw new Error('Socket não inicializado');
        }

        this.wavoipInstance.socket.on('connect', () => {
          const number = this.displayNumber || this.phoneNumber;
          if (!number) {
            this.isCallActive = false;
            this.toast.error(this.$t('CONVERSATION.NO_NUMBER'));
            return;
          }

          this.wavoipInstance.callStart({
            whatsappid: number,
          });

          this.toast.success(this.$t('CONVERSATION.CALL_STARTED'));
        });

        this.wavoipInstance.socket.on('error', error => {
          this.isCallActive = false;
          this.toast.error(
            `${this.$t('CONVERSATION.CALL_ERROR')}: ${error.message}`
          );
        });

        this.wavoipInstance.socket.on('disconnect', () => {
          this.isCallActive = false;
          this.toast.error(this.$t('CONVERSATION.CALL_DISCONNECTED'));
        });
      } catch (error) {
        this.isCallActive = false;
        this.toast.error(
          `${this.$t('CONVERSATION.CALL_FAILED')}: ${error.message}`
        );
      }
    },
    endCall() {
      try {
        if (this.wavoipInstance?.socket) {
          this.wavoipInstance.socket.disconnect();
        }
      } catch (error) {
        this.toast.error(this.$t('CONVERSATION.END_CALL_ERROR'));
      } finally {
        this.isCallActive = false;
        this.onClose();
      }
    },
  },
};
</script>

<template>
  <Modal
    :show="show"
    :on-close="onClose"
    class="!max-w-[280px] !w-[280px] !inset-0 !m-auto !h-fit"
  >
    <div class="w-[280px] bg-white rounded-lg shadow-lg">
      <div class="p-4">
        <!-- Display Number Section -->
        <div class="text-center mb-8">
          <div class="text-xl font-medium text-gray-800">
            {{ displayNumber || phoneNumber || '+1' }}
          </div>
          <div
            class="flex items-center justify-center gap-1 text-sm text-gray-700 mt-1"
          >
            <span>{{ contactName }}</span>
          </div>
        </div>

        <!-- Dialpad Grid -->
        <div class="grid grid-cols-3 gap-4">
          <button
            v-for="(number, index) in dialpadItems"
            :key="index"
            class="aspect-square rounded-full bg-gray-100 hover:bg-gray-200 transition-colors flex flex-col items-center justify-center"
            @click="appendNumber(number.digit)"
          >
            <span class="text-lg font-medium text-gray-800">{{
              number.digit
            }}</span>
            <span
              v-if="number.letters"
              class="text-[10px] text-gray-700 mt-0.5"
            >
              {{ number.letters }}
            </span>
          </button>
        </div>

        <!-- Action Buttons -->
        <div class="flex justify-between items-center mt-6">
          <button
            class="w-10 h-10 rounded-full hover:bg-gray-100 flex items-center justify-center"
          >
            <FluentIcon icon="chat" class="w-5 h-5 text-gray-600" />
          </button>

          <button
            class="w-14 h-14 rounded-full transition-colors flex items-center justify-center"
            :class="[
              isCallActive
                ? 'bg-red-500 hover:bg-red-600'
                : 'bg-green-500 hover:bg-green-600',
            ]"
            @click="isCallActive ? endCall() : startCall()"
          >
            <FluentIcon
              :icon="isCallActive ? 'dismiss' : 'call'"
              class="w-7 h-7 text-white"
            />
          </button>

          <button
            class="w-10 h-10 rounded-full hover:bg-gray-100 flex items-center justify-center"
            @click="deleteLastNumber"
          >
            <FluentIcon icon="delete" class="w-5 h-5 text-gray-800" />
          </button>
        </div>
      </div>
    </div>
  </Modal>
</template>

<style scoped>
.backdrop-blur-sm {
  backdrop-filter: blur(8px);
}
</style>
