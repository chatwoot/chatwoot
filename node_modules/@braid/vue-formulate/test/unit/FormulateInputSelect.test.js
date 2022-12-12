import Vue from 'vue'
import { mount } from '@vue/test-utils'
import flushPromises from 'flush-promises'
import Formulate from '@/Formulate.js'
import FormulateInput from '@/FormulateInput.vue'
import FormulateInputSelect from '@/inputs/FormulateInputSelect.vue'

Vue.use(Formulate)

describe('FormulateInputSelect', () => {
  it('renders select input when type is "select"', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'select' } })
    expect(wrapper.findComponent(FormulateInputSelect).exists()).toBe(true)
  })

  it('renders select options when options object is passed', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'select', options: { first: 'First', second: 'Second' } } })
    const option = wrapper.find('option[value="second"]')
    expect(option.exists()).toBe(true)
    expect(option.text()).toBe('Second')
  })

  it('renders select options when options array is passed', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'select', options: [
      { value: 13, label: 'Jane' },
      { value: 22, label: 'Jon' }
    ]} })
    const option = wrapper.find('option[value="22"]')
    expect(option.exists()).toBe(true)
    expect(option.text()).toBe('Jon')
  })

  it('renders select list with no options when empty array is passed.', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'select', options: []} })
    const option = wrapper.find('option')
    expect(option.exists()).toBe(false)
  })

  it('renders select list placeholder option.', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'select', placeholder: 'Select this', options: []} })
    const options = wrapper.findAll('option')
    expect(options.length).toBe(1)
    expect(options.at(0).attributes('disabled')).toBeTruthy()
  })

  it('passes an explicitly given name prop through to the root element', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'select', options: [],  name: 'foo' } })
    expect(wrapper.find('select[name="foo"]').exists()).toBe(true)
  })

  it('Allows disabling options', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'select', options: [
      { label: 'a', value: 'a'},
      { label: 'b', value: 'b', disabled: true },
      { label: 'c', value: 'c'}
    ],  name: 'foo' } })
    expect(wrapper.find('option[value="a"]').attributes('disabled')).toBe(undefined)
    expect(wrapper.find('option[value="b"]').attributes('disabled')).toBe('disabled')
  })

  it('additional context does not bleed through to text select attributes', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'select' } } )
    expect(Object.keys(wrapper.find('select').attributes())).toEqual(["id"])
  })

  it('sets data-has-value when it has a value', async () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'select', value: '', options: {first: 'First', second: 'Second'} }})
    expect(wrapper.attributes('data-has-value')).toBe(undefined)
    wrapper.find('select').setValue('second')
    await flushPromises()
    expect(wrapper.attributes('data-has-value')).toBe('true')
  })

  it('can add classes to the element wrapper', () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'select', elementClass: ['test-class']}
    })
    expect(wrapper.findComponent(FormulateInputSelect).attributes('class'))
      .toBe('formulate-input-element formulate-input-element--select test-class')
  })

  it('can add classes to the input element', () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'select', inputClass: ['test-class']}
    })
    expect(wrapper.find('select').attributes('class'))
      .toBe('test-class')
  })

  it('selects the first item if it has no value, vmodel, or formvalue', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'select', options: { a: 'A', b: 'B', c: 'C' }}
    })
    await flushPromises()
    expect(wrapper.find('select').element.value).toBe('a')
  })

  it('does not select first value if there is a placeholder', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'select', options: { a: 'A', b: 'B', c: 'C' }, placeholder: 'Select a letter' }
    })
    await flushPromises()
    expect(wrapper.find('select').element.value).toBe('')
  })

  it('does not set the default value if a value exists', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'select', options: { a: 'A', b: 'B', c: 'C' }, value: '' }
    })
    await flushPromises()
    expect(wrapper.find('select').element.value).toBe('')
  })

  it('does not set the default value if a v-model exists', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'select', options: { a: 'A', b: 'B', c: 'C' }, formulateValue: '' },
      listeners: {
        input: () => {}
      }
    })
    await flushPromises()
    expect(wrapper.find('select').element.value).toBe('')
  })

  it('emits a focus event', async () => {
    const focus = jest.fn()
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'select', options: {a: 'A', b: 'B'} },
      listeners: { focus }
    })
    wrapper.find('select').trigger('focus')
    await flushPromises()
    expect(focus.mock.calls.length).toBe(1);
  })

  it('initializes multi-input select lists with an array instead of a string', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'select', options: { a: 'A', b: 'B', c: 'C' }, multiple: true },
    })
    await flushPromises()
    expect(wrapper.vm.context.model).toEqual([])
  })

  it('allows using an array of strings as options', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'select', options: ['Sydney', 'New York', 'Chicago'] },
    })
    await flushPromises()
    expect(wrapper.findAll('select option')
      .wrappers
      .map(option => `${option.attributes('value')} - ${option.text()}`)
    ).toEqual(['Sydney - Sydney', 'New York - New York', 'Chicago - Chicago'])
  })

  it('allows slot injection of of a prefix and suffix', async () => {
    const wrapper = mount({
      template: `
        <FormulateInput
          type="select"
          label="money"
          :options="['a', 'b']"
        >
          <template #prefix="{ label }">
            <span>\${{ label }}</span>
          </template>
          <template #suffix="{ label }">
            <span>after {{ label }}</span>
          </template>
        </FormulateInput>
      `
    })
    expect(wrapper.find('.formulate-input-element > span').text()).toBe('$money')
    expect(wrapper.find('.formulate-input-element > *:last-child').text()).toBe('after money')
  })
})
