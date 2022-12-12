import { h, patchChildren } from './vval'

const NIL = () => null

const buildFromKeys = (keys, fn, keyFn) =>
  keys.reduce((build, key) => {
    build[keyFn ? keyFn(key) : key] = fn(key)
    return build
  }, {})

function isFunction(val) {
  return typeof val === 'function'
}

function isObject(val) {
  return val !== null && (typeof val === 'object' || isFunction(val))
}

function isPromise(object) {
  return isObject(object) && isFunction(object.then)
}

const getPath = (ctx, obj, path, fallback) => {
  if (typeof path === 'function') {
    return path.call(ctx, obj, fallback)
  }

  path = Array.isArray(path) ? path : path.split('.')
  for (let i = 0; i < path.length; i++) {
    if (obj && typeof obj === 'object') {
      obj = obj[path[i]]
    } else {
      return fallback
    }
  }

  return typeof obj === 'undefined' ? fallback : obj
}

import { withParams, pushParams, popParams } from './params'

const __isVuelidateAsyncVm = '__isVuelidateAsyncVm'
function makePendingAsyncVm(Vue, promise) {
  const asyncVm = new Vue({
    data: {
      p: true, // pending
      v: false // value
    }
  })

  promise.then(
    (value) => {
      asyncVm.p = false
      asyncVm.v = value
    },
    (error) => {
      asyncVm.p = false
      asyncVm.v = false
      throw error
    }
  )

  asyncVm[__isVuelidateAsyncVm] = true
  return asyncVm
}

const validationGetters = {
  $invalid() {
    const proxy = this.proxy
    return (
      this.nestedKeys.some((nested) => this.refProxy(nested).$invalid) ||
      this.ruleKeys.some((rule) => !proxy[rule])
    )
  },
  $dirty() {
    if (this.dirty) {
      return true
    }
    if (this.nestedKeys.length === 0) {
      return false
    }

    return this.nestedKeys.every((key) => this.refProxy(key).$dirty)
  },
  $anyDirty() {
    if (this.dirty) {
      return true
    }
    if (this.nestedKeys.length === 0) {
      return false
    }

    return this.nestedKeys.some((key) => this.refProxy(key).$anyDirty)
  },
  $error() {
    return this.$dirty && !this.$pending && this.$invalid
  },
  $anyError() {
    if (this.$error) return true

    return this.nestedKeys.some((key) => this.refProxy(key).$anyError)
  },
  $pending() {
    return (
      this.ruleKeys.some((key) => this.getRef(key).$pending) ||
      this.nestedKeys.some((key) => this.refProxy(key).$pending)
    )
  },
  $params() {
    const vals = this.validations
    return {
      ...buildFromKeys(
        this.nestedKeys,
        (key) => (vals[key] && vals[key].$params) || null
      ),
      ...buildFromKeys(this.ruleKeys, (key) => this.getRef(key).$params)
    }
  }
}

function setDirtyRecursive(newState) {
  this.dirty = newState
  const proxy = this.proxy
  const method = newState ? '$touch' : '$reset'
  this.nestedKeys.forEach((key) => {
    proxy[key][method]()
  })
}

const validationMethods = {
  $touch() {
    setDirtyRecursive.call(this, true)
  },
  $reset() {
    setDirtyRecursive.call(this, false)
  },
  $flattenParams() {
    const proxy = this.proxy
    let params = []
    for (const key in this.$params) {
      if (this.isNested(key)) {
        const childParams = proxy[key].$flattenParams()
        for (let j = 0; j < childParams.length; j++) {
          childParams[j].path.unshift(key)
        }
        params = params.concat(childParams)
      } else {
        params.push({ path: [], name: key, params: this.$params[key] })
      }
    }
    return params
  }
}

const getterNames = Object.keys(validationGetters)
const methodNames = Object.keys(validationMethods)

let _cachedComponent = null
const getComponent = (Vue) => {
  if (_cachedComponent) {
    return _cachedComponent
  }

  const VBase = Vue.extend({
    computed: {
      refs() {
        const oldVval = this._vval
        // eslint-disable-next-line vue/no-side-effects-in-computed-properties
        this._vval = this.children
        patchChildren(oldVval, this._vval)
        const refs = {}
        this._vval.forEach((c) => {
          refs[c.key] = c.vm
        })
        return refs
      }
    },
    beforeCreate() {
      this._vval = null
    },
    beforeDestroy() {
      if (this._vval) {
        patchChildren(this._vval)
        this._vval = null
      }
    },
    methods: {
      getModel() {
        return this.lazyModel ? this.lazyModel(this.prop) : this.model
      },
      getModelKey(key) {
        var model = this.getModel()
        if (model) {
          return model[key]
        }
      },
      hasIter() {
        return false
      }
    }
  })

  const ValidationRule = VBase.extend({
    data() {
      return {
        rule: null,
        lazyModel: null,
        model: null,
        lazyParentModel: null,
        rootModel: null
      }
    },
    methods: {
      runRule(parent) {
        // Avoid using this.lazyParentModel to not get dependent on it.
        // Passed as an argument for workaround
        const model = this.getModel()
        pushParams()
        const rawOutput = this.rule.call(this.rootModel, model, parent)
        const output = isPromise(rawOutput)
          ? makePendingAsyncVm(Vue, rawOutput)
          : rawOutput

        const rawParams = popParams()
        const params =
          rawParams && rawParams.$sub
            ? rawParams.$sub.length > 1
              ? rawParams
              : rawParams.$sub[0]
            : null

        return { output, params }
      }
    },
    computed: {
      run() {
        const parent = this.lazyParentModel()
        const isArrayDependant = Array.isArray(parent) && parent.__ob__

        if (isArrayDependant) {
          // force depend on the array
          const arrayDep = parent.__ob__.dep
          arrayDep.depend()

          const target = arrayDep.constructor.target

          if (!this._indirectWatcher) {
            const Watcher = target.constructor
            this._indirectWatcher = new Watcher(
              this,
              () => this.runRule(parent),
              null,
              { lazy: true }
            )
          }

          // if the update cause is only the array update
          // and value stays the same, don't recalculate
          const model = this.getModel()
          if (!this._indirectWatcher.dirty && this._lastModel === model) {
            this._indirectWatcher.depend()
            return target.value
          }

          this._lastModel = model
          this._indirectWatcher.evaluate()
          this._indirectWatcher.depend()
        } else if (this._indirectWatcher) {
          // array was replaced with different type at runtime
          this._indirectWatcher.teardown()
          this._indirectWatcher = null
        }
        return this._indirectWatcher
          ? this._indirectWatcher.value
          : this.runRule(parent)
      },
      $params() {
        return this.run.params
      },
      proxy() {
        const output = this.run.output
        if (output[__isVuelidateAsyncVm]) {
          return !!output.v
        }
        return !!output
      },
      $pending() {
        const output = this.run.output
        if (output[__isVuelidateAsyncVm]) {
          return output.p
        }
        return false
      }
    },
    destroyed() {
      if (this._indirectWatcher) {
        this._indirectWatcher.teardown()
        this._indirectWatcher = null
      }
    }
  })

  const Validation = VBase.extend({
    data() {
      return {
        dirty: false,
        validations: null,
        lazyModel: null,
        model: null,
        prop: null,
        lazyParentModel: null,
        rootModel: null
      }
    },
    methods: {
      ...validationMethods,
      refProxy(key) {
        return this.getRef(key).proxy
      },
      getRef(key) {
        return this.refs[key]
      },
      isNested(key) {
        return typeof this.validations[key] !== 'function'
      }
    },
    computed: {
      ...validationGetters,
      nestedKeys() {
        return this.keys.filter(this.isNested)
      },
      ruleKeys() {
        return this.keys.filter((k) => !this.isNested(k))
      },
      keys() {
        return Object.keys(this.validations).filter((k) => k !== '$params')
      },
      proxy() {
        const keyDefs = buildFromKeys(this.keys, (key) => ({
          enumerable: true,
          configurable: true, // allow mocking lib calls
          get: () => this.refProxy(key)
        }))

        const getterDefs = buildFromKeys(getterNames, (key) => ({
          enumerable: true,
          configurable: true,
          get: () => this[key]
        }))

        const methodDefs = buildFromKeys(methodNames, (key) => ({
          enumerable: false,
          configurable: true,
          get: () => this[key]
        }))

        const iterDefs = this.hasIter()
          ? {
              $iter: {
                enumerable: true,
                value: Object.defineProperties(
                  {},
                  {
                    ...keyDefs
                  }
                )
              }
            }
          : {}

        return Object.defineProperties(
          {},
          {
            ...keyDefs,
            ...iterDefs,
            $model: {
              enumerable: true,
              get: () => {
                const parent = this.lazyParentModel()
                if (parent != null) {
                  return parent[this.prop]
                } else {
                  return null
                }
              },
              set: (value) => {
                const parent = this.lazyParentModel()
                if (parent != null) {
                  parent[this.prop] = value
                  this.$touch()
                }
              }
            },
            ...getterDefs,
            ...methodDefs
          }
        )
      },
      children() {
        return [
          ...this.nestedKeys.map((key) => renderNested(this, key)),
          ...this.ruleKeys.map((key) => renderRule(this, key))
        ].filter(Boolean)
      }
    }
  })

  const GroupValidation = Validation.extend({
    methods: {
      isNested(key) {
        return typeof this.validations[key]() !== 'undefined'
      },
      getRef(key) {
        const vm = this
        return {
          get proxy() {
            // default to invalid
            return vm.validations[key]() || false
          }
        }
      }
    }
  })

  const EachValidation = Validation.extend({
    computed: {
      keys() {
        var model = this.getModel()
        if (isObject(model)) {
          return Object.keys(model)
        } else {
          return []
        }
      },
      tracker() {
        const trackBy = this.validations.$trackBy
        return trackBy
          ? (key) =>
              `${getPath(this.rootModel, this.getModelKey(key), trackBy)}`
          : (x) => `${x}`
      },
      getModelLazy() {
        return () => this.getModel()
      },
      children() {
        const def = this.validations
        const model = this.getModel()

        const validations = { ...def }
        delete validations['$trackBy']

        let usedTracks = {}

        return this.keys
          .map((key) => {
            const track = this.tracker(key)
            if (usedTracks.hasOwnProperty(track)) {
              return null
            }
            usedTracks[track] = true
            return h(Validation, track, {
              validations,
              prop: key,
              lazyParentModel: this.getModelLazy,
              model: model[key],
              rootModel: this.rootModel
            })
          })
          .filter(Boolean)
      }
    },
    methods: {
      isNested() {
        return true
      },
      getRef(key) {
        return this.refs[this.tracker(key)]
      },
      hasIter() {
        return true
      }
    }
  })

  const renderNested = (vm, key) => {
    if (key === '$each') {
      return h(EachValidation, key, {
        validations: vm.validations[key],
        lazyParentModel: vm.lazyParentModel,
        prop: key,
        lazyModel: vm.getModel,
        rootModel: vm.rootModel
      })
    }
    const validations = vm.validations[key]
    if (Array.isArray(validations)) {
      const root = vm.rootModel
      const refVals = buildFromKeys(
        validations,
        (path) =>
          function() {
            return getPath(root, root.$v, path)
          },
        (v) => (Array.isArray(v) ? v.join('.') : v)
      )
      return h(GroupValidation, key, {
        validations: refVals,
        lazyParentModel: NIL,
        prop: key,
        lazyModel: NIL,
        rootModel: root
      })
    }
    return h(Validation, key, {
      validations,
      lazyParentModel: vm.getModel,
      prop: key,
      lazyModel: vm.getModelKey,
      rootModel: vm.rootModel
    })
  }

  const renderRule = (vm, key) => {
    return h(ValidationRule, key, {
      rule: vm.validations[key],
      lazyParentModel: vm.lazyParentModel,
      lazyModel: vm.getModel,
      rootModel: vm.rootModel
    })
  }

  _cachedComponent = { VBase, Validation }
  return _cachedComponent
}

let _cachedVue = null
function getVue(rootVm) {
  if (_cachedVue) return _cachedVue
  let Vue = rootVm.constructor
  /* istanbul ignore next */
  while (Vue.super) Vue = Vue.super
  _cachedVue = Vue
  return Vue
}

const validateModel = (model, validations) => {
  const Vue = getVue(model)
  const { Validation, VBase } = getComponent(Vue)
  const root = new VBase({
    computed: {
      children() {
        const vals =
          typeof validations === 'function'
            ? validations.call(model)
            : validations

        return [
          h(Validation, '$v', {
            validations: vals,
            lazyParentModel: NIL,
            prop: '$v',
            model,
            rootModel: model
          })
        ]
      }
    }
  })
  return root
}

const validationMixin = {
  data() {
    const vals = this.$options.validations
    if (vals) {
      this._vuelidate = validateModel(this, vals)
    }
    return {}
  },
  beforeCreate() {
    const options = this.$options
    const vals = options.validations
    if (!vals) return
    if (!options.computed) options.computed = {}
    if (options.computed.$v) return
    options.computed.$v = function() {
      return this._vuelidate ? this._vuelidate.refs.$v.proxy : null
    }
  },
  beforeDestroy() {
    if (this._vuelidate) {
      this._vuelidate.$destroy()
      this._vuelidate = null
    }
  }
}

function Vuelidate(Vue) {
  Vue.mixin(validationMixin)
}

export { Vuelidate, validationMixin, withParams }
export default Vuelidate
