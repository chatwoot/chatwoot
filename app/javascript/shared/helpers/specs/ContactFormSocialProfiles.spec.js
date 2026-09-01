import { mount } from '@vue/test-utils';
import ContactForm from '../../../dashboard/routes/dashboard/conversation/contact/ContactForm.vue';
import VuelidatePlugin from '@vuelidate/core';

const profiles = [
  { key: 'instagram', valid: 'https://www.instagram.com/' },
  { key: 'twitter', valid: 'https://twitter.com/' },
  { key: 'linkedin', valid: 'https://linkedin.com/' },
  { key: 'facebook', valid: 'https://facebook.com/' },
  { key: 'github', valid: 'https://github.com/' },
  { key: 'telegram', valid: 'https://t.me/' },
  { key: 'tiktok', valid: 'https://tiktok.com/@' },
]

const factory = () =>
  mount(ContactForm, {
    global: {
      plugins: [VuelidatePlugin],
      mocks: { $t: msg => msg },
      stubs: {
        'woot-input': true,
        'woot-phone-input': true,
        Avatar: true,
        ComboBox: true,
        NextButton: true,
      },
    },
    props: {
      contact: {},
      inProgress: false,
      onSubmit: vi.fn(),
    },
  })

describe('ContactForm social profile validation', () => {
  profiles.forEach(({ key, valid }) => {
    it(`shows error for invalid ${key}`, async () => {
      const wrapper = factory()

      const input = wrapper.get(`[data-testid="social-${key}"]`)
      await input.setValue('bad-url')

      wrapper.vm.v$.$touch()
      await wrapper.vm.$nextTick()

      expect(wrapper.vm.socialProfileErrors[key])
        .toBe(`Invalid ${key} URL`)
    })

    it(`accepts valid ${key}`, async () => {
      const wrapper = factory()

      const input = wrapper.get(`[data-testid="social-${key}"]`)
      await input.setValue(valid)

      wrapper.vm.v$.$touch()
      await wrapper.vm.$nextTick()

      expect(wrapper.vm.socialProfileErrors[key]).toBeFalsy()
    })
  })
})