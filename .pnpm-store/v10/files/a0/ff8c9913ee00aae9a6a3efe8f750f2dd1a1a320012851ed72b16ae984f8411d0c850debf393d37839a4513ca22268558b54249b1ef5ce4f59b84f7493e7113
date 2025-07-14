import { v4 as uuid } from '@lukeed/uuid'
import jar from 'js-cookie'
import { Traits } from '../events'
import { tld } from './tld'
import autoBind from '../../lib/bind-all'

export type ID = string | null | undefined

export interface UserOptions {
  /**
   * Disables storing any data about the user.
   */
  disable?: boolean
  localStorageFallbackDisabled?: boolean
  persist?: boolean

  cookie?: {
    key?: string
    oldKey?: string
  }

  localStorage?: {
    key: string
  }
}

const defaults = {
  persist: true,
  cookie: {
    key: 'ajs_user_id',
    oldKey: 'ajs_user',
  },
  localStorage: {
    key: 'ajs_user_traits',
  },
}

export type StoreType = 'cookie' | 'localStorage' | 'memory'

type StorageObject = Record<string, unknown>

class Store {
  private cache: Record<string, unknown> = {}

  get<T>(key: string): T | null {
    return this.cache[key] as T | null
  }

  set<T>(key: string, value: T | null): void {
    this.cache[key] = value
  }

  remove(key: string): void {
    delete this.cache[key]
  }
  get type(): StoreType {
    return 'memory'
  }
}

const ONE_YEAR = 365

export class Cookie extends Store {
  static available(): boolean {
    let cookieEnabled = window.navigator.cookieEnabled

    if (!cookieEnabled) {
      jar.set('ajs:cookies', 'test')
      cookieEnabled = document.cookie.includes('ajs:cookies')
      jar.remove('ajs:cookies')
    }

    return cookieEnabled
  }

  static get defaults(): CookieOptions {
    return {
      maxage: ONE_YEAR,
      domain: tld(window.location.href),
      path: '/',
      sameSite: 'Lax',
    }
  }

  private options: Required<CookieOptions>

  constructor(options: CookieOptions = Cookie.defaults) {
    super()
    this.options = {
      ...Cookie.defaults,
      ...options,
    } as Required<CookieOptions>
  }

  private opts(): jar.CookieAttributes {
    return {
      sameSite: this.options.sameSite as jar.CookieAttributes['sameSite'],
      expires: this.options.maxage,
      domain: this.options.domain,
      path: this.options.path,
      secure: this.options.secure,
    }
  }

  get<T>(key: string): T | null {
    try {
      const value = jar.get(key)

      if (!value) {
        return null
      }

      try {
        return JSON.parse(value)
      } catch (e) {
        return value as unknown as T
      }
    } catch (e) {
      return null
    }
  }

  set<T>(key: string, value: T): void {
    if (typeof value === 'string') {
      jar.set(key, value, this.opts())
    } else if (value === null) {
      jar.remove(key, this.opts())
    } else {
      jar.set(key, JSON.stringify(value), this.opts())
    }
  }

  remove(key: string): void {
    return jar.remove(key, this.opts())
  }

  get type(): StoreType {
    return 'cookie'
  }
}

const localStorageWarning = (key: string, state: 'full' | 'unavailable') => {
  console.warn(`Unable to access ${key}, localStorage may be ${state}`)
}

export class LocalStorage extends Store {
  static available(): boolean {
    const test = 'test'
    try {
      localStorage.setItem(test, test)
      localStorage.removeItem(test)
      return true
    } catch (e) {
      return false
    }
  }

  get<T>(key: string): T | null {
    try {
      const val = localStorage.getItem(key)
      if (val === null) {
        return null
      }
      try {
        return JSON.parse(val)
      } catch (e) {
        return val as any as T
      }
    } catch (err) {
      localStorageWarning(key, 'unavailable')
      return null
    }
  }

  set<T>(key: string, value: T): void {
    try {
      localStorage.setItem(key, JSON.stringify(value))
    } catch {
      localStorageWarning(key, 'full')
    }
  }

  remove(key: string): void {
    try {
      return localStorage.removeItem(key)
    } catch (err) {
      localStorageWarning(key, 'unavailable')
    }
  }

  get type(): StoreType {
    return 'localStorage'
  }
}

export interface CookieOptions {
  maxage?: number
  domain?: string
  path?: string
  secure?: boolean
  sameSite?: string
}

export class UniversalStorage<Data extends StorageObject = StorageObject> {
  private enabledStores: StoreType[]
  private storageOptions: StorageOptions

  constructor(stores: StoreType[], storageOptions: StorageOptions) {
    this.storageOptions = storageOptions
    this.enabledStores = stores
  }

  private getStores(storeTypes: StoreType[] | undefined): Store[] {
    const stores: Store[] = []
    this.enabledStores
      .filter((i) => !storeTypes || storeTypes?.includes(i))
      .forEach((storeType) => {
        const storage = this.storageOptions[storeType]
        if (storage !== undefined) {
          stores.push(storage)
        }
      })

    return stores
  }

  /*
    This is to support few scenarios where:
    - value exist in one of the stores ( as a result of other stores being cleared from browser ) and we want to resync them
    - read values in AJS 1.0 format ( for customers after 1.0 --> 2.0 migration ) and then re-write them in AJS 2.0 format
  */

  /**
   * get value for the key from the stores. it will pick the first value found in the stores, and then sync the value to all the stores
   * if the found value is a number, it will be converted to a string. this is to support legacy behavior that existed in AJS 1.0
   * @param key key for the value to be retrieved
   * @param storeTypes optional array of store types to be used for performing get and sync
   * @returns value for the key or null if not found
   */
  public getAndSync<K extends keyof Data>(
    key: K,
    storeTypes?: StoreType[]
  ): Data[K] | null {
    const val = this.get(key, storeTypes)

    // legacy behavior, getAndSync can change the type of a value from number to string (AJS 1.0 stores numerical values as a number)
    const coercedValue = (typeof val === 'number' ? val.toString() : val) as
      | Data[K]
      | null

    this.set(key, coercedValue, storeTypes)

    return coercedValue
  }

  /**
   * get value for the key from the stores. it will return the first value found in the stores
   * @param key key for the value to be retrieved
   * @param storeTypes optional array of store types to be used for retrieving the value
   * @returns value for the key or null if not found
   */
  public get<K extends keyof Data>(
    key: K,
    storeTypes?: StoreType[]
  ): Data[K] | null {
    let val = null

    for (const store of this.getStores(storeTypes)) {
      val = store.get<Data[K]>(key)
      if (val) {
        return val
      }
    }
    return null
  }

  /**
   * it will set the value for the key in all the stores
   * @param key key for the value to be stored
   * @param value value to be stored
   * @param storeTypes optional array of store types to be used for storing the value
   * @returns value that was stored
   */
  public set<K extends keyof Data>(
    key: K,
    value: Data[K] | null,
    storeTypes?: StoreType[]
  ): void {
    for (const store of this.getStores(storeTypes)) {
      store.set(key, value)
    }
  }

  /**
   * remove the value for the key from all the stores
   * @param key key for the value to be removed
   * @param storeTypes optional array of store types to be used for removing the value
   */
  public clear<K extends keyof Data>(key: K, storeTypes?: StoreType[]): void {
    for (const store of this.getStores(storeTypes)) {
      store.remove(key)
    }
  }
}

type StorageOptions = {
  cookie: Cookie | undefined
  localStorage: LocalStorage | undefined
  memory: Store
}

export function getAvailableStorageOptions(
  cookieOptions?: CookieOptions
): StorageOptions {
  return {
    cookie: Cookie.available() ? new Cookie(cookieOptions) : undefined,
    localStorage: LocalStorage.available() ? new LocalStorage() : undefined,
    memory: new Store(),
  }
}

export class User {
  static defaults = defaults

  private idKey: string
  private traitsKey: string
  private anonKey: string
  private cookieOptions?: CookieOptions

  private legacyUserStore: UniversalStorage<{
    [k: string]:
      | {
          id?: string
          traits?: Traits
        }
      | string
  }>
  private traitsStore: UniversalStorage<{
    [k: string]: Traits
  }>

  private identityStore: UniversalStorage<{
    [k: string]: string
  }>

  options: UserOptions = {}

  constructor(options: UserOptions = defaults, cookieOptions?: CookieOptions) {
    this.options = options
    this.cookieOptions = cookieOptions

    this.idKey = options.cookie?.key ?? defaults.cookie.key
    this.traitsKey = options.localStorage?.key ?? defaults.localStorage.key
    this.anonKey = 'ajs_anonymous_id'

    const isDisabled = options.disable === true
    const shouldPersist = options.persist !== false

    let defaultStorageTargets: StoreType[] = isDisabled
      ? []
      : shouldPersist
      ? ['localStorage', 'cookie', 'memory']
      : ['memory']

    const storageOptions = getAvailableStorageOptions(cookieOptions)

    if (options.localStorageFallbackDisabled) {
      defaultStorageTargets = defaultStorageTargets.filter(
        (t) => t !== 'localStorage'
      )
    }

    this.identityStore = new UniversalStorage(
      defaultStorageTargets,
      storageOptions
    )

    // using only cookies for legacy user store
    this.legacyUserStore = new UniversalStorage(
      defaultStorageTargets.filter(
        (t) => t !== 'localStorage' && t !== 'memory'
      ),
      storageOptions
    )

    // using only localStorage / memory for traits store
    this.traitsStore = new UniversalStorage(
      defaultStorageTargets.filter((t) => t !== 'cookie'),
      storageOptions
    )

    const legacyUser = this.legacyUserStore.get(defaults.cookie.oldKey)
    if (legacyUser && typeof legacyUser === 'object') {
      legacyUser.id && this.id(legacyUser.id)
      legacyUser.traits && this.traits(legacyUser.traits)
    }
    autoBind(this)
  }

  id = (id?: ID): ID => {
    if (this.options.disable) {
      return null
    }

    const prevId = this.identityStore.getAndSync(this.idKey)

    if (id !== undefined) {
      this.identityStore.set(this.idKey, id)

      const changingIdentity = id !== prevId && prevId !== null && id !== null
      if (changingIdentity) {
        this.anonymousId(null)
      }
    }

    const retId = this.identityStore.getAndSync(this.idKey)
    if (retId) return retId

    const retLeg = this.legacyUserStore.get(defaults.cookie.oldKey)
    return retLeg ? (typeof retLeg === 'object' ? retLeg.id : retLeg) : null
  }

  private legacySIO(): [string, string] | null {
    const val = this.legacyUserStore.get('_sio') as string
    if (!val) {
      return null
    }
    const [anon, user] = val.split('----')
    return [anon, user]
  }

  anonymousId = (id?: ID): ID => {
    if (this.options.disable) {
      return null
    }

    if (id === undefined) {
      const val =
        this.identityStore.getAndSync(this.anonKey) ?? this.legacySIO()?.[0]

      if (val) {
        return val
      }
    }

    if (id === null) {
      this.identityStore.set(this.anonKey, null)
      return this.identityStore.getAndSync(this.anonKey)
    }

    this.identityStore.set(this.anonKey, id ?? uuid())
    return this.identityStore.getAndSync(this.anonKey)
  }

  traits = (traits?: Traits | null): Traits | undefined => {
    if (this.options.disable) {
      return
    }

    if (traits === null) {
      traits = {}
    }

    if (traits) {
      this.traitsStore.set(this.traitsKey, traits ?? {})
    }

    return this.traitsStore.get(this.traitsKey) ?? {}
  }

  identify(id?: ID, traits?: Traits): void {
    if (this.options.disable) {
      return
    }

    traits = traits ?? {}
    const currentId = this.id()

    if (currentId === null || currentId === id) {
      traits = {
        ...this.traits(),
        ...traits,
      }
    }

    if (id) {
      this.id(id)
    }

    this.traits(traits)
  }

  logout(): void {
    this.anonymousId(null)
    this.id(null)
    this.traits({})
  }

  reset(): void {
    this.logout()
    this.identityStore.clear(this.idKey)
    this.identityStore.clear(this.anonKey)
    this.traitsStore.clear(this.traitsKey)
  }

  load(): User {
    return new User(this.options, this.cookieOptions)
  }

  save(): boolean {
    return true
  }
}

const groupDefaults: UserOptions = {
  persist: true,
  cookie: {
    key: 'ajs_group_id',
  },
  localStorage: {
    key: 'ajs_group_properties',
  },
}

export class Group extends User {
  constructor(options: UserOptions = groupDefaults, cookie?: CookieOptions) {
    super(options, cookie)
    autoBind(this)
  }

  anonymousId = (_id?: ID): ID => {
    return undefined
  }
}
