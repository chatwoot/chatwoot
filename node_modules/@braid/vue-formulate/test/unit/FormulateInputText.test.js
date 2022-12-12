import Vue from 'vue'
import flushPromises from 'flush-promises'
import { mount } from '@vue/test-utils'
import Formulate from '../../src/Formulate.js'
import FormulateInput from '@/FormulateInput.vue'
import FormulateInputText from '@/inputs/FormulateInputText.vue'
import { doesNotReject } from 'assert';

Vue.use(Formulate)

/**
 * Test each type of text element
 */

describe('FormulateInputText', () => {
  it('renders text input when type is "text"', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text' } })
    expect(wrapper.findComponent(FormulateInputText).exists()).toBe(true)
  })

  it('renders search input when type is "search"', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'search' } })
    expect(wrapper.findComponent(FormulateInputText).exists()).toBe(true)
  })

  it('renders email input when type is "email"', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'email' } })
    expect(wrapper.findComponent(FormulateInputText).exists()).toBe(true)
  })

  it('renders number input when type is "number"', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'number' } })
    expect(wrapper.findComponent(FormulateInputText).exists()).toBe(true)
  })

  it('renders color input when type is "color"', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'color' } })
    expect(wrapper.findComponent(FormulateInputText).exists()).toBe(true)
  })

  it('renders date input when type is "date"', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'date' } })
    expect(wrapper.findComponent(FormulateInputText).exists()).toBe(true)
  })

  it('renders month input when type is "month"', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'month' } })
    expect(wrapper.findComponent(FormulateInputText).exists()).toBe(true)
  })

  it('renders password input when type is "password"', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'password' } })
    expect(wrapper.findComponent(FormulateInputText).exists()).toBe(true)
  })

  it('renders tel input when type is "tel"', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'tel' } })
    expect(wrapper.findComponent(FormulateInputText).exists()).toBe(true)
  })

  it('renders time input when type is "time"', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'time' } })
    expect(wrapper.findComponent(FormulateInputText).exists()).toBe(true)
  })

  it('renders url input when type is "url"', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'url' } })
    expect(wrapper.findComponent(FormulateInputText).exists()).toBe(true)
  })

  it('renders week input when type is "week"', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'week' } })
    expect(wrapper.findComponent(FormulateInputText).exists()).toBe(true)
  })

  /**
   * Test rendering functionality to text inputs
   */

  it('automatically assigns an id', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text' } })
    expect(wrapper.vm.context).toHaveProperty('id')
    expect(wrapper.find(`input[id="${wrapper.vm.context.attributes.id}"]`).exists()).toBe(true)
  })

  it('passes an explicitly given name prop through to the root text element', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text', name: 'foo' } })
    expect(wrapper.find('input[name="foo"]').exists()).toBe(true)
  })

  it('passes an explicitly given name prop through to the root textarea element', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'textarea', name: 'foo' } })
    expect(wrapper.find('textarea[name="foo"]').exists()).toBe(true)
  })

  it('additional context does not bleed through to text input attributes', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text' } } )
    expect(Object.keys(wrapper.find('input[type="text"]').attributes())).toEqual(["type", "id"])
  })

  it('additional context does not bleed through to textarea input attributes', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'textarea' } } )
    expect(Object.keys(wrapper.find('textarea').attributes())).toEqual(["id"])
  })

  it('doesn’t automatically add a label', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text' } })
    expect(wrapper.find('label').exists()).toBe(false)
  })

  it('renders labels', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text', label: 'Field label' } })
    expect(wrapper.find(`label[for="${wrapper.vm.context.attributes.id}"]`).exists()).toBe(true)
  })

  it('doesn’t automatically render help text', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text' } })
    expect(wrapper.find(`.formulate-input-help`).exists()).toBe(false)
  })

  it('renders help text', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text', help: 'This is some help text' } })
    expect(wrapper.find(`.formulate-input-help`).exists()).toBe(true)
  })

  /**
   * Test data binding
   */
  it('emits input (vmodel) event with value when edited', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text' } })
    wrapper.find('input').setValue('Updated Value')
    expect(wrapper.emitted().input).toBeTruthy()
    expect(wrapper.emitted().input[0]).toEqual(['Updated Value'])
  })


  it('doesn’t re-context itself if there were no changes', async () => {
    const wrapper = mount({
      data () {
        return {
          valueA: 'first value',
          valueB: 'second value'
        }
      },
      template: `
        <div>
          <FormulateInput type="text" ref="first" v-model="valueA" :placeholder="valueA" />
          <FormulateInput type="text" ref="second" v-model="valueB" :placeholder="valueB" />
        </div>
      `
    })
    await flushPromises()
    const firstContext = wrapper.findComponent({ref: "first"}).vm.context
    const secondContext = wrapper.findComponent({ref: "second"}).vm.context
    wrapper.find('input').setValue('new value')
    await flushPromises()
    expect(firstContext).toBeTruthy()
    expect(wrapper.vm.valueA === 'new value').toBe(true)
    expect(wrapper.vm.valueB === 'second value').toBe(true)
    expect(wrapper.findComponent({ref: "first"}).vm.context === firstContext).toBe(false)
    expect(wrapper.findComponent({ref: "second"}).vm.context === secondContext).toBe(true)
  })

  it('uses the v-model value as the initial value', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text', formulateValue: 'initial val' } })
    expect(wrapper.find('input').element.value).toBe('initial val')
  })

  it('uses the value as the initial value', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text', value: 'initial val' } })
    expect(wrapper.find('input').element.value).toBe('initial val')
  })

  it('uses the value prop as the initial value when v-model provided', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text', formulateValue: 'initial val', value: 'initial other val' } })
    expect(wrapper.find('input').element.value).toBe('initial other val')
  })

  it('uses a proxy model internally if it doesnt have a v-model', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'textarea' } })
    const input = wrapper.find('textarea')
    input.setValue('changed value')
    expect(wrapper.vm.proxy).toBe('changed value')
  })


  /**
   * Test error handling
   */
  it('doesn’t automatically render errors', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text' } })
    expect(wrapper.find('.formulate-input-errors').exists()).toBe(false)
  })

  it('accepts a single string as an error prop', async () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text', error: 'This is an error' } })
    expect(wrapper.find('.formulate-input-errors').exists()).toBe(true)
  })

  it('accepts an array as errors prop', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text', errorBehavior: 'live', errors: ['This is an error', 'this is another'] } })
    expect(wrapper.findAll('.formulate-input-error').length).toBe(2)
  })

  it('removes any duplicate errors', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text', errorBehavior: 'live', errors: ['This is an error', 'This is an error'] } })
    expect(wrapper.findAll('.formulate-input-error').length).toBe(1)
  })

  it('adds data-has-errors when there are errors', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text', errorBehavior: 'live', errors: ['This is an error', 'This is an error'] } })
    expect(wrapper.find('[data-has-errors]').exists()).toBe(true)
  })

  it('Should always show explicitly set errors, but not validation errors', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text', validation: 'required', errorBehavior: 'blur', errors: ['Bad input'] } })
    expect(wrapper.find('[data-has-errors]').exists()).toBe(true)
    expect(wrapper.find('[data-is-showing-errors]').exists()).toBe(true)
    expect(wrapper.findAll('.formulate-input-error').length).toBe(1)
  })

  it('Should show no errors when there are no errors', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text' } })
    expect(wrapper.find('[data-has-errors]').exists()).toBe(false)
    expect(wrapper.find('[data-is-showing-errors]').exists()).toBe(false)
    expect(wrapper.findAll('.formulate-input-error').exists()).toBe(false)
  })

  it('allows error-behavior blur to be overridden with show-errors', async () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text', errorBehavior: 'blur', showErrors: true, validation: 'required' } })
    await flushPromises()
    expect(wrapper.find('[data-has-errors]').exists()).toBe(true)
    expect(wrapper.find('[data-is-showing-errors]').exists()).toBe(true)
    expect(wrapper.findAll('.formulate-input-errors').exists()).toBe(true)
    expect(wrapper.findAll('.formulate-input-error').length).toBe(1)
  })

  it('shows errors on blur with error-behavior blur', async () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text', errorBehavior: 'blur', validation: 'required' } })
    await wrapper.vm.$nextTick()
    await flushPromises()
    expect(wrapper.find('[data-has-errors]').exists()).toBe(true)
    expect(wrapper.find('[data-is-showing-errors]').exists()).toBe(false)
    expect(wrapper.findAll('.formulate-input-error').exists()).toBe(false)
    expect(wrapper.vm.showValidationErrors).toBe(false)
    wrapper.find('input').trigger('blur')
    await flushPromises()
    expect(wrapper.vm.showValidationErrors).toBe(true)
    expect(wrapper.find('[data-is-showing-errors]').exists()).toBe(true)
    // expect(wrapper.findAll('.formulate-input-errors').exists()).toBe(true)
    // expect(wrapper.findAll('.formulate-input-error').length).toBe(1)
  })

  it('continues to show errors if validation fires more than one time', async () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'date', errorBehavior: 'live', validation: [['after', '01/01/2021']] , value: '01/01/1999' } })
    await wrapper.vm.$nextTick()
    await flushPromises()
    expect(wrapper.find('[data-has-errors]').exists()).toBe(true)
    wrapper.find('input').trigger('input')
    await wrapper.vm.$nextTick()
    await flushPromises()
    expect(wrapper.find('[data-has-errors]').exists()).toBe(true)
  })

  it('allows label-before override with scoped slot', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'text', label: 'flavor' },
      scopedSlots: {
        label: '<label>{{ props.label }} town</label>'
      }
    })
    expect(wrapper.find('label').text()).toBe('flavor town')
  })

  it('allows label-after override with scoped slot', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'text', label: 'flavor', labelPosition: 'after' },
      scopedSlots: {
        label: '<label>{{ props.label }} town</label>'
      }
    })
    expect(wrapper.find('label').text()).toBe('flavor town')
  })

  it('allows help-before override', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'text', label: 'flavor', help: 'I love this next field...', helpPosition: 'before' },
    })
    expect(wrapper.find('label + *').classes('formulate-input-help')).toBe(true)
  })

  it('Allow help text override with scoped slot', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'text', name: 'soda', help: 'Do you want some'},
      scopedSlots: {
        help: '<small>{{ props.help }} {{ props.name }}?</small>'
      }
    })
    expect(wrapper.find('small').text()).toBe('Do you want some soda?')
  })

  it('Allow errors override with scoped slot', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'text', name: 'soda', validation: 'required|in:foo,bar', errorBehavior: 'live' },
      scopedSlots: {
        errors: '<ul class="my-errors"><li v-for="error in props.visibleValidationErrors">{{ error }}</li></ul>'
      }
    })
    await flushPromises();
    expect(wrapper.findAll('.my-errors li').length).toBe(2)
  })


  it('Output the model value inside a scoped slot', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'text', name: 'soda', help: 'Do you want some'},
      scopedSlots: {
        help: '<small>{{ props.help }} {{ props.model }} {{ props.name }} {{ props.labelPosition }}?</small>'
      }
    })
    wrapper.find('input').setValue('cherry')
    await flushPromises()
    expect(wrapper.find('small').text()).toBe('Do you want some cherry soda before?')
  })

  it('sets role="status" attribute for input errors', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text', errorBehavior: 'live', errors: ['error 1', 'error 2'] } })
    expect(wrapper.find('[role="status"]').exists()).toBe(true)
    expect(wrapper.findAll('[role="status"]').length).toBe(2)
  })

  it('sets aria-live="polite" attribute for input errors', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text', errorBehavior: 'live', errors: ['error 1', 'error 2', 'error 3'] } })
    expect(wrapper.find('[aria-live="polite"]').exists()).toBe(true)
    expect(wrapper.findAll('[aria-live="polite"]').length).toBe(3)
  })

  it('sets data-has-value when it has a value', async () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text' }})
    expect(wrapper.attributes('data-has-value')).toBe(undefined)
    wrapper.find('input').setValue('abc123')
    await flushPromises()
    expect(wrapper.attributes('data-has-value')).toBe('true')
    wrapper.find('input').setValue('')
    await flushPromises()
    expect(wrapper.attributes('data-has-value')).toBe(undefined)
  })


  it('can add classes to the element wrapper', () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'number', elementClass: ['test-class']}
    })
    expect(wrapper.findComponent(FormulateInputText).attributes('class'))
      .toBe('formulate-input-element formulate-input-element--number test-class')
  })

  it('can add classes to the input element', () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'datetime-local', inputClass: ['test-class']}
    })
    expect(wrapper.find('input').attributes('class'))
      .toBe('test-class')
  })

  it('emits a focus event', async () => {
    const focus = jest.fn()
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'text', min: 0, max: 100 },
      listeners: { focus }
    })
    wrapper.find('input[type="text"]').trigger('focus')
    await flushPromises()
    expect(focus.mock.calls.length).toBe(1);
  })

  it('emits a blur event', async () => {
    const blur = jest.fn()
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'text', min: 0, max: 100 },
      listeners: { blur }
    })
    const input = wrapper.find('input[type="text"]')

    input.trigger('blur')
    await flushPromises()
    expect(blur.mock.calls.length).toBe(1);
  })

  it('allows slot injection of of a prefix and suffix', async () => {
    const wrapper = mount({
      template: `
        <FormulateInput
          type="text"
          label="money"
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
