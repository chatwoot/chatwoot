<template>
  <div class="brazilian-contact-form">
    <div class="form-header">
      <h3>Formulário de Contato Brasileiro</h3>
      <p>Preencha seus dados para iniciar uma conversa</p>
    </div>

    <form @submit.prevent="handleSubmit" class="contact-form">
      <!-- Nome -->
      <div class="form-group">
        <label for="name">Nome Completo</label>
        <input
          id="name"
          v-model="formData.name"
          type="text"
          placeholder="Digite seu nome completo"
          required
          class="form-input"
        />
      </div>

      <!-- Email -->
      <div class="form-group">
        <label for="email">E-mail</label>
        <input
          id="email"
          v-model="formData.email"
          type="email"
          placeholder="Digite seu e-mail"
          required
          class="form-input"
        />
      </div>

      <!-- Telefone -->
      <div class="form-group">
        <label for="phone">Telefone</label>
        <div class="phone-input-group">
          <span class="country-code">+55</span>
          <input
            id="phone"
            v-model="formData.phone"
            type="tel"
            placeholder="(11) 99999-9999"
            @blur="validatePhone"
            @input="formatPhone"
            class="form-input phone-input"
          />
        </div>
        <div v-if="phoneValidation" class="validation-message" :class="phoneValidation.valid ? 'valid' : 'invalid'">
          {{ phoneValidation.message }}
        </div>
      </div>

      <!-- CPF/CNPJ -->
      <div class="form-group">
        <label for="document">CPF/CNPJ (opcional)</label>
        <input
          id="document"
          v-model="formData.document"
          type="text"
          placeholder="000.000.000-00 ou 00.000.000/0000-00"
          @blur="validateDocument"
          @input="formatDocument"
          class="form-input"
        />
        <div v-if="documentValidation" class="validation-message" :class="documentValidation.valid ? 'valid' : 'invalid'">
          {{ documentValidation.message }}
        </div>
      </div>

      <!-- Mensagem -->
      <div class="form-group">
        <label for="message">Mensagem</label>
        <textarea
          id="message"
          v-model="formData.message"
          placeholder="Digite sua mensagem..."
          rows="4"
          @input="detectIntent"
          class="form-input"
        ></textarea>
        <div v-if="detectedIntent" class="intent-detection">
          <span class="intent-label">Intenção detectada:</span>
          <span class="intent-value">{{ getIntentLabel(detectedIntent) }}</span>
        </div>
      </div>

      <!-- Botões -->
      <div class="form-actions">
        <button
          type="button"
          @click="autoFillContact"
          :disabled="!formData.phone && !formData.document"
          class="btn btn-secondary"
        >
          Auto-preencher
        </button>
        <button
          type="submit"
          :disabled="!isFormValid || isSubmitting"
          class="btn btn-primary"
        >
          <span v-if="isSubmitting">Enviando...</span>
          <span v-else>Enviar Mensagem</span>
        </button>
      </div>
    </form>

    <!-- Resultado -->
    <div v-if="result" class="result-message" :class="result.success ? 'success' : 'error'">
      {{ result.message }}
    </div>
  </div>
</template>

<script>
import { ref, computed, reactive } from 'vue';

export default {
  name: 'BrazilianContactForm',
  props: {
    accountId: {
      type: [String, Number],
      required: true
    }
  },
  emits: ['conversation-created', 'error'],
  setup(props, { emit }) {
    const formData = reactive({
      name: '',
      email: '',
      phone: '',
      document: '',
      message: ''
    });

    const phoneValidation = ref(null);
    const documentValidation = ref(null);
    const detectedIntent = ref(null);
    const isSubmitting = ref(false);
    const result = ref(null);

    const isFormValid = computed(() => {
      return formData.name && 
             formData.email && 
             formData.phone && 
             phoneValidation.value?.valid;
    });

    const formatPhone = (event) => {
      let value = event.target.value.replace(/\D/g, '');
      
      if (value.length <= 2) {
        formData.phone = value;
      } else if (value.length <= 6) {
        formData.phone = `(${value.slice(0, 2)}) ${value.slice(2)}`;
      } else if (value.length <= 10) {
        formData.phone = `(${value.slice(0, 2)}) ${value.slice(2, 6)}-${value.slice(6)}`;
      } else {
        formData.phone = `(${value.slice(0, 2)}) ${value.slice(2, 7)}-${value.slice(7, 11)}`;
      }
    };

    const validatePhone = async () => {
      if (!formData.phone) return;

      try {
        const response = await fetch(`/api/v1/accounts/${props.accountId}/brazil_conversations/validate_phone`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'api_access_token': window.authToken
          },
          body: JSON.stringify({
            phone_number: formData.phone
          })
        });

        const data = await response.json();
        
        phoneValidation.value = {
          valid: data.valid,
          message: data.valid ? 'Telefone válido' : 'Telefone inválido'
        };

        if (data.valid && data.formatted) {
          formData.phone = data.formatted;
        }
      } catch (error) {
        console.error('Erro ao validar telefone:', error);
      }
    };

    const formatDocument = (event) => {
      let value = event.target.value.replace(/\D/g, '');
      
      if (value.length <= 11) {
        // CPF
        if (value.length <= 3) {
          formData.document = value;
        } else if (value.length <= 6) {
          formData.document = `${value.slice(0, 3)}.${value.slice(3)}`;
        } else if (value.length <= 9) {
          formData.document = `${value.slice(0, 3)}.${value.slice(3, 6)}.${value.slice(6)}`;
        } else {
          formData.document = `${value.slice(0, 3)}.${value.slice(3, 6)}.${value.slice(6, 9)}-${value.slice(9)}`;
        }
      } else {
        // CNPJ
        if (value.length <= 2) {
          formData.document = value;
        } else if (value.length <= 5) {
          formData.document = `${value.slice(0, 2)}.${value.slice(2)}`;
        } else if (value.length <= 8) {
          formData.document = `${value.slice(0, 2)}.${value.slice(2, 5)}.${value.slice(5)}`;
        } else if (value.length <= 12) {
          formData.document = `${value.slice(0, 2)}.${value.slice(2, 5)}.${value.slice(5, 8)}/${value.slice(8)}`;
        } else {
          formData.document = `${value.slice(0, 2)}.${value.slice(2, 5)}.${value.slice(5, 8)}/${value.slice(8, 12)}-${value.slice(12)}`;
        }
      }
    };

    const validateDocument = async () => {
      if (!formData.document) return;

      try {
        const response = await fetch(`/api/v1/accounts/${props.accountId}/brazil_conversations/validate_document`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'api_access_token': window.authToken
          },
          body: JSON.stringify({
            document_number: formData.document
          })
        });

        const data = await response.json();
        
        documentValidation.value = {
          valid: data.valid,
          message: data.valid ? `${data.type.toUpperCase()} válido` : 'Documento inválido'
        };
      } catch (error) {
        console.error('Erro ao validar documento:', error);
      }
    };

    const detectIntent = async () => {
      if (!formData.message || formData.message.length < 10) {
        detectedIntent.value = null;
        return;
      }

      try {
        const response = await fetch(`/api/v1/accounts/${props.accountId}/brazil_conversations/detect_intent`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'api_access_token': window.authToken
          },
          body: JSON.stringify({
            message_content: formData.message
          })
        });

        const data = await response.json();
        detectedIntent.value = data.intent;
      } catch (error) {
        console.error('Erro ao detectar intenção:', error);
      }
    };

    const autoFillContact = async () => {
      try {
        const response = await fetch(`/api/v1/accounts/${props.accountId}/brazil_conversations/auto_fill_contact`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'api_access_token': window.authToken
          },
          body: JSON.stringify({
            phone_number: formData.phone,
            document_number: formData.document
          })
        });

        const data = await response.json();
        
        if (data.phone_info) {
          Object.assign(formData, data.phone_info);
        }
        
        result.value = {
          success: true,
          message: 'Informações preenchidas automaticamente'
        };
      } catch (error) {
        console.error('Erro ao auto-preencher:', error);
        result.value = {
          success: false,
          message: 'Erro ao preencher informações automaticamente'
        };
      }
    };

    const handleSubmit = async () => {
      if (!isFormValid.value) return;

      isSubmitting.value = true;
      result.value = null;

      try {
        const response = await fetch(`/api/v1/accounts/${props.accountId}/brazil_conversations/create_with_welcome`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'api_access_token': window.authToken
          },
          body: JSON.stringify({
            contact: {
              name: formData.name,
              email: formData.email,
              phone_number: formData.phone,
              additional_attributes: {
                document: formData.document,
                document_type: documentValidation.value?.type,
                country: 'Brasil',
                country_code: 'BR'
              }
            },
            message: {
              content: formData.message
            }
          })
        });

        const data = await response.json();
        
        if (response.ok) {
          result.value = {
            success: true,
            message: 'Conversa criada com sucesso! Mensagem de boas-vindas enviada.'
          };
          emit('conversation-created', data);
        } else {
          throw new Error(data.error || 'Erro desconhecido');
        }
      } catch (error) {
        console.error('Erro ao criar conversa:', error);
        result.value = {
          success: false,
          message: error.message || 'Erro ao criar conversa'
        };
        emit('error', error);
      } finally {
        isSubmitting.value = false;
      }
    };

    const getIntentLabel = (intent) => {
      const labels = {
        'vendas': 'Vendas',
        'suporte': 'Suporte',
        'financeiro': 'Financeiro',
        'reclamacao': 'Reclamação',
        'geral': 'Geral'
      };
      return labels[intent] || intent;
    };

    return {
      formData,
      phoneValidation,
      documentValidation,
      detectedIntent,
      isSubmitting,
      result,
      isFormValid,
      formatPhone,
      validatePhone,
      formatDocument,
      validateDocument,
      detectIntent,
      autoFillContact,
      handleSubmit,
      getIntentLabel
    };
  }
};
</script>

<style scoped>
.brazilian-contact-form {
  max-width: 600px;
  margin: 0 auto;
  padding: 20px;
}

.form-header {
  text-align: center;
  margin-bottom: 30px;
}

.form-header h3 {
  color: #1f2937;
  margin-bottom: 10px;
}

.form-header p {
  color: #6b7280;
  font-size: 14px;
}

.contact-form {
  background: #ffffff;
  border-radius: 8px;
  padding: 30px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
  font-weight: 500;
  color: #374151;
}

.form-input {
  width: 100%;
  padding: 12px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 14px;
  transition: border-color 0.2s;
}

.form-input:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.phone-input-group {
  display: flex;
  align-items: center;
}

.country-code {
  background: #f3f4f6;
  padding: 12px 8px;
  border: 1px solid #d1d5db;
  border-right: none;
  border-radius: 6px 0 0 6px;
  font-size: 14px;
  color: #6b7280;
}

.phone-input {
  border-radius: 0 6px 6px 0;
  border-left: none;
}

.validation-message {
  margin-top: 5px;
  font-size: 12px;
}

.validation-message.valid {
  color: #059669;
}

.validation-message.invalid {
  color: #dc2626;
}

.intent-detection {
  margin-top: 10px;
  padding: 8px 12px;
  background: #f0f9ff;
  border-radius: 4px;
  font-size: 12px;
}

.intent-label {
  color: #0369a1;
  font-weight: 500;
}

.intent-value {
  color: #0c4a6e;
  margin-left: 5px;
}

.form-actions {
  display: flex;
  gap: 10px;
  margin-top: 30px;
}

.btn {
  padding: 12px 24px;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-primary {
  background: #3b82f6;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #2563eb;
}

.btn-secondary {
  background: #f3f4f6;
  color: #374151;
}

.btn-secondary:hover:not(:disabled) {
  background: #e5e7eb;
}

.result-message {
  margin-top: 20px;
  padding: 12px;
  border-radius: 6px;
  font-size: 14px;
}

.result-message.success {
  background: #d1fae5;
  color: #065f46;
  border: 1px solid #a7f3d0;
}

.result-message.error {
  background: #fee2e2;
  color: #991b1b;
  border: 1px solid #fca5a5;
}
</style> 