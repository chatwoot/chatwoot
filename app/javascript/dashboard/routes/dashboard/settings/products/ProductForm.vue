<!-- eslint-disable vue/no-mutating-props -->
<template>
  <div>
    <woot-modal
      :show.sync="show"
      :on-close="onCancel"
      modal-type="right-aligned"
    >
      <div class="h-auto overflow-auto flex flex-col">
        <woot-modal-header
          :header-title="`${$t('PRODUCT_FORM.TITLE')} - ${
            product.short_name || $t('PRODUCT_FORM.SUBTITLE')
          }`"
          :header-content="$t('PRODUCT_FORM.DESCRIPTION')"
        />
        <form
          class="w-full px-8 pt-6 pb-8 contact--form"
          @submit.prevent="handleSubmit"
        >
          <div class="w-full">
            <label :class="{ error: $v.name.$error }">
              {{ $t('PRODUCT_FORM.NAME_LABEL') }}
              <input v-model.trim="name" type="text" @input="$v.name.$touch" />
            </label>
          </div>
          <div class="w-full">
            <div class="gap-2 flex flex-row">
              <div class="w-[50%]">
                <label :class="{ error: $v.short_name.$error }">
                  {{ $t('PRODUCT_FORM.SHORT_NAME_LABEL') }}
                  <input
                    v-model.trim="short_name"
                    type="text"
                    @input="short_name = short_name.toUpperCase()"
                  />
                </label>
              </div>
              <div class="w-[50%]">
                <label :class="{ error: $v.price.$error }">
                  {{ $t('PRODUCT_FORM.PRICE_LABEL') }}
                  <input
                    v-model.trim="price"
                    type="number"
                    @input="$v.price.$touch"
                  />
                </label>
              </div>
            </div>
            <div v-if="product.id" class="flex flex-row-reverse mb-4">
              <label :class="{ error: $v.disabled.$error }">
                {{ $t('PRODUCT_FORM.DISABLED_LABEL') }}
                <input
                  v-model.trim="disabled"
                  class="!mt-0 ml-2"
                  type="checkbox"
                  @input="$v.disabled.$touch"
                />
              </label>
            </div>
          </div>

          <div class="conversation--actions">
            <accordion-item
              :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONTACT_ATTRIBUTES')"
              :is-open="true"
              compact
            >
              <custom-attributes
                attribute-type="product_attribute"
                attribute-class="conversation--attribute"
                attribute-from="product_form"
                :custom-attributes="customAttributes"
                class="even"
                @customAttributeChanged="customAttributeChanged"
              />
            </accordion-item>
          </div>

          <div class="flex flex-row justify-between w-full gap-2 px-0 py-2">
            <div class="flex gap-2">
              <woot-submit-button
                :loading="inProgress"
                :button-text="$t('PRODUCT_FORM.SUBMIT')"
                @click="submitEnabled = true"
              />
              <button class="button clear" @click.prevent="onCancel">
                {{ $t('PRODUCT_FORM.CANCEL') }}
              </button>
            </div>
            <button
              v-if="product.id"
              class="button alert"
              @click.prevent="confirmDelete"
            >
              {{ $t('PRODUCT_FORM.DELETE') }}
            </button>
          </div>
        </form>
      </div>
    </woot-modal>
    <woot-confirm-modal
      ref="confirmDeleteDialog"
      :title="$t('PRODUCT_FORM.CONFIRM_DELETE.TITLE')"
      :description="$t('PRODUCT_FORM.CONFIRM_DELETE.MESSAGE')"
      :confirm-label="$t('PRODUCT_FORM.CONFIRM_DELETE.YES')"
      :cancel-label="$t('PRODUCT_FORM.CONFIRM_DELETE.NO')"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { required } from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';
import AccordionItem from 'dashboard/components/Accordion/AccordionItem.vue';
import CustomAttributes from 'dashboard/routes/dashboard/conversation/customAttributes/CustomAttributes.vue';

export default {
  components: {
    CustomAttributes,
    AccordionItem,
  },
  mixins: [alertMixin],
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    product: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      submitEnabled: false,
      name: '',
      short_name: '',
      price: null,
      disabled: false,
      customAttributes: {},
    };
  },
  validations: {
    name: {
      required,
    },
    short_name: {
      required,
    },
    price: {
      required,
    },
    disabled: {
      required,
    },
  },

  computed: {
    ...mapGetters({
      uiFlags: 'products/getUIFlags',
    }),
    inProgress() {
      return this.uiFlags.isCreating;
    },
  },
  watch: {
    show() {
      this.setProductObject();
    },
  },
  mounted() {
    this.setProductObject();
  },
  methods: {
    onCancel() {
      this.$emit('cancel');
    },
    onSuccess() {
      this.$emit('cancel');
    },
    customAttributeChanged(key, value) {
      this.customAttributes = {
        ...this.customAttributes,
        [key]: value,
      };
    },
    setProductObject() {
      const { name, short_name, price, disabled } = this.product;

      this.name = name || '';
      this.short_name = short_name || '';
      this.price = price || 0;
      this.disabled = disabled || false;
      this.customAttributes = this.product.custom_attributes || {};
    },
    getProductObject() {
      const contactObject = {
        id: this.product.id,
        name: this.name,
        short_name: this.short_name,
        price: this.price,
        disabled: this.disabled,
        custom_attributes: this.customAttributes,
      };
      return contactObject;
    },
    async handleSubmit() {
      if (!this.submitEnabled) return;
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      try {
        const contactItem = this.getProductObject();
        if (contactItem.id) {
          await this.$store.dispatch('products/update', contactItem);
        } else {
          await this.$store.dispatch('products/create', contactItem);
        }
        this.onSuccess();
        this.showAlert(this.$t('PRODUCT_FORM.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('PRODUCT_FORM.ERROR_MESSAGE'));
      } finally {
        this.submitEnabled = false;
      }
    },
    async confirmDelete() {
      const ok = await this.$refs.confirmDeleteDialog.showConfirmation();

      if (ok) {
        try {
          await this.$store.dispatch('products/delete', this.product.id);
          this.onSuccess();
          this.showAlert(this.$t('PRODUCT_FORM.SUCCESS_DELETING'));
        } catch (error) {
          this.showAlert(this.$t('PRODUCT_FORM.ERROR_DELETING'));
        }
      }
    },
  },
};
</script>
