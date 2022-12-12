import Vue from 'vue'
import flushPromises from 'flush-promises'
import { mount } from '@vue/test-utils'
import Formulate from '../../src/Formulate.js'
import FormulateInput from '@/FormulateInput.vue'
import FormulateInputBox from '@/inputs/FormulateInputBox.vue'
import FormulateInputGroup from '@/inputs/FormulateInputGroup.vue'

Vue.use(Formulate)

describe('FormulateInputBox', () => {
  it('renders a box element when type "checkbox" ', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'checkbox' } })
    expect(wrapper.findComponent(FormulateInputBox).exists()).toBe(true)
  })

  it('renders a box element when type "radio"', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'radio' } })
    expect(wrapper.findComponent(FormulateInputBox).exists()).toBe(true)
  })

  it('passes an explicitly given name prop through to the root radio elements', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'radio', name: 'foo', options: {a: '1', b: '2'} } })
    expect(wrapper.findAll('input[name="foo"]')).toHaveLength(2)
  })

  it('passes an explicitly given name prop through to the root checkbox elements', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'checkbox', name: 'foo', options: {a: '1', b: '2'} } })
    expect(wrapper.findAll('input[name="foo"]')).toHaveLength(2)
  })

  it('box inputs properly process options object in context library', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'checkbox', options: {a: '1', b: '2'} } })
    expect(Array.isArray(wrapper.vm.context.options)).toBe(true)
  })

  it('renders a group when type "checkbox" with options', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'checkbox', options: {a: '1', b: '2'} } })
    expect(wrapper.findComponent(FormulateInputGroup).exists()).toBe(true)
  })

  it('renders a group when type "radio" with options', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'radio', options: {a: '1', b: '2'} } })
    expect(wrapper.findComponent(FormulateInputGroup).exists()).toBe(true)
  })

  it('defaults labelPosition to "after" when type "checkbox"', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'checkbox' } })
    expect(wrapper.vm.context.labelPosition).toBe('after')
  })

  it('labelPosition of defaults to before when type "checkbox" with options', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'checkbox', options: {a: '1', b: '2'}}})
    expect(wrapper.vm.context.labelPosition).toBe('before')
  })


  it('renders multiple inputs with options when type "radio"', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'radio', options: {a: '1', b: '2'} } })
    expect(wrapper.findAll('input[type="radio"]').length).toBe(2)
  })

  it('generates unique ids if not provided when type "radio"', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'radio', options: {a: '1', b: '2'} } })
    const radios = wrapper.findAll('input[type="radio"]')
    expect(radios.at(0).attributes().id).toBeTruthy()
    expect(radios.at(0).attributes().id).not.toBe(radios.at(1).attributes().id)
  })

  it('generates ids if not provided when type "radio" and options are arrays', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'radio', options: [{value: 'a', label: 'A'}, {value: 'b', label: 'B' }] } })
    const radios = wrapper.findAll('input[type="radio"]')
    expect(radios.at(0).attributes().id).not.toBe(radios.at(1).attributes().id)
  })

  it('additional context does not bleed through to attributes with type "radio" and options', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'radio', options: {a: '1', b: '2'} } })
    expect(Object.keys(wrapper.find('input[type="radio"]').attributes())).toEqual(["type", "id", "value"])
  })

  it('additional context does not bleed through to attributes with type "checkbox" and options', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'checkbox', options: {a: '1', b: '2'} } })
    expect(Object.keys(wrapper.find('input[type="checkbox"]').attributes())).toEqual(["type", "id", "value"])
  })

  it('allows external attributes to make it down to the inner box elements', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'radio', options: {a: '1', b: '2'}, readonly: 'true' } })
    expect(Object.keys(wrapper.find('input[type="radio"]').attributes()).includes('readonly')).toBe(true)
  })

  it('does not use the value attribute to be checked', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'checkbox', value: '123' } })
    expect(wrapper.find('input').element.checked).toBe(false)
  })

  it('uses the checked attribute to be checked', async () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'checkbox', checked: 'true' } })
    await flushPromises()
    await wrapper.vm.$nextTick()
    expect(wrapper.find('input').element.checked).toBe(true)
  })

  it('uses the value attribute to select "type" radio when using options', async () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'radio', options: {a: '1', b: '2'}, value: 'b' } })
    await flushPromises()
    expect(wrapper.findAll('input:checked').length).toBe(1)
  })

  it('uses the value attribute to select "type" checkbox when using options', async () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'checkbox', options: {a: '1', b: '2', c: '123'}, value: ['b', 'c'] } })
    await flushPromises()
    expect(wrapper.findAll('input:checked').length).toBe(2)
  })

  /**
   * it data binding
   */

  it('sets array of values via v-model when type "checkbox"', async () => {
    const wrapper = mount({
      data () {
        return {
          checkboxValues: [],
          options: {foo: 'Foo', bar: 'Bar', fooey: 'Fooey'}
        }
      },
      template: `
        <div>
          <FormulateInput type="checkbox" v-model="checkboxValues" :options="options" />
        </div>
      `
    })
    const fooInputs = wrapper.findAll('input[value^="foo"]')
    expect(fooInputs.length).toBe(2)
    fooInputs.at(0).setChecked()
    await flushPromises()
    fooInputs.at(1).setChecked()
    await flushPromises()
    expect(wrapper.vm.checkboxValues).toEqual(['foo', 'fooey'])
  })

  it('does not pre-set internal value when type "radio" with options', async () => {
    const wrapper = mount({
      data () {
        return {
          radioValue: '',
          options: {foo: 'Foo', bar: 'Bar', fooey: 'Fooey'}
        }
      },
      template: `
        <div>
          <FormulateInput type="radio" v-model="radioValue" :options="options" />
        </div>
      `
    })
    await wrapper.vm.$nextTick()
    await flushPromises()
    expect(wrapper.vm.radioValue).toBe('')
  })

  it('does not pre-set internal value of FormulateForm when type "radio" with options', async () => {
    const wrapper = mount({
      data () {
        return {
          radioValue: '',
          formValues: {},
          options: {foo: 'Foo', bar: 'Bar', fooey: 'Fooey'}
        }
      },
      template: `
        <FormulateForm
          v-model="formValues"
        >
          <FormulateInput type="radio" v-model="radioValue" name="foobar" :options="options" />
        </FormulateForm>
      `
    })
    await wrapper.vm.$nextTick()
    await flushPromises()
    expect(wrapper.vm.formValues.foobar).toBe('')
  })

  it('does precheck the correct input when radio with options', async () => {
    const wrapper = mount({
      data () {
        return {
          radioValue: 'fooey',
          options: {foo: 'Foo', bar: 'Bar', fooey: 'Fooey', gooey: 'Gooey'}
        }
      },
      template: `
        <div>
          <FormulateInput type="radio" v-model="radioValue" :options="options" />
        </div>
      `
    })
    await flushPromises()
    const checkboxes = wrapper.findAll('input[type="radio"]:checked')
    expect(checkboxes.length).toBe(1)
    expect(checkboxes.at(0).element.value).toBe('fooey')
  })

  it('shows validation errors when blurred', async () => {
    const wrapper = mount({
      data () {
        return {
          radioValue: 'fooey',
          options: {foo: 'Foo', bar: 'Bar', fooey: 'Fooey', gooey: 'Gooey'}
        }
      },
      template: `
        <div>
          <FormulateInput type="radio" v-model="radioValue" :options="options" validation="in:gooey" />
        </div>
      `
    })
    wrapper.find('input[value="fooey"]').trigger('blur')
    await wrapper.vm.$nextTick()
    await flushPromises()
    expect(wrapper.find('.formulate-input-error').exists()).toBe(true)
  })

  it('renders no boxes when options array is empty', async () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'checkbox', options: [] } })
    expect(wrapper.findComponent(FormulateInputGroup).exists()).toBe(true)
    expect(wrapper.find('input[type="checkbox"]').exists()).toBe(false)
  })

  it('renders multiple labels both with correct id', async () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'checkbox', label: 'VueFormulate FTW!'} })
    const id = wrapper.find('input[type="checkbox"]').attributes('id')
    const labelIds = wrapper.findAll('label').wrappers.map(label => label.attributes('for'));
    expect(labelIds.length).toBe(2);
    expect(labelIds.filter(labelId => labelId === id).length).toBe(2);
  })

  it('does not have data-is-showing-errors on well formed box inputs', async () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'radio', options: {first: 'First', second: 'Second', third: 'Third' }} })
    const radios = wrapper.findAll('input[type="radio"]')
    radios.at(0).setChecked()
    await flushPromises()
    radios.at(2).setChecked()
    radios.at(2).trigger('blur')
    await flushPromises()
    expect(radios.at(0).attributes('data-is-showing-errors')).toBe(undefined)
  })

  it('sets data-has-value when single checkbox has value, and removes it when it doesnt', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'checkbox' }
    })
    expect(wrapper.attributes('data-has-value')).toBe(undefined)
    await flushPromises()
    wrapper.find('input[type="checkbox"]').setChecked()
    await flushPromises()
    expect(wrapper.attributes('data-has-value')).toBe('true')
    wrapper.find('input[type="checkbox"]').setChecked(false)
    await flushPromises()
    expect(wrapper.attributes('data-has-value')).toBe(undefined)

  })

  it('sets data-has-value when box input has value and multiple options', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'radio', options: {first: 'First', second: 'Second', third: 'Third' }}
    })
    expect(wrapper.attributes('data-has-value')).toBe(undefined)
    await flushPromises()
    wrapper.find('input[type="radio"]').setChecked()
    await flushPromises()
    expect(wrapper.attributes('data-has-value')).toBe('true')
    const subBoxes = wrapper.findAll('[data-classification="box"]')
    expect(subBoxes.at(0).attributes('data-has-value')).toBe('true')
    expect(subBoxes.at(1).attributes('data-has-value')).toBe(undefined)
  })

  it('has the proper default element classes when grouped', () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'radio', options: {first: 'First', second: 'Second', third: 'Third' }, elementClass: ['extra']}
    })

    // NOTE: the .formulate-input-group class should be deprecated.
    expect(wrapper.findComponent(FormulateInputGroup).attributes('class'))
      .toBe('formulate-input-element formulate-input-element--group formulate-input-group extra')
  })

  it('can add classes to the element wrapper', () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'checkbox', elementClass: ['test-class']}
    })
    expect(wrapper.findComponent(FormulateInputBox).attributes('class'))
      .toBe('formulate-input-element formulate-input-element--checkbox test-class')
  })


  it('can add classes to the input element', () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'checkbox', inputClass: ['test-class']}
    })
    expect(wrapper.find('input').attributes('class'))
      .toBe('test-class')
  })

  it('allows overriding the decorator class', () => {
    const wrapper = mount(FormulateInput, {
      propsData: {
        type: 'checkbox',
        value: '123',
        decoratorClass: 'custom-class'
      }
    })
    expect(wrapper.find('label.custom-class').exists()).toBe(true);
  })

  it('emits a focus event', async () => {
    const focus = jest.fn()
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'checkbox' },
      listeners: { focus }
    })
    wrapper.find('input[type="checkbox"]').trigger('focus')
    await flushPromises()
    expect(focus.mock.calls.length).toBe(1);
  })

  it('allows slot injection of of a prefix and suffix single checkbox', async () => {
    const wrapper = mount({
      template: `
        <FormulateInput
          type="checkbox"
          label="money"
          value="yes"
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

  it('allows slot injection of of a prefix and suffix multiple checkboxes', async () => {
    const wrapper = mount({
      template: `
        <FormulateInput
          type="text"
          label="money"
          :options="['First', 'Second']"
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
