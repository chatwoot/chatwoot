import Vue from 'vue'
import flushPromises from 'flush-promises'
import { mount } from '@vue/test-utils'
import Formulate from '@/Formulate.js'
import FormulateSchema from '@/FormulateSchema.js'
import FormulateInput from '@/FormulateInput.vue'

Vue.use(Formulate)

describe('FormulateSchema', () => {
  it('renders a FormulateInput by default', async () => {
    const wrapper = mount(FormulateSchema, { propsData: { schema: [
      {}
    ]}})
    expect(wrapper.findComponent(FormulateInput).exists()).toBe(true)
  })

  it('can render a standard div', async () => {
    const wrapper = mount(FormulateSchema, { propsData: { schema: [
      { component: 'div', class: 'test-div' }
    ]}})
    expect(wrapper.find('.test-div').exists()).toBe(true)
  })

  it('can render children', async () => {
    const wrapper = mount(FormulateSchema, { propsData: { schema: [
      { component: 'div', class: 'test-div', children: [{}] }
    ]}})
    expect(wrapper.find('.test-div .formulate-input').exists()).toBe(true)
  })

  it('can render children inside a group input', async () => {
    const wrapper = mount(FormulateSchema, { propsData: { schema: [
      { type: 'group', repeatable: true, children: [{}] }
    ]}})
    expect(wrapper.findAll('.formulate-input').length)
      .toBe(3)
    wrapper.find('.formulate-input-group-add-more button').trigger('click')
    await flushPromises()
    expect(wrapper.findAll('.formulate-input').length)
      .toBe(4)
  })

  it('renders text nodes inside dom elements', async () => {
    const wrapper = mount(FormulateSchema, { propsData: { schema: [
      { component: 'h2', children: 'Hello world' }
    ]}})
    expect(wrapper.find('h2').text()).toBe('Hello world')
  })

  it('renders classes as classes and not attributes', async () => {
    const wrapper = mount(FormulateSchema, { propsData: { schema: [
      { component: 'h2', children: 'Hello world', class: {
        'has-this-one': true,
        'does-not-have': false
      } }
    ]}})
    expect(wrapper.find('h2').attributes('class')).toBe('has-this-one')
  })

  // This test is intended to recreate the conditions of issue #200
  // https://github.com/wearebraid/vue-formulate/issues/200
  it('can insert directly in between form elements without key confusions', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          :schema="schema"
          v-model="formData"
        />
      `,
      data () {
        return {
          formData: {}
        }
      },
      computed: {
        schema () {
          const baseSchema = [
            {
              type: "text",
              name: "firstName",
              help: 'type here to see next field'
            },
            {
              type: "text",
              name: "lastName",
              value: 'FOO'
            }
          ]
          return (this.formData.firstName) ? [
            baseSchema[0],
            {
              type: "text",
              name: "occupation",
              value: 'BAR'
            },
            baseSchema[1],
          ]
            : baseSchema
        }
      }
    })
    wrapper.findAll('input').at(1).setValue('FOOEY')
    wrapper.find('input').setValue('Justin')
    await flushPromises()
    expect(wrapper.findAll('input').wrappers.map(input => input.element.value)).toEqual(['Justin', 'BAR', 'FOOEY'])
  })

  it('can render two divs back to back with unique keys', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          :schema="schema"
        />
      `,
      data () {
        return {
          switch: true
        }
      },
      computed: {
        schema () {
          return [
            { component: 'div', 'data-is-first': true, children: this.switch ? 'abc' : 'def' },
            { component: 'div', 'data-is-second': true, children: this.switch ? 'def' : 'abc' }
          ]
        }
      }
    })
    expect(wrapper.find('[data-is-first]').text()).toBe('abc')
    wrapper.setData({ switch: false })
    await flushPromises()
    expect(wrapper.find('[data-is-first]').text()).toBe('def')
  })

  it('can uniquely key grouped inputs', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm
          :schema="schema"
        />
      `,
      data () {
        return {
          switch: true
        }
      },
      computed: {
        schema () {
          return [
            {
              type: 'group',
              value: [{}, {}],
              children: [
                { type: 'text', value: 'abc' },
                { type: 'text', value: 'def' }
              ]
            }
          ]
        }
      }
    })
  })

  it('can emit events from children', async () => {
    const customBlurHandler = jest.fn()
    const directlyCalled = jest.fn()
    const changedState = jest.fn()
    const wrapper = mount({
      template: `
      <FormulateForm
        :schema="schema"
        @blur="customBlurHandler"
        @changed-state="changedState"
      />`,
      data () {
        return {
          schema: [
            {
              name: 'username',
              '@input': directlyCalled
            },
            {
              name: 'password',
              '@blur': true
            },
            {
              component: 'div',
              children: [
                {
                  type: 'select',
                  name: 'state',
                  options: ['Kansas', 'Nebraska', 'Iowa'],
                  value: 'Iowa',
                  '@change': 'changed-state'
                }
              ]
            }
          ]
        }
      },
      methods: {
        customBlurHandler,
        changedState
      }
    })
    await flushPromises()
    wrapper.find('input[name="username"]').setValue('cooldude45')
    wrapper.find('input[name="password"]').trigger('blur')
    wrapper.find('option[value="Nebraska"]').setSelected('Nebraska')
    await flushPromises()
    expect(directlyCalled.mock.calls.length).toBe(1)
    expect(customBlurHandler.mock.calls.length).toBe(1)
    expect(customBlurHandler.mock.calls[0][0]).toBeInstanceOf(FocusEvent)
    expect(changedState.mock.calls.length).toBe(1)
  })
})
