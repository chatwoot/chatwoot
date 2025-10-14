<script>
import { useAlert } from 'dashboard/composables';
import {
  DuplicateContactException,
  ExceptionWithMessage,
} from 'shared/helpers/CustomErrors';
import { required } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Avatar from 'next/avatar/Avatar.vue';

export default {
  components: {
    NextButton,
    Avatar,
  },
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
    inProgress: {
      type: Boolean,
      default: false,
    },
    onSubmit: {
      type: Function,
      default: () => {},
    },
  },
  emits: ['cancel', 'success'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      name: '',
      playerId: '',
      ggNickname: '',
      playerStatus: 'beginner',
      behaviorStatus: 'loyal',
      avatarFile: null,
      avatarUrl: '',
    };
  },
  validations: {
    name: {
      required,
    },
  },
  computed: {
    // Player status options
    playerStatusOptions() {
      return [
        {
          value: 'beginner',
          label: this.$t('CONTACT_FORM.PLAYER_STATUS.BEGINNER'),
        },
        {
          value: 'amateur',
          label: this.$t('CONTACT_FORM.PLAYER_STATUS.AMATEUR'),
        },
        {
          value: 'regular',
          label: this.$t('CONTACT_FORM.PLAYER_STATUS.REGULAR'),
        },
        {
          value: 'advanced',
          label: this.$t('CONTACT_FORM.PLAYER_STATUS.ADVANCED'),
        },
        {
          value: 'professional',
          label: this.$t('CONTACT_FORM.PLAYER_STATUS.PROFESSIONAL'),
        },
        {
          value: 'high_roller',
          label: this.$t('CONTACT_FORM.PLAYER_STATUS.HIGH_ROLLER'),
        },
      ];
    },
    // Behavior status options
    behaviorStatusOptions() {
      return [
        {
          value: 'toxic',
          label: this.$t('CONTACT_FORM.BEHAVIOR_STATUS.TOXIC'),
        },
        {
          value: 'manipulator',
          label: this.$t('CONTACT_FORM.BEHAVIOR_STATUS.MANIPULATOR'),
        },
        {
          value: 'loyal',
          label: this.$t('CONTACT_FORM.BEHAVIOR_STATUS.LOYAL'),
        },
        { value: 'tilt', label: this.$t('CONTACT_FORM.BEHAVIOR_STATUS.TILT') },
        {
          value: 'artist',
          label: this.$t('CONTACT_FORM.BEHAVIOR_STATUS.ARTIST'),
        },
        {
          value: 'teapot',
          label: this.$t('CONTACT_FORM.BEHAVIOR_STATUS.TEAPOT'),
        },
      ];
    },
  },
  watch: {
    contact() {
      this.setContactObject();
    },
  },
  mounted() {
    this.setContactObject();
  },
  methods: {
    onCancel() {
      this.$emit('cancel');
    },
    onSuccess() {
      this.$emit('success');
    },
    setContactObject() {
      const { name } = this.contact;
      const additionalAttributes = this.contact.additional_attributes || {};

      this.name = name || '';
      this.playerId = additionalAttributes.player_id || this.contact.id || '';
      this.ggNickname = additionalAttributes.gg_nickname || '';
      this.playerStatus = additionalAttributes.player_status || 'beginner';
      this.behaviorStatus = additionalAttributes.behavior_status || 'loyal';
      this.avatarUrl = this.contact.thumbnail || '';
    },
    getContactObject() {
      const contactObject = {
        id: this.contact.id,
        name: this.name,
        additional_attributes: {
          ...this.contact.additional_attributes,
          player_id: this.playerId,
          gg_nickname: this.ggNickname,
          player_status: this.playerStatus,
          behavior_status: this.behaviorStatus,
        },
      };
      if (this.avatarFile) {
        contactObject.avatar = this.avatarFile;
        contactObject.isFormData = true;
      }
      return contactObject;
    },
    async handleSubmit() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }
      try {
        await this.onSubmit(this.getContactObject());
        this.onSuccess();
        useAlert(this.$t('CONTACT_FORM.SUCCESS_MESSAGE'));
      } catch (error) {
        if (error instanceof DuplicateContactException) {
          useAlert(this.$t('CONTACT_FORM.DUPLICATE_CONTACT'));
        } else if (error instanceof ExceptionWithMessage) {
          useAlert(error.data);
        } else {
          useAlert(this.$t('CONTACT_FORM.ERROR_MESSAGE'));
        }
      }
    },
    handleImageUpload({ file, url }) {
      this.avatarFile = file;
      this.avatarUrl = url;
    },
    async handleAvatarDelete() {
      try {
        if (this.contact && this.contact.id) {
          await this.$store.dispatch('contacts/deleteAvatar', this.contact.id);
          useAlert(this.$t('CONTACT_FORM.DELETE_AVATAR.API.SUCCESS_MESSAGE'));
        }
        this.avatarFile = null;
        this.avatarUrl = '';
      } catch (error) {
        useAlert(
          error.message
            ? error.message
            : this.$t('CONTACT_FORM.DELETE_AVATAR.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <form
    class="w-full px-8 pt-6 pb-8 contact--form"
    @submit.prevent="handleSubmit"
  >
    <!-- Avatar -->
    <div class="flex flex-col mb-4 items-start gap-1 w-full">
      <label class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ $t('CONTACT_FORM.FORM.AVATAR.LABEL') }}
      </label>
      <Avatar
        :src="avatarUrl"
        :size="72"
        :name="contact.name"
        allow-upload
        rounded-full
        @upload="handleImageUpload"
        @delete="handleAvatarDelete"
      />
    </div>

    <!-- Name -->
    <div class="w-full mb-4">
      <label :class="{ error: v$.name.$error }">
        {{ $t('CONTACT_FORM.FORM.NAME.LABEL') }}
        <input
          v-model="name"
          type="text"
          :placeholder="$t('CONTACT_FORM.FORM.NAME.PLACEHOLDER')"
          @input="v$.name.$touch"
        />
      </label>
    </div>

    <!-- Player ID (readonly) -->
    <div class="w-full mb-4">
      <label>
        {{ $t('CONTACT_FORM.PLAYER_ID.LABEL') }}
        <input
          v-model="playerId"
          type="text"
          readonly
          class="bg-n-slate-3"
          :placeholder="$t('CONTACT_FORM.PLAYER_ID.PLACEHOLDER')"
        />
      </label>
    </div>

    <!-- GG Nickname (readonly) -->
    <div class="w-full mb-4">
      <label>
        {{ $t('CONTACT_FORM.GG_NICKNAME.LABEL') }}
        <input
          v-model="ggNickname"
          type="text"
          readonly
          class="bg-n-slate-3"
          :placeholder="$t('CONTACT_FORM.GG_NICKNAME.PLACEHOLDER')"
        />
      </label>
    </div>

    <!-- Player Status -->
    <div class="w-full mb-4">
      <label>
        {{ $t('CONTACT_FORM.PLAYER_STATUS.LABEL') }}
        <select v-model="playerStatus" class="form-control">
          <option
            v-for="status in playerStatusOptions"
            :key="status.value"
            :value="status.value"
          >
            {{ status.label }}
          </option>
        </select>
      </label>
    </div>

    <!-- Behavior Status -->
    <div class="w-full mb-4">
      <label>
        {{ $t('CONTACT_FORM.BEHAVIOR_STATUS.LABEL') }}
        <select v-model="behaviorStatus" class="form-control">
          <option
            v-for="status in behaviorStatusOptions"
            :key="status.value"
            :value="status.value"
          >
            {{ status.label }}
          </option>
        </select>
      </label>
    </div>

    <!-- Submit buttons -->
    <div class="flex flex-row justify-start w-full gap-2 px-0 py-2">
      <NextButton
        type="submit"
        :label="$t('CONTACT_FORM.FORM.SUBMIT')"
        :is-loading="inProgress"
      />
      <NextButton
        faded
        slate
        type="reset"
        :label="$t('CONTACT_FORM.FORM.CANCEL')"
        @click.prevent="onCancel"
      />
    </div>
  </form>
</template>

<style scoped lang="scss">
.bg-n-slate-3 {
  background-color: var(--s-75);
  cursor: not-allowed;
}
</style>
