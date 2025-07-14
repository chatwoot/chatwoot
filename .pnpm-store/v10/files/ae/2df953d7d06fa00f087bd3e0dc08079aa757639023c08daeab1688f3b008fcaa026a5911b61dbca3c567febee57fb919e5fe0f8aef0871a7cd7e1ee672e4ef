import { mount } from '@vue/test-utils'
import HstCheckbox from './HstCheckbox.vue'

describe('hstCheckbox', () => {
  it('toggle to checked', async () => {
    const wrapper = mount(HstCheckbox, {
      props: {
        modelValue: false,
        title: 'Label',
      },
    })
    await wrapper.trigger('click')
    expect(wrapper.emitted('update:modelValue')[0]).toEqual([true])
    expect(wrapper.html()).toMatchSnapshot()
  })

  it('toggle to unchecked', async () => {
    const wrapper = mount(HstCheckbox, {
      props: {
        modelValue: true,
        title: 'Label',
      },
    })
    await wrapper.trigger('click')
    expect(wrapper.emitted('update:modelValue')[0]).toEqual([false])
    expect(wrapper.html()).toMatchSnapshot()
  })
})
