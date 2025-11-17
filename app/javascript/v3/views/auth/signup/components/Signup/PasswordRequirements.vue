<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  password: { type: String, default: '' },
  open: { type: Boolean, default: false },
  showError: { type: Boolean, default: false },
  minLength: { type: Number, default: 6 },
});

const SPECIAL_CHAR_REGEX = /[!@#$%^&*()_+\-=[\]{}|'"/\\.,`<>:;?~]/;

const { t } = useI18n();

const passwordRequirements = computed(() => {
  const pwd = props.password || '';
  return {
    length: pwd.length >= props.minLength,
    uppercase: /[A-Z]/.test(pwd),
    lowercase: /[a-z]/.test(pwd),
    number: /[0-9]/.test(pwd),
    special: SPECIAL_CHAR_REGEX.test(pwd),
  };
});

const passwordRequirementItems = computed(() => {
  const reqs = passwordRequirements.value;
  return [
    {
      id: 'length',
      met: reqs.length,
      label: t('REGISTER.PASSWORD.REQUIREMENTS_LENGTH', {
        min: props.minLength,
      }),
    },
    {
      id: 'uppercase',
      met: reqs.uppercase,
      label: t('REGISTER.PASSWORD.REQUIREMENTS_UPPERCASE'),
    },
    {
      id: 'lowercase',
      met: reqs.lowercase,
      label: t('REGISTER.PASSWORD.REQUIREMENTS_LOWERCASE'),
    },
    {
      id: 'number',
      met: reqs.number,
      label: t('REGISTER.PASSWORD.REQUIREMENTS_NUMBER'),
    },
    {
      id: 'special',
      met: reqs.special,
      label: t('REGISTER.PASSWORD.REQUIREMENTS_SPECIAL'),
    },
  ];
});
</script>

<template>
  <div
    class="grid transition-all duration-300 ease-in-out"
    :class="[open ? 'grid-rows-[1fr] !mt-1' : 'grid-rows-[0fr] !mt-0']"
  >
    <div class="overflow-hidden">
      <Transition
        enter-active-class="transition-all duration-300 ease-in-out"
        leave-active-class="transition-all duration-300 ease-in-out"
        enter-from-class="opacity-0 -translate-y-2"
        enter-to-class="opacity-100 translate-y-0"
        leave-from-class="opacity-100 translate-y-0"
        leave-to-class="opacity-0 -translate-y-2"
      >
        <div
          v-if="open"
          id="password-requirements"
          class="text-xs rounded-lg px-3 py-2.5 outline outline-1 -outline-offset-1 outline-n-weak bg-n-alpha-black2"
        >
          <ul role="list" class="grid grid-cols-2 gap-1">
            <li
              v-for="item in passwordRequirementItems"
              :key="item.id"
              class="inline-flex gap-1 items-start"
            >
              <Icon
                class="flex-none flex-shrink-0 w-3 mt-0.5"
                :icon="
                  item.met
                    ? 'i-lucide-circle-check'
                    : showError
                      ? 'i-lucide-circle-x'
                      : 'i-lucide-circle-dot'
                "
                :class="
                  item.met
                    ? 'text-n-teal-9'
                    : showError
                      ? 'text-n-ruby-9'
                      : 'text-n-slate-10'
                "
              />

              <span
                :class="
                  item.met
                    ? 'text-n-teal-11'
                    : showError
                      ? 'text-n-ruby-11'
                      : 'text-n-slate-11'
                "
              >
                {{ item.label }}
              </span>
            </li>
          </ul>
        </div>
      </Transition>
    </div>
  </div>
</template>
