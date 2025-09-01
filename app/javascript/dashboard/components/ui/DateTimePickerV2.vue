<script>
import { ref, computed } from 'vue';
import VueDatePicker from '@vuepic/vue-datepicker';
import '@vuepic/vue-datepicker/dist/main.css';

export default {
  name: 'DateTimePickerV2',
  components: { VueDatePicker },
  props: {
    modelValue: {
      type: [Date, String],
      default: null,
    },
    placeholder: {
      type: String,
      default: 'Selecione data e hora',
    },
    type: {
      type: String,
      default: 'datetime',
      validator: (value) => ['date', 'datetime', 'time'].includes(value),
    },
  },
  emits: ['update:modelValue'],

  setup(props, { emit }) {
    const internalValue = computed({
      get() {
        return props.modelValue;
      },
      set(newValue) {
        // For time mode, convert object to HH:mm string
        if (props.type === 'time' && newValue && typeof newValue === 'object') {
          const hours = String(newValue.hours || 0).padStart(2, '0');
          const minutes = String(newValue.minutes || 0).padStart(2, '0');
          emit('update:modelValue', `${hours}:${minutes}`);
        } else {
          emit('update:modelValue', newValue);
        }
      },
    });

    const pickerConfig = computed(() => {
      const baseConfig = {
        locale: 'pt-BR',
        cancelText: 'Cancelar',
        selectText: 'Confirmar',
        format: 'dd/MM/yyyy HH:mm',
        previewFormat: 'dd/MM/yyyy HH:mm',
        placeholder: props.placeholder,
        autoApply: false,
      };

      switch (props.type) {
        case 'date':
          return {
            ...baseConfig,
            format: 'dd/MM/yyyy',
            previewFormat: 'dd/MM/yyyy',
            placeholder: props.placeholder || 'Selecione a data',
          };
        case 'time':
          return {
            ...baseConfig,
            timePicker: true,
            format: 'HH:mm',
            previewFormat: 'HH:mm',
            placeholder: props.placeholder || 'Selecione o horário',
          };
        case 'datetime':
        default:
          return {
            ...baseConfig,
            enableTimePicker: true,
            placeholder: props.placeholder || 'Selecione data e hora',
          };
      }
    });

    return {
      internalValue,
      pickerConfig,
    };
  },
};
</script>

<template>
  <div class="date-picker-v2">
    <VueDatePicker
      v-model="internalValue"
      v-bind="pickerConfig"
      :enable-time-picker="type === 'datetime'"
      :time-picker="type === 'time'"
      :auto-apply="false"
      :clearable="true"
      :close-on-scroll="false"
      :day-names="['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']"
    />
  </div>
</template>

<style scoped>
.date-picker-v2 {
  width: 100%;
}

/* Ajustes para manter consistência visual com o tema atual */
.date-picker-v2 :deep(.dp__input) {
  border: 1px solid #e2e8f0;
  border-radius: 4px;
  padding: 8px 12px;
  font-size: 14px;
  transition: border-color 0.2s ease;
}

.date-picker-v2 :deep(.dp__input:focus) {
  border-color: #1f93ff;
  outline: none;
  box-shadow: 0 0 0 2px rgba(31, 147, 255, 0.1);
}

.date-picker-v2 :deep(.dp__input:hover) {
  border-color: #cbd5e0;
}
</style>