import { CoreContext } from '../context'
import { ID } from '../user'
import { DeepNullable } from '../utils/ts-helpers'

export type Callback<Ctx extends CoreContext = CoreContext> = (
  ctx: Ctx
) => Promise<unknown> | unknown

export type SegmentEventType =
  | 'track'
  | 'page'
  | 'identify'
  | 'group'
  | 'alias'
  | 'screen'

export type JSONPrimitive = string | number | boolean | null
export type JSONValue = JSONPrimitive | JSONObject | JSONArray
export type JSONObject = { [member: string]: JSONValue }
export type JSONArray = JSONValue[]

export type EventProperties = Record<string, any>

export type Integrations = {
  All?: boolean
  [integration: string]: boolean | JSONObject | undefined
}

export interface CoreOptions {
  integrations?: Integrations
  timestamp?: Timestamp
  context?: CoreExtraContext
  anonymousId?: string
  userId?: string
  traits?: Traits
  // ugh, this is ugly, but we allow literally any property to be passed to options (which get spread onto the event)
  [key: string]: any
}

/**
 * Context is a dictionary of extra information that provides useful context about a datapoint, for example the user’s ip address or locale. You should only use Context fields for their intended meaning.
 * @link https://segment.com/docs/connections/spec/common/#context
 */
export interface CoreExtraContext {
  /**
   * This is usually used to flag an .identify() call to just update the trait, rather than "last seen".
   */
  active?: boolean

  /**
   * Current user's IP address.
   */
  ip?: string

  /**
   * Locale string for the current user, for example en-US.
   * @example en-US
   */
  locale?: string
  /**
   * Dictionary of information about the user’s current location.
   */
  location?: {
    /**
     * @example San Francisco
     */
    city?: string
    /**
     * @example United States
     */
    country?: string
    /**
     * @example 40.2964197
     */
    latitude?: string
    /**
     * @example -76.9411617
     */
    longitude?: string
    /**
     * @example CA
     */
    region?: string
    /**
     * @example 100
     */
    speed?: number
  }

  /**
   * Dictionary of information about the current web page.
   */
  page?: {
    /**
     * @example /academy/
     */
    path?: string
    /**
     * @example https://www.foo.com/
     */
    referrer?: string
    /**
     * @example projectId=123
     */
    search?: string
    /**
     * @example Analytics Academy
     */
    title?: string
    /**
     * @example https://segment.com/academy/
     */
    url?: string
  }

  /**
   * User agent of the device making the request.
   */
  userAgent?: string

  /**
   * Information about the current library.
   *
   * **Automatically filled out by the library.**
   *
   * This type should probably be "never"
   */
  library?: {
    /**
     * @example analytics-node-next/latest
     */
    name: string
    /**
     * @example  "1.43.1"
     */
    version: string
  }

  /**
   * This is useful in cases where you need to track an event,
   * but also associate information from a previous identify call.
   * You should fill this object the same way you would fill traits in an identify call.
   */
  traits?: Traits

  /**
   * Dictionary of information about the campaign that resulted in the API call, containing name, source, medium, term, content, and any other custom UTM parameter.
   */
  campaign?: {
    name: string
    term: string
    source: string
    medium: string
    content: string
  }

  /**
   * Dictionary of information about the way the user was referred to the website or app.
   */
  referrer?: {
    type?: string
    name?: string
    url?: string
    link?: string

    id?: string // undocumented
    btid?: string // undocumented?
    urid?: string // undocumented?
  }

  amp?: {
    // undocumented?
    id: string
  }

  [key: string]: any
}

export interface CoreSegmentEvent {
  messageId?: string
  type: SegmentEventType

  // page specific
  category?: string
  name?: string

  properties?: EventProperties

  traits?: Traits // Traits is only defined in 'identify' and 'group', even if it can be passed in other calls.

  integrations?: Integrations
  context?: CoreExtraContext
  options?: CoreOptions

  userId?: ID
  anonymousId?: ID
  groupId?: ID
  previousId?: ID

  event?: string

  writeKey?: string

  sentAt?: Date

  _metadata?: SegmentEventMetadata

  timestamp?: Timestamp
}

export interface SegmentEventMetadata {
  failedInitializations?: unknown[]
  bundled?: string[]
  unbundled?: string[]
  nodeVersion?: string
  bundledConfigIds?: string[]
  unbundledConfigIds?: string[]
  bundledIds?: string[]
}

export type Timestamp = Date | string

/**
 * A Plan allows users to specify events and which destinations they would like them to be sent to
 */
export interface Plan {
  track?: TrackPlan
  identify?: TrackPlan
  group?: TrackPlan
}

export interface TrackPlan {
  [key: string]: PlanEvent | undefined
  // __default SHOULD always exist, but marking as optional for extra safety.
  __default?: PlanEvent
}

export interface PlanEvent {
  /**
   * Whether or not this plan event is enabled
   */
  enabled: boolean
  /**
   * Which integrations the plan event applies to
   */
  integrations?: {
    [key: string]: boolean
  }
}

type DbId = string | number // TODO: the docs says that this can only be a string?
type PhoneNumber = string | number // TODO: the docs say this can only be a string?

/**
 * Traits are pieces of information you know about a group.
 * This interface represents reserved traits that Segment has standardized.
 * @link https://segment.com/docs/connections/spec/group/#traits
 */
type BaseGroupTraits = DeepNullable<{
  /**
   * Street address of a group.
   */
  address?: BaseUserTraits['address']

  /**
   * URL to an avatar image for the group.
   */
  avatar?: BaseUserTraits['avatar']

  /**
   * Date the group's account was first created. Segment recommends ISO-8601 date strings.
   */
  createdAt?: BaseUserTraits['createdAt']

  /**
   * Description of a group
   */
  description?: BaseUserTraits['description']
  /**
   * Email address of group.
   */
  email?: BaseUserTraits['email']
  /**
   * Number of employees of a group, typically used for companies.
   */
  employees?: string | number // TODO: the docs says that this must be a string?

  /**
   * Unique ID in your database for a group.
   */
  id?: BaseUserTraits['id']

  /**
   * Industry a group is part of.
   */
  industry?: BaseUserTraits['industry']

  /**
   * Name of a group.
   */
  name?: BaseUserTraits['name']

  /**
   * Phone number of a group
   */
  phone?: BaseUserTraits['phone']

  /**
   * Website of a group.
   */
  website?: BaseUserTraits['website']

  /**
   * 	Plan that a group is in.
   */
  plan?: BaseUserTraits['plan']
}>

/**
 * Traits are pieces of information you know about a user.
 * This interface represents reserved traits that Segment has standardized.
 * @link https://segment.com/docs/connections/spec/identify/#traits
 */
type BaseUserTraits = DeepNullable<{
  /**
   * Unique ID in your database for a user
   */
  id?: DbId

  /**
   * Industry a user works in
   */
  industry?: string

  /**
   * First name of a user.
   */
  firstName?: string

  /**
   * Last name of a user.
   */
  lastName?: string

  /**
   * Full name of a user. If you only pass a first and last name Segment automatically fills in the full name for you.
   */
  name?: string

  /**
   * Phone number of a user
   */
  phone?: PhoneNumber

  /**
   * Title of a user, usually related to their position at a specific company.
   * @example VP of Engineering
   */
  title?: string

  /**
   * User's username. This should be unique to each user, like the usernames of Twitter or GitHub.
   */
  username?: string

  /**
   * Website of a user.
   */
  website?: string

  /**
   * Street address of a user.
   */
  address?: {
    city?: string
    country?: string
    postalCode?: string
    state?: string
    street?: string
  }
  /**
   * Age of a user.
   */
  age?: number

  /**
   * URL to an avatar image for the user.
   */
  avatar?: string

  /**
   * User's birthday.
   */
  birthday?: Timestamp

  /**
   * User's company.
   */
  company?: {
    name?: string
    id?: DbId
    industry?: BaseUserTraits['industry']
    employee_count?: number
    plan?: BaseUserTraits['plan']
  }

  /**
    Plan that a user is in.

   * @example enterprise
   */
  plan?: string

  /**
   * 	Date the user's account was first created. Segment recommends using ISO-8601 date strings.
   */
  createdAt?: Timestamp

  /**
   * Description of user, such as bio.
   */
  description?: string

  /**
   * Email address of a user.
   */
  email?: string

  /**
   * @example female
   */
  gender?: string
}>

/**
 * Traits are pieces of information you know about a group.
 * This interface represents reserved traits that Segment has standardized.
 * @link https://segment.com/docs/connections/spec/group/#traits
 */
export type GroupTraits = BaseGroupTraits & {
  [customTrait: string]: any
}

/**
 * Traits are pieces of information you know about a user.
 * This interface represents reserved traits that Segment has standardized.
 * @link https://segment.com/docs/connections/spec/identify/#traits
 */
export type UserTraits = BaseUserTraits & {
  [customTrait: string]: any
}

/**
 * Traits are pieces of information you know about a user or group.
 */
export type Traits = UserTraits | GroupTraits
