<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  emits: ['close'],
  data() {
    return {
      name: '',
      description: '',
      typeName: '',
      parentLocationId: null,
      hasAddress: false,
      street: '',
      exteriorNumber: '',
      interiorNumber: '',
      neighborhood: '',
      postalCode: '',
      city: '',
      state: '',
      email: '',
      phone: '',
      webpage: '',
      establishmentSummary: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'locations/getUIFlags',
      locations: 'locations/getLocations',
    }),
    parentLocationOptions() {
      const options = [
        { value: null, label: this.$t('LOCATIONS.FORM.NO_PARENT') },
      ];

      this.locations.forEach(loc => {
        options.push({
          value: loc.id,
          label: loc.name,
        });
      });

      return options;
    },
    isAddressValid() {
      if (!this.hasAddress) return true;

      return (
        this.street &&
        this.exteriorNumber &&
        this.neighborhood &&
        this.postalCode &&
        this.city &&
        this.state
      );
    },
    isFormValid() {
      return this.name && this.isAddressValid;
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    async addLocation() {
      if (!this.isFormValid) return;

      const payload = {
        name: this.name,
        description: this.description || null,
        type_name: this.typeName || null,
        parent_location_id: this.parentLocationId || null,
      };

      if (this.hasAddress) {
        payload.address_attributes = {
          street: this.street,
          exterior_number: this.exteriorNumber,
          interior_number: this.interiorNumber || null,
          neighborhood: this.neighborhood,
          postal_code: this.postalCode,
          city: this.city,
          state: this.state,
          email: this.email || null,
          phone: this.phone || null,
          webpage: this.webpage || null,
          establishment_summary: this.establishmentSummary || null,
        };
      }

      try {
        await this.$store.dispatch('locations/create', payload);
        useAlert(this.$t('LOCATIONS.FORM.CREATE_SUCCESS'));
        this.onClose();
        await this.$store.dispatch('locations/get');
      } catch (error) {
        const errorMessage =
          error?.response?.data?.errors?.[0] ||
          error.message ||
          this.$t('LOCATIONS.FORM.SUBMIT_ERROR');
        useAlert(errorMessage);
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('LOCATIONS.FORM.CREATE_TITLE')"
      :header-content="$t('LOCATIONS.FORM.BASIC_INFO')"
    />
    <form class="flex flex-wrap mx-0" @submit.prevent="addLocation">
      <!-- Name -->
      <woot-input
        v-model="name"
        class="w-full"
        :label="$t('LOCATIONS.FORM.NAME')"
        :placeholder="$t('LOCATIONS.FORM.NAME_PLACEHOLDER')"
        :error="!name ? $t('LOCATIONS.FORM.NAME_REQUIRED') : ''"
        required
      />

      <!-- Type Name -->
      <woot-input
        v-model="typeName"
        class="w-full"
        :label="$t('LOCATIONS.FORM.TYPE_NAME')"
        :placeholder="$t('LOCATIONS.FORM.TYPE_NAME_PLACEHOLDER')"
      />

      <!-- Description -->
      <label class="w-full">
        {{ $t('LOCATIONS.FORM.DESCRIPTION') }}
        <textarea
          v-model="description"
          rows="3"
          :placeholder="$t('LOCATIONS.FORM.DESCRIPTION_PLACEHOLDER')"
          class="w-full"
        />
      </label>

      <!-- Parent Location -->
      <div class="w-full">
        <label>
          {{ $t('LOCATIONS.FORM.PARENT_LOCATION') }}
          <select v-model="parentLocationId" class="w-full">
            <option
              v-for="option in parentLocationOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </label>
      </div>

      <!-- Has Address Toggle -->
      <div class="flex items-center w-full gap-2 my-4">
        <input v-model="hasAddress" type="checkbox" :value="true" />
        <label>
          {{ $t('LOCATIONS.FORM.HAS_ADDRESS') }}
        </label>
      </div>

      <!-- Address Fields (conditional) -->
      <template v-if="hasAddress">
        <div class="w-full">
          <h3 class="text-base font-medium mb-2">
            {{ $t('LOCATIONS.FORM.ADDRESS_SECTION') }}
          </h3>
        </div>

        <div class="w-2/3 ltr:pr-2 rtl:pl-2">
          <woot-input
            v-model="street"
            :label="$t('LOCATIONS.FORM.ADDRESS.STREET')"
            :placeholder="$t('LOCATIONS.FORM.ADDRESS.STREET_PLACEHOLDER')"
            required
          />
        </div>

        <div class="w-1/6 ltr:pr-2 rtl:pl-2">
          <woot-input
            v-model="exteriorNumber"
            :label="$t('LOCATIONS.FORM.ADDRESS.EXTERIOR_NUMBER')"
            required
          />
        </div>

        <div class="w-1/6">
          <woot-input
            v-model="interiorNumber"
            :label="$t('LOCATIONS.FORM.ADDRESS.INTERIOR_NUMBER')"
          />
        </div>

        <div class="w-1/2 ltr:pr-2 rtl:pl-2">
          <woot-input
            v-model="neighborhood"
            :label="$t('LOCATIONS.FORM.ADDRESS.NEIGHBORHOOD')"
            required
          />
        </div>

        <div class="w-1/2">
          <woot-input
            v-model="postalCode"
            :label="$t('LOCATIONS.FORM.ADDRESS.POSTAL_CODE')"
            required
          />
        </div>

        <div class="w-1/2 ltr:pr-2 rtl:pl-2">
          <woot-input
            v-model="city"
            :label="$t('LOCATIONS.FORM.ADDRESS.CITY')"
            required
          />
        </div>

        <div class="w-1/2">
          <woot-input
            v-model="state"
            :label="$t('LOCATIONS.FORM.ADDRESS.STATE')"
            required
          />
        </div>

        <div class="w-1/2 ltr:pr-2 rtl:pl-2">
          <woot-input
            v-model="email"
            type="email"
            :label="$t('LOCATIONS.FORM.ADDRESS.EMAIL')"
          />
        </div>

        <div class="w-1/2">
          <woot-input
            v-model="phone"
            :label="$t('LOCATIONS.FORM.ADDRESS.PHONE')"
          />
        </div>

        <woot-input
          v-model="webpage"
          class="w-full"
          type="url"
          :label="$t('LOCATIONS.FORM.ADDRESS.WEBPAGE')"
        />

        <label class="w-full">
          {{ $t('LOCATIONS.FORM.ADDRESS.ESTABLISHMENT_SUMMARY') }}
          <textarea
            v-model="establishmentSummary"
            rows="2"
            class="w-full"
          />
        </label>
      </template>

      <!-- Form Actions -->
      <div class="flex items-center justify-end w-full gap-2 px-0 py-2">
        <NextButton
          faded
          slate
          type="reset"
          :label="$t('LOCATIONS.FORM.CANCEL')"
          @click.prevent="onClose"
        />
        <NextButton
          type="submit"
          :label="$t('LOCATIONS.FORM.CREATE')"
          :disabled="!isFormValid || uiFlags.isCreating"
          :is-loading="uiFlags.isCreating"
        />
      </div>
    </form>
  </div>
</template>
