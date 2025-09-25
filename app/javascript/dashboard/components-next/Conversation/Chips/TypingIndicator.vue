<script setup>
import { useFunctionGetter, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { computed } from 'vue';

const { t } = useI18n();

const getTypingUsersText = (users = []) => {
  const count = users.length;
  const [firstUser, secondUser] = users;

  if (count === 1) {
    return t('TYPING.ONE', { user: firstUser.name });
  }

  if (count === 2) {
    return t('TYPING.TWO', {
      user: firstUser.name,
      secondUser: secondUser.name,
    });
  }

  return t('TYPING.MULTIPLE', { user: firstUser.name, count: count - 1 });
};

const currentChat = useMapGetter('getSelectedChat');
const typingUsersList = useFunctionGetter(
  'conversationTypingStatus/getUserList',
  currentChat.value.id
);

const isAnyoneTyping = computed(() => {
  return typingUsersList.value.length !== 0;
});

const typingUserNames = computed(() => {
  if (typingUsersList.value.length) {
    return getTypingUsersText(typingUsersList.value);
  }
  return '';
});
</script>

<template>
  <div v-show="isAnyoneTyping">
    <div
      v-if="isAnyoneTyping"
      class="flex py-1.5 ltr:pr-2 ltr:pl-3 rtl:pl-2 rtl:pr-3 rounded-full shadow-sm border border-n-weak bg-n-solid-2 text-xs font-semibold my-2.5 mx-auto"
    >
      {{ typingUserNames }}
      <img
        class="w-6 ltr:ml-2 rtl:mr-2"
        src="assets/images/typing.gif"
        alt="Someone is typing"
      />
    </div>
  </div>
</template>
