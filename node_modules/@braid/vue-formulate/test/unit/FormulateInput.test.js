import Vue from 'vue'
import flushPromises from 'flush-promises'
import { mount, createLocalVue } from '@vue/test-utils'
import Formulate from '@/Formulate.js'
import FormulateForm from '@/FormulateForm.vue'
import FormulateInput from '@/FormulateInput.vue'
import FormulateInputBox from '@/inputs/FormulateInputBox.vue'
import { classKeys } from '@/libs/classes'

const globalRule = jest.fn((context) => { return false })
const options = {
  locales: {
    en: {
      email: ({ value }) => `Super invalid email: ${value}`
    }
  },
  rules: {
    globalRule
  },
  library: {
    special: {
      classification: 'box',
      component: 'FormulateInputBox'
    }
  },
  useInputDecorators: true,
  validationNameStrategy: false
}
Vue.use(Formulate, options)

const resetInstance = () => {
  Formulate.install(Vue, options)
}

describe('FormulateInput', () => {
  it('sets unknown classification if not in library', () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'foobar',
    } })
    expect(wrapper.vm.classification).toBe('unknown')
  })

  it('uses a hard-coded fallback validation error if no default rules exist', async () => {
    const localVue = createLocalVue()
    localVue.use(Formulate, { rules: { foobar: () => false }, locales: { en: 'xyz' } })
    const wrapper = mount(FormulateInput, { localVue, propsData: { validation: 'foobar', errorBehavior: 'live' }})
    await flushPromises()
    expect(wrapper.find('.formulate-input-error').text()).toBe('Invalid field value')
    resetInstance()
  })

  it('allows custom field-rule level validation strings', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'required|in:abcdef',
      validationMessages: {in: 'the value was different than expected'},
      errorBehavior: 'live',
      value: 'other value'
    } })
    await flushPromises()
    expect(wrapper.find('.formulate-input-error').text()).toBe('the value was different than expected')
  })

  it('allows custom field-rule level validation functions', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'required|in:abcdef',
      validationMessages: { in: ({ value }) => `The string ${value} is not correct.` },
      errorBehavior: 'live',
      value: 'other value'
    } })
    await flushPromises()
    expect(wrapper.find('.formulate-input-error').text()).toBe('The string other value is not correct.')
  })

  it('uses globally overridden validation messages', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'required|email',
      errorBehavior: 'live',
      value: 'wrong email'
    } })
    await flushPromises()
    expect(wrapper.find('.formulate-input-error').text()).toBe('Super invalid email: wrong email')
  })

  it('uses custom async validation rules on defined on the field', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'required|foobar',
      validationMessages: {
        foobar: 'failed the foobar check'
      },
      validationRules: {
        foobar: async ({ value }) => value === 'foo'
      },
      errorBehavior: 'live',
      value: 'bar'
    } })
    await flushPromises()
    expect(wrapper.find('.formulate-input-error').text()).toBe('failed the foobar check')
  })

  it('uses custom sync validation rules on defined on the field', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'required|foobar',
      validationMessages: {
        foobar: 'failed the foobar check'
      },
      validationRules: {
        foobar: ({ value }) => value === 'foo'
      },
      errorBehavior: 'live',
      value: 'bar'
    } })
    await flushPromises()
    expect(wrapper.find('.formulate-input-error').text()).toBe('failed the foobar check')
  })

  it('uses global custom validation rules', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'required|globalRule',
      errorBehavior: 'live',
      value: 'bar'
    } })
    await flushPromises()
    expect(globalRule.mock.calls.length).toBe(1)
  })

  it('skips validation when the optional rule exists fields', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'optional|min:6,length',
      errorBehavior: 'live'
    }})
    await flushPromises()
    expect(wrapper.vm.context.validationErrors.length).toBe(0)
  })

  it('skips validation when the optional rule is at the stack end', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'min:6,length|optional',
      errorBehavior: 'live'
    }})
    await flushPromises()
    expect(wrapper.vm.context.validationErrors.length).toBe(0)
  })

  it('ignores modifiers on the optional rule', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: '^optional|min:6,length|max:10',
      errorBehavior: 'live'
    }})
    await flushPromises()
    expect(wrapper.vm.context.validationErrors.length).toBe(0)
  })

  it('skips validation when the optional rule is used with required', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'optional|required|min:6,length',
      errorBehavior: 'live'
    }})
    await flushPromises()
    expect(wrapper.vm.context.validationErrors.length).toBe(0)
  })

  it('skips validation when the optional rule is used in array format', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: [
        ['optional'],
        ['required'],
        ['min', '6', 'length'],
      ],
      errorBehavior: 'live'
    }})
    await flushPromises()
    expect(wrapper.vm.context.validationErrors.length).toBe(0)
  })

  it('remaining validation rules after passing the optional rule', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'optional|min:6,length|max:10',
      errorBehavior: 'live'
    }})
    wrapper.find('input').setValue('hi')
    await flushPromises()
    expect(wrapper.vm.context.validationErrors.length).toBe(1)
  })

  it('can extend its standard library of inputs', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'special',
      validation: 'required',
      errorBehavior: 'live',
      value: 'bar'
    } })
    await flushPromises()
    expect(wrapper.findComponent(FormulateInputBox).exists()).toBe(true)
  })

  it('emits correct validation event', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
        type: 'text',
        validation: 'required',
        errorBehavior: 'live',
        value: '',
        name: 'testinput',
      } })
    await flushPromises()
    const errorObject = wrapper.emitted('validation')[0][0]
    expect(errorObject).toEqual({
      name: 'testinput',
      errors: [
        expect.any(String)
      ],
      hasErrors: true
    })
  })

  it('emits a error-visibility event on blur', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'required',
      errorBehavior: 'blur',
      value: '',
      name: 'testinput',
    } })
    await flushPromises()
    expect(wrapper.emitted('error-visibility')[0][0]).toBe(false)
    wrapper.find('input[type="text"]').trigger('blur')
    await flushPromises()
    expect(wrapper.emitted('error-visibility')[1][0]).toBe(true)
  })

  it('emits error-visibility event immediately when live', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'required',
      errorBehavior: 'live',
      value: '',
      name: 'testinput',
    } })
    await flushPromises()
    expect(wrapper.emitted('error-visibility').length).toBe(1)
  })

  it('Does not emit an error-visibility event if visibility did not change', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'in:xyz',
      errorBehavior: 'live',
      value: 'bar',
      name: 'testinput',
    } })
    await flushPromises()
    expect(wrapper.emitted('error-visibility').length).toBe(1)
    wrapper.find('input[type="text"]').setValue('bar')
    await flushPromises()
    expect(wrapper.emitted('error-visibility').length).toBe(1)
  })

  it('allows overriding the label default slot component', async () => {
    const localVue = createLocalVue()
    localVue.component('CustomLabel', {
      render: function (h) {
        return h('div', { class: 'custom-label' }, [`custom: ${this.context.label}`])
      },
      props: ['context']
    })
    localVue.use(Formulate, { slotComponents: { label: 'CustomLabel' } })
    const wrapper = mount(FormulateInput, { localVue, propsData: { label: 'My label here' } })
    expect(wrapper.find('.custom-label').html()).toBe('<div class="custom-label">custom: My label here</div>')
  })

  it('allows overriding the help default slot component', async () => {
    const localVue = createLocalVue()
    localVue.component('CustomHelp', {
      render: function (h) {
        return h('small', { class: 'custom-help' }, [`custom: ${this.context.help}`])
      },
      props: ['context']
    })
    localVue.use(Formulate, { slotComponents: { help: 'CustomHelp' } })
    const wrapper = mount(FormulateInput, { localVue, propsData: { help: 'My help here' } })
    expect(wrapper.find('.custom-help').html()).toBe('<small class="custom-help">custom: My help here</small>')
  })

  it('allows overriding the errors component', async () => {
    const localVue = createLocalVue()
    localVue.component('CustomErrors', {
      render: function (h) {
        return h('ul', { class: 'my-errors' }, this.context.visibleValidationErrors.map(message => h('li', message)))
      },
      props: ['context']
    })
    localVue.use(Formulate, { slotComponents: { errors: 'CustomErrors' } })
    const wrapper = mount(FormulateInput, { localVue, propsData: {
      help: 'My help here',
      errorBehavior: 'live',
      validation: 'required'
    } })
    await flushPromises()
    expect(wrapper.find('.my-errors').html())
      .toBe(`<ul class="my-errors">\n  <li>Text is required.</li>\n</ul>`)
    // Clean up after this call — we should probably get rid of the singleton all together....
    Formulate.extend({ slotComponents: { errors: 'FormulateErrors' }})
  })

  it('links help text with `aria-describedby`', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: {
        type: 'text',
        validation: 'required',
        errorBehavior: 'live',
        value: 'bar',
        help: 'Some help text'
      }
    })
    await flushPromises()
    const id = `${wrapper.vm.context.id}-help`
    expect(wrapper.find('input').attributes('aria-describedby')).toBe(id)
    expect(wrapper.find('.formulate-input-help').attributes().id).toBe(id)
  });

  it('it does not use aria-describedby if there is no help text', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: {
        type: 'text',
        validation: 'required',
        errorBehavior: 'live',
        value: 'bar',
      }
    })
    await flushPromises()
    expect(wrapper.find('input').attributes('aria-describedby')).toBeFalsy()
  });

  it('it allows overriding aria-describedby', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: {
        type: 'text',
        validation: 'required',
        errorBehavior: 'live',
        value: 'bar',
        help: 'abc',
        'aria-describedby': 'other-id'
      }
    })
    await flushPromises()
    expect(wrapper.find('input').attributes('aria-describedby')).toBe('other-id')
  });

  it('can bail on validation when encountering the bail rule', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'text', validation: 'bail|required|in:xyz', errorBehavior: 'live' }
    })
    await flushPromises();
    expect(wrapper.vm.context.visibleValidationErrors.length).toBe(1);
  })

  it('continues to bail after content was entered', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'text', name: 'letters', validation: 'bail|required|in:xyz', errorBehavior: 'live' }
    })
    await flushPromises();
    wrapper.find('input').setValue('xyz')
    await flushPromises()
    expect(wrapper.findAll('.formulate-input-errors li').length).toBe(0);
    wrapper.find('input').setValue('')
    await flushPromises()
    expect(wrapper.findAll('.formulate-input-errors li').length).toBe(1);
    expect(wrapper.find('.formulate-input-errors li').text()).toBe('Letters is required.');
  })

  it('can show multiple validation errors if they occur before the bail rule', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'text', validation: 'required|in:xyz|bail', errorBehavior: 'live' }
    })
    await flushPromises();
    expect(wrapper.vm.context.visibleValidationErrors.length).toBe(2);
  })

  it('can avoid bail behavior by using modifier', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'text', validation: '^required|in:xyz|min:10,length', errorBehavior: 'live', value: '123' }
    })
    await flushPromises();
    expect(wrapper.vm.context.visibleValidationErrors.length).toBe(2);
  })

  it('prevents later error messages when modified rule fails', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'text', validation: '^required|in:xyz|min:10,length', errorBehavior: 'live' }
    })
    await flushPromises();
    expect(wrapper.vm.context.visibleValidationErrors.length).toBe(1);
  })

  it('can bail in the middle of the rule set with a modifier', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'text', validation: 'required|^in:xyz|min:10,length', errorBehavior: 'live' }
    })
    await flushPromises();
    expect(wrapper.vm.context.visibleValidationErrors.length).toBe(2);
  })

  it('does not show errors on blur when set error-behavior is submit', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'required',
      errorBehavior: 'submit',
    } })
    wrapper.find('input').trigger('input')
    wrapper.find('input').trigger('blur')
    await flushPromises()
    expect(wrapper.find('.formulate-input-errors').exists()).toBe(false)
  })

  it('does not show errors initially when error-behavior is value', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'required',
      errorBehavior: 'value',
    } })
    wrapper.find('input').trigger('input')
    await flushPromises()
    expect(wrapper.find('.formulate-input-errors').exists()).toBeFalsy()
  })

  it('shows errors when error-behavior is value and an input is blurred', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'required',
      errorBehavior: 'value',
    } })
    wrapper.find('input').trigger('blur')
    await flushPromises()
    expect(wrapper.find('.formulate-input-errors').exists()).toBeTruthy()
  })

  it('shows errors initially when error-behavior is value and it has a value', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'required|email',
      errorBehavior: 'value',
      value: 'test'
    } })
    wrapper.find('input').setValue('Added some text')
    await flushPromises()
    expect(wrapper.vm.touched).toBe(true)
    expect(wrapper.find('.formulate-input-errors').exists()).toBeTruthy()
  })

  it('hides errors initially, and then shows them after first touch when error-behavior is value', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'required|email',
      errorBehavior: 'value'
    } })
    await flushPromises()
    expect(wrapper.find('.formulate-input-errors').exists()).toBeFalsy()
    wrapper.find('input').setValue('Added some text')
    await flushPromises()
    expect(wrapper.find('.formulate-input-errors').exists()).toBeTruthy()
  })

  it('displays errors when error-behavior is submit and form is submitted', async () => {
    const wrapper = mount(FormulateForm, {
      slots: {
        default: `<FormulateInput error-behavior="submit" validation="required" />`
      }
    })
    wrapper.trigger('submit')
    await flushPromises()
    expect(wrapper.find('.formulate-input-errors').exists()).toBe(true)
  })

  it('passes $emit to rootEmit inside the context object', async () => {
    const wrapper = mount(FormulateInput, {
      propsData: { type: 'text' }
    })
    wrapper.vm.context.rootEmit('foo', 'bar')
    await flushPromises()
    expect(wrapper.emitted().foo[0]).toEqual(['bar'])
  })

  it('allows getFormValues inside of custom validation messages', async () => {
    const wrapper = mount({
      template: `
        <FormulateForm>
          <FormulateInput type="text" name="first" />
          <FormulateInput type="text"  name="last" />
          <FormulateInput
            type="text"
            name="name"
            validation="fullName"
            :validation-rules="{ fullName }"
            :validation-messages="{ fullName: fullNameMessage }"
            error-behavior="live"
          />
        </FormulateForm>
      `,
      methods: {
        fullName ({ value, getFormValues }) {
          const values = getFormValues()
          return `${values.first} ${values.last}` === value
        },
        fullNameMessage ({ value, formValues }) {
          return `${formValues.first} ${formValues.last} does not equal ${value}.`
        }
      }
    })
    await flushPromises()
    const inputs = wrapper.findAll('input[type="text"]')
    inputs.at(0).setValue('jon')
    inputs.at(1).setValue('baley')
    inputs.at(2).setValue('jon baley')
    await flushPromises()
    expect(wrapper.find('.formulate-input-errors').exists()).toBe(false)
    inputs.at(1).setValue('parker')
    await flushPromises()
    expect(wrapper.find('.formulate-input-errors').exists()).toBe(true)
    expect(wrapper.find('.formulate-input-errors li').text()).toBe('jon parker does not equal jon baley.')
  })

  it('emits an input event a single time on change', async () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text' }})
    await flushPromises()
    wrapper.find('input').setValue('a')
    await flushPromises()
    expect(wrapper.emitted().input.length).toBe(1);
  })

  it('allows you to replace classes on the outer element', () => {
    const wrapper = mount({
      template: `<FormulateInput type='text' class='my-custom-class' />`
    })
    expect(wrapper.attributes('class')).toBe('my-custom-class formulate-input')
  })
  it('has formulate-input outer classes by default', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text' }})
    expect(wrapper.attributes('class')).toBe('formulate-input');
    expect(wrapper.find('.formulate-input > *').attributes('class')).toBe('formulate-input-wrapper')
  })

  it('has formulate-input-label wrapper classes by default', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text', label: 'blah' }})
    expect(wrapper.find('label').attributes('class')).toBe('formulate-input-label formulate-input-label--before');
  })

  it('can override the baseClasses function globally', () => {
    const localVue = createLocalVue()
    localVue.use(Formulate, {
      baseClasses () {
        return classKeys.reduce((classMap, key) => Object.assign(classMap, { [key]: 'my-class' }), {})
      }
    })
    const wrapper = mount(FormulateInput, { localVue, propsData: { type: 'text', label: 'blah' }})
    expect(wrapper.find('label').attributes('class')).toBe('my-class');
  })

  it('can override individual classKey globals', () => {
    const localVue = createLocalVue()
    localVue.use(Formulate, {
      classes: {
        label: 'label-class'
      }
    })
    const wrapper = mount(FormulateInput, { localVue, propsData: { type: 'text', label: 'blah' }})
    expect(wrapper.attributes('class')).toBe('formulate-input');
    expect(wrapper.find('label').attributes('class')).toBe('label-class');
  })

  it('can override individual classKey globals with functions', async () => {
    const localVue = createLocalVue()
    localVue.use(Formulate, {
      classes: {
        outer: (c, d) => d.concat(['adds-1-class']),
        wrapper: (c, d) => d.concat(['adds-2-class']),
        label: (c, d) => d.concat(['adds-3-class']),
        element: (c, d) => d.concat(['adds-4-class']),
        input: (c, d) => d.concat(['adds-5-class']),
        help: (c, d) => d.concat(['adds-6-class']),
        errors: (c, d) => d.concat(['adds-7-class']),
        error: (c, d) => d.concat(['adds-8-class'])
      }
    })
    const wrapper = mount(FormulateInput, { localVue, propsData: { type: 'text', label: 'foo', help: 'bar', errorBehavior: 'live', validation: 'required' }})
    await flushPromises()
    expect(wrapper.attributes('class')).toBe('formulate-input adds-1-class');
    // Test the wrapper override
    expect(wrapper.find('.formulate-input-wrapper').attributes('class'))
      .toBe('formulate-input-wrapper adds-2-class');
    // Test the label override
    expect(wrapper.find('label').attributes('class'))
      .toBe('formulate-input-label formulate-input-label--before adds-3-class');
    // Test the element override
    expect(wrapper.find('.formulate-input-element').attributes('class'))
      .toBe('formulate-input-element formulate-input-element--text adds-4-class');
    // Test the input override
    expect(wrapper.find('input').attributes('class'))
      .toBe('adds-5-class');
    // Test the input override
    expect(wrapper.find('.formulate-input-help').attributes('class'))
      .toBe('formulate-input-help formulate-input-help--after adds-6-class');
    // Test the errors wrapper
    expect(wrapper.find('.formulate-input-errors').attributes('class'))
      .toBe('formulate-input-errors adds-7-class');
    // Test the inner error
    expect(wrapper.find('.formulate-input-error').attributes('class'))
      .toBe('formulate-input-error adds-8-class');
  })

  it('allows you to fully override the class on the label element', () => {
    // We have to do this because the previous tests messed with the singleton object — ideally we should
    const localVue = createLocalVue()
    localVue.use(Formulate, {classes: {}})

    const wrapper = mount(FormulateInput, { propsData: { type: 'text', label: 'foobar', labelClass: 'my-custom-class' }})
    expect(wrapper.find('label').attributes('class')).toBe('my-custom-class')
  })

  it('allows you to modify all class keys via props', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      label: 'foo',
      help: 'bar',
      errorBehavior: 'live',
      validation: 'required',
      outerClass: ['custom-1-class'],
      wrapperClass: ['custom-2-class'],
      labelClass: ['custom-3-class'],
      elementClass: ['custom-4-class'],
      inputClass: ['custom-5-class'],
      helpClass: ['custom-6-class'],
      errorsClass: ['custom-7-class'],
      errorClass: ['custom-8-class'],
    }})
    await flushPromises();
    expect(wrapper.attributes('class')).toBe('formulate-input custom-1-class');
    // Test the wrapper override
    expect(wrapper.find('.formulate-input-wrapper').attributes('class'))
      .toBe('formulate-input-wrapper custom-2-class');
    // Test the label override
    expect(wrapper.find('label').attributes('class'))
      .toBe('formulate-input-label formulate-input-label--before custom-3-class');
    // Test the element override
    expect(wrapper.find('.formulate-input-element').attributes('class'))
      .toBe('formulate-input-element formulate-input-element--text custom-4-class');
    // Test the input override
    expect(wrapper.find('input').attributes('class'))
      .toBe('custom-5-class');
    // Test the input override
    expect(wrapper.find('.formulate-input-help').attributes('class'))
      .toBe('formulate-input-help formulate-input-help--after custom-6-class');
    // Test the errors wrapper
    expect(wrapper.find('.formulate-input-errors').attributes('class'))
      .toBe('formulate-input-errors custom-7-class');
    // Test the inner error
    expect(wrapper.find('.formulate-input-error').attributes('class'))
      .toBe('formulate-input-error custom-8-class');
  })

  it('responds to hasValue state class key', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      labelHasValueClass: 'field-has-value',
      label: 'My label'
    }})
    wrapper.find('input').setValue('some value')
    await flushPromises()
    expect(wrapper.find('label').attributes('class')).toBe('formulate-input-label formulate-input-label--before field-has-value')
  })

  it('responds to isValid and hasErrors state class key', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      validation: 'required',
      inputIsValidClass: 'is-valid-input',
      inputHasErrorsClass: 'is-invalid-input',
      errorBehavior: 'live'
    }})
    await flushPromises()
    expect(wrapper.find('input').attributes('class')).toBe('is-invalid-input')
    wrapper.find('input').setValue('some value')
    await flushPromises()
    expect(wrapper.find('input').attributes('class')).toBe('is-valid-input')
  })

  it('responds to globally registered hasValue on every element key', async () => {
    const localVue = createLocalVue()
    localVue.use(Formulate, {
      classes: {
        outerHasValue: 'has-1-value',
        wrapperHasValue: 'has-2-value',
        labelHasValue: 'has-3-value',
        elementHasValue: 'has-4-value',
        inputHasValue: 'has-5-value',
        helpHasValue: 'has-6-value',
        errorsHasValue: 'has-7-value',
        errorHasValue: 'has-8-value'
      }
    })
    const wrapper = mount(FormulateInput, { localVue, propsData: {
      type: 'text',
      label: 'foobar',
      help: 'barfoo',
      validation: 'required|in:123',
      errorBehavior: 'live'
    }})
    wrapper.find('input').setValue('foobar')
    await flushPromises()

    expect(wrapper.attributes('class')).toBe('formulate-input has-1-value');
    // Test the wrapper override
    expect(wrapper.find('.formulate-input-wrapper').attributes('class'))
      .toBe('formulate-input-wrapper has-2-value');
    // Test the label override
    expect(wrapper.find('label').attributes('class'))
      .toBe('formulate-input-label formulate-input-label--before has-3-value');
    // Test the element override
    expect(wrapper.find('.formulate-input-element').attributes('class'))
      .toBe('formulate-input-element formulate-input-element--text has-4-value');
    // Test the input override
    expect(wrapper.find('input').attributes('class'))
      .toBe('has-5-value');
    // Test the input override
    expect(wrapper.find('.formulate-input-help').attributes('class'))
      .toBe('formulate-input-help formulate-input-help--after has-6-value');
    // Test the errors wrapper
    expect(wrapper.find('.formulate-input-errors').attributes('class'))
      .toBe('formulate-input-errors has-7-value');
    // Test the inner error
    expect(wrapper.find('.formulate-input-error').attributes('class'))
      .toBe('formulate-input-error has-8-value');
    resetInstance()
  })

  it('assigns isValid irregardless of error-behavior', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      label: 'blah',
      labelIsValidClass: 'my-valid',
      errorBehavior: 'submit',
      validation: "required|in:foobar",
      value: '123'
    }})
    await flushPromises()
    expect(wrapper.find('label').attributes('class')).toBe('formulate-input-label formulate-input-label--before')
    wrapper.find('input').setValue('foobar')
    await flushPromises()
    expect(wrapper.find('label').attributes('class')).toBe('formulate-input-label formulate-input-label--before my-valid')
  })

  it('assigns hasErrors only when triggered by error visibility', async () => {
    const wrapper = mount(FormulateInput, { propsData: {
      type: 'text',
      inputHasErrorsClass: 'input-has-errors',
      errorBehavior: 'blur',
      validation: "required|in:foobar",
      value: '123'
    }})
    await flushPromises()
    expect(wrapper.find('input').attributes('class')).toBe(undefined)
    wrapper.vm.context.blurHandler()
    await flushPromises()
    expect(wrapper.find('input').attributes('class')).toBe('input-has-errors')
  })

  it('extracts pseudoProps when camelCase', () => {
    const wrapper = mount(FormulateInput, { propsData: { type: 'text', label: 'blah', labelClass: 'my-class' }})
    expect(wrapper.vm.pseudoProps['labelClass']).toBe('my-class')
  })

  it('extracts pseudoProps when kebab case', () => {
    const wrapper = mount({
      template: '<FormulateInput type="text" label="blah" label-class="my-class" />'
    })
    expect(wrapper.findComponent(FormulateInput).vm.pseudoProps['labelClass']).toBe('my-class')
  })

  it('removes slotProps from the attributes and passes it', async () => {
    const localVue = createLocalVue()
    localVue.component('MyCustomLabel', {
      functional: true,
      render: (h, { props }) => h('label', props.infoText)
    })
    localVue.component('MyCustomHelp', {
      functional: true,
      render: (h, { props }) => h('span', { class: 'my-help' }, props.infoHelp)
    })
    localVue.component('MyCustomErrors', {
      functional: true,
      render: (h, { props }) => {
        if (props.context.visibleValidationErrors.length) {
          return h('div', { class: 'my-errors' }, props.infoErrors)
        }
        return null
      }
    })
    localVue.component('MyAddMore', {
      functional: true,
      render: (h, { props }) => h('button', { class: 'my-add-more' }, props.infoAddMore)
    })
    // localVue.component('MyRepeatable', {
    //   functional: true,
    //   render: (h, { props }) => h('div', { class: 'my-repeatable' }, props.infoRepeatable)
    // })
    localVue.component('MyRemove', {
      functional: true,
      render: (h, { props }) => h('div', { class: 'my-remove' }, props.infoRemove)
    })

    localVue.use(Formulate, {
      slotProps: {
        label: ['infoText'],
        help: ['infoHelp'],
        errors: ['infoErrors'],
        addMore: ['infoAddMore'],
        // repeatable: ['infoRepeatable'],
        remove: ['infoRemove'],
      },
      slotComponents: {
        label: 'MyCustomLabel',
        help: 'MyCustomHelp',
        errors: 'MyCustomErrors',
        addMore: 'MyAddMore',
        // repeatable: 'MyRepeatable',
        remove: 'MyRemove'
      }
    })
    const wrapper = mount(FormulateInput, {
      localVue,
      propsData: {
        type: 'group',
        validation: 'min:5,length',
        value: [{ test: '123' }],
        repeatable: true,
        errorBehavior: 'live',
        help: 'foobar',
        label: 'blah',
        infoText: 'Some label text',
        infoHelp: 'Some help text',
        infoErrors: 'Some error text',
        infoAddMore: 'Add some goodies',
        // infoRepeatable: 'Repeat me',
        infoRemove: 'Get outta here'
      },
      slots: {
        default: '<FormulateInput type="text" name="test" />'
      }
    })
    await flushPromises()
    expect(wrapper.find('[info-text]').exists()).toBe(false)
    expect(wrapper.find('label').text()).toBe('Some label text')
    expect(wrapper.find('.my-help').text()).toBe('Some help text')
    expect(wrapper.find('.my-errors').text()).toBe('Some error text')
    expect(wrapper.find('.my-add-more').text()).toBe('Add some goodies')
    // expect(wrapper.find('.my-repeatable').text()).toBe('Repeat me')
    expect(wrapper.find('.my-remove').text()).toBe('Get outta here')
  })

  it('can remove all baseClasses globally', async () => {
    const localVue = createLocalVue()
    localVue.use(Formulate, {
      baseClasses: () => []
    })
    const wrapper = mount(FormulateInput, { localVue, propsData: {
      type: 'text',
      validation: 'required|in:abcdef',
      errorBehavior: 'live',
      label: 'foobar',
      help: 'foobar',
      value: 'other value'
    } })
    await flushPromises()
    expect(wrapper.find('.formulate-input').exists()).toBe(false)
    expect(wrapper.find('.formulate-input-label').exists()).toBe(false)
    expect(wrapper.find('.formulate-input-label--before').exists()).toBe(false)
    expect(wrapper.find('.formulate-input-help').exists()).toBe(false)
    resetInstance()
  })

  it('allows an empty string as a validation prop', async () => {
    const wrapper = mount(FormulateInput, { propsData: { validation: '', errorBehavior: 'live' }})
    await flushPromises()
    expect(wrapper.find('.formulate-errors').exists()).toBe(false)
  })

  it('allows access to attributes attrs in classes context object', async () => {
    const localVue = createLocalVue()
    localVue.use(Formulate, {
      classes: {
        input: (context, classes) => context.attrs.disabled ? classes.concat(['is-disabled']) : classes
      }
    })
    const wrapper = mount(FormulateInput, { localVue, propsData: {
      type: 'button',
      disabled: 'true'
    } })
    await flushPromises()
    expect(wrapper.find('button.is-disabled').exists()).toBe(true)
    resetInstance()
  })

  it('allows custom slotProps for custom inputs', async () => {
    const localVue = createLocalVue()
    localVue.component('MyCustomInput', {
      functional: true,
      render: (h, { props }) => h('button', { class: 'my-custom-input' }, props.customInputProp)
    })
    localVue.use(Formulate, {
      library: {
        'my-input': {
          classification: 'text',
          component: 'MyCustomInput'
        }
      },
      slotProps: {
        component: ['customInputProp']
      }
    })

    const wrapper = mount(FormulateInput, { localVue, propsData: {
      type: 'my-input',
      customInputProp: 'foo-bar'
    } })
    await flushPromises()
    expect(wrapper.find('button.my-custom-input').text()).toBe('foo-bar')
    resetInstance()
  })

  it('allows the disabling of input decorators with useInputDecorators: false', async () => {
    const localVue = createLocalVue()
    localVue.use(Formulate, {
      useInputDecorators: false
    })

    const wrapper = mount(FormulateInput, { localVue, propsData: {
      type: 'checkbox',
      options: {
        a: 'A',
        b: 'B'
      }
    } })
    await flushPromises()
    expect(wrapper.find('.formulate-input-element-decorator').exists()).toBeFalsy()
    resetInstance()
  })

  it('uses the validationName by default', async () => {
    const localVue = createLocalVue()
    localVue.use(Formulate, {
    })

    const wrapper = mount(FormulateInput, { localVue, propsData: {
      label: 'Hello world',
      name: 'something',
      validationName: 'This field',
      validation: 'required',
      errorBehavior: 'live'
    } })
    await flushPromises()
    expect(wrapper.find('.formulate-input-errors li').text()).toBe('This field is required.')
    resetInstance()
  })

  it('allows overriding the validation strategy via array', async () => {
    const localVue = createLocalVue()
    localVue.use(Formulate, {
      validationNameStrategy: ['label', 'name']
    })

    const wrapper = mount(FormulateInput, { localVue, propsData: {
      label: 'Hello world',
      name: 'something',
      validation: 'required',
      errorBehavior: 'live'
    } })
    await flushPromises()
    expect(wrapper.find('.formulate-input-errors li').text()).toBe('Hello world is required.')
    resetInstance()
  })

  it('allows overriding the validation strategy via function', async () => {
    const localVue = createLocalVue()
    localVue.use(Formulate, {
      validationNameStrategy: function (vm) {
        return vm.type === 'text' ? 'Some text' : vm.context.name
      }
    })

    const wrapper = mount(FormulateInput, { localVue, propsData: {
      label: 'Hello world',
      name: 'something',
      validation: 'required',
      errorBehavior: 'live'
    } })
    await flushPromises()
    expect(wrapper.find('.formulate-input-errors li').text()).toBe('Some text is required.')
    resetInstance()
  })

  it('sets the field based on the value over the v-model when both are set', async () => {
    const wrapper = mount({
      template: `<FormulateInput
        value="abc"
        v-model="modelValue"
      />`,
      data () {
        return {
          modelValue: '123'
        }
      }
    })
    await flushPromises()
    expect(wrapper.find('input').element.value).toBe('abc')
  })

  it('re-runs validation rules if the validation rules change', async () => {
    const wrapper = mount({
      template: `
        <FormulateInput
          :validation="validationRules"
          error-behavior="live"
          name="city"
        />
      `,
      data () {
        return {
          validationRules: 'required'
        }
      }
    })
    await flushPromises()
    expect(wrapper.find('.formulate-input-errors li').text()).toBe('City is required.')
    wrapper.vm.validationRules = 'optional'
    await flushPromises()
    expect(wrapper.find('.formulate-input-errors li').exists()).toBeFalsy()
  })

  it('exposes validation rules within the context object', async () => {
    const wrapper = mount({
      template: `
        <FormulateInput
          label="Email"
          validation="required"
        >
          <template #label="{ rules, label }">
            <label>{{ label }}{{ rules.some(({ ruleName }) => ruleName === 'required') ? '*' : '' }}</label>
          </template>
        </FormulateInput>
      `
    })
    expect(wrapper.find('label').text()).toBe('Email*')
  })

  it('can override the errorList slotComponent', async () => {
    const localVue = createLocalVue()
    localVue.component('CustomErrors', {
      render: function (h) {
        return h(
          'div',
          { class: 'custom-errors' },
          this.visibleErrors
            .map(error => h('div', { class: 'error-item', key: error }, error))
        )
      },
      props: ['visibleErrors']
    })
    localVue.use(Formulate, {
      slotComponents: {
        errorList: 'CustomErrors'
      }
    })
    const wrapper = mount(FormulateInput, {
      localVue,
      propsData: {
        name: 'name',
        validation: 'required',
        errorBehavior: 'live'
      }
    })
    await flushPromises()
    expect(wrapper.find('.formulate-input-error').exists()).toBeFalsy()
    expect(wrapper.find('.custom-errors .error-item').text()).toBe('Name is required.')
    resetInstance()
  })

  it('can override the prefix slotComponent', async () => {
    const localVue = createLocalVue()
    localVue.component('PrefixMe', {
      render: function (h) {
        return h(
          'div',
          { class: 'custom-prefix' },
          ['Hello there', this.context.name]
        )
      },
      props: ['context']
    })
    localVue.use(Formulate, {
      slotComponents: {
        prefix: 'PrefixMe'
      }
    })
    const wrapper = mount(FormulateInput, {
      localVue,
      propsData: {
        name: 'justin',
      }
    })
    await flushPromises()
    expect(wrapper.find('.formulate-input-element .custom-prefix').text()).toBe('Hello therejustin')
    resetInstance()
  })

  it('emits a blur-context event on blur', async () => {
    const listener = jest.fn();
    const wrapper = mount(FormulateInput, {
      propsData: {
        type: 'text',
        validation: 'required|email',
        value: 'not an email',
        errorBehavior: 'live'
      },
      listeners: {
        'blur-context': listener
      }
    })
    await flushPromises()
    wrapper.find('input').trigger('blur')
    await flushPromises()
    expect(listener.mock.calls.length).toBe(1)
    expect(listener.mock.calls[0][0].isValid).toBe(false)
  })

  it('can debounce a standard input', async () => {
    const isdebounced = jest.fn();
    const wrapper = mount(FormulateInput, {
      propsData: {
        type: 'text',
        validation: 'isdebounced',
        errorBehavior: 'live',
        debounce: 50,
        validationRules: {
          isdebounced
        }
      }
    })
    const input = wrapper.find('input')
    setTimeout(() => input.setValue('a'), 5)
    setTimeout(() => input.setValue('ab'), 10)
    setTimeout(() => input.setValue('abc'), 15)
    setTimeout(() => input.setValue('abcd'), 20)
    await new Promise(resolve => setTimeout(resolve, 100))
    expect(isdebounced.mock.calls.length).toBe(2)
    expect(isdebounced.mock.calls[1][0].value).toBe('abcd')
  })
})
