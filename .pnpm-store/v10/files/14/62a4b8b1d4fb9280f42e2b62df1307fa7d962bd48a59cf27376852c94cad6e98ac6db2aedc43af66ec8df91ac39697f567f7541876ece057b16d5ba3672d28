declare module '@segment/facade' {
  interface Options {
    clone?: boolean;
    traverse?: boolean;
  }
  export class Facade<T = { [key: string]: any }> {
    constructor(object: { [key: string]: any }, options?: Options);
    Track: Track;
    Identify: Identify;
    Page: Page;
    Group: Group;
    /**
     * Get a potentially-nested field in this facade. `field` should be a
     * period-separated sequence of properties.
     *
     * If the first field passed in points to a function (e.g. the `field` passed
     * in is `a.b.c` and this facade's `obj.a` is a function), then that function
     * will be called, and then the deeper fields will be fetched (using obj-case)
     * from what that function returns. If the first field isn't a function, then
     * this function works just like obj-case.
     *
     * Because this function uses obj-case, the camel- or snake-case of the input
     * is irrelevant.
     *
     */
    proxy(path: string): unknown;

    /**
     * Gets the underlying object this facade wraps around.
     *
     * If this facade has a property `type`, it will be invoked as a function and
     * will be assigned as the property `type` of the outputted object.
     *
     */
    json(): { [key: string]: any };

    /**
     * Gets the raw, unmodified object this facade wraps around.
     * 
     * Unlike the `json` method, which does make some subtle modifications 
     * to datetime values and the `type` property, this method returns the input
     * object as-is. It is not guaranteed to be the same instance, due to constraints of 
     * how the `clone: false` option behaves.
     */
    rawEvent(): { [key: string]: any }

    /**
     * Get the options of a call. If an integration is passed, only the options for
     * that integration are included. If the integration is not enabled, then
     * `undefined` is returned.
     *
     * Options are taken from the `options` property of the underlying object,
     * falling back to the object's `context` or simply `{}`.
     *
     * @param integration - The name of the integration to get settings
     * for. Casing does not matter.
     */
    options(): { [key: string]: any };
    options(integration?: string): T;
    /**
     * Check whether an integration is enabled.
     *
     * Basically, this method checks whether this integration is explicitly
     * enabled. If it isn'texplicitly mentioned, it checks whether it has been
     * enabled at the global level. Some integrations (e.g. Salesforce), cannot
     * enabled by these global event settings.
     *
     * More concretely, the deciding factors here are:
     *
     * 1. If `this.integrations()` has the integration set to `true`, return `true`.
     * 2. If `this.integrations().providers` has the integration set to `true`, return `true`.
     * 3. If integrations are set to default-disabled via global parameters (i.e.
     * `options.providers.all`, `options.all`, or `integrations.all`), then return
     * false.
     * 4. If the integration is one of the special default-deny integrations
     * (currently, only Salesforce), then return false.
     * 5. Else, return true.
     */
    enabled(integration: string): boolean;
    /**
     * Get all `integration` options.
     */
    integrations(): { [key: string]: any };
    /**
     * Check whether the user is active.
     */
    active(): boolean;
    /**
     * Get `sessionId / anonymousId`.
     */
    anonymousId(): unknown;
    /**
     * Get `sessionId / anonymousId`.
     */
    sessionId(): unknown;
    /**
     * Get `groupId` from `context.groupId`.
     */
    groupId(): unknown;
    /**
     * Get the call's "traits". All event types can pass in traits, though {@link
     * Identify} and {@link Group} override this implementation.
     *
     * Traits are gotten from `options.traits`, augmented with a property `id` with
     * the event's `userId`.
     *
     * The parameter `aliases` is meant to transform keys in `options.traits` into
     * new keys. Each alias like `{ "xxx": "yyy" }` will take whatever is at `xxx`
     * in the traits, and move it to `yyy`. If `xxx` is a method of this facade,
     * it'll be called as a function instead of treated as a key into the traits.
     */
    traits(aliases?: object): { [key: string]: any };
    /**
     * The library and version of the client used to produce the message.
     *
     * If the library name cannot be determined, it is set to `"unknown"`. If the
     * version cannot be determined, it is set to `null`.
     */
    library(): { name: string; version: null } | unknown;
    /**
     * Return the device information, falling back to an empty object.
     *
     * Interesting values of `type` are `"ios"` and `"android"`, but other values
     * are possible if the client is doing something unusual with `context.device`.
     */
    device(): unknown;
    /** Get the User-Agent from `context.userAgent`. */
    userAgent(): unknown;
    /** Get the timezone from `context.timezone`. */
    timezone(): unknown;
    /** Get the timestamp from `context.timestamp`. */
    timestamp(): unknown;
    /** Get the channel from `channel`. */
    channel(): unknown;
    /** Get the IP address from `context.ip`. */
    ip(): unknown;
    /** Get the user ID from `userId`. */
    userId(): unknown;
    /**
     * Get the ZIP/Postal code from `traits`, `traits.address`, `properties`, or
     * `properties.address`.
     */
    zip(): unknown;
    /**
     * Get the country from `traits`, `traits.address`, `properties`, or
     * `properties.address`.
     */
    country(): unknown;
    /**
     * Get the street from `traits`, `traits.address`, `properties`, or
     * `properties.address`.
     */
    street(): unknown;
    /**
     * Get the state from `traits`, `traits.address`, `properties`, or
     * `properties.address`.
     */
    state(): unknown;
    /**
     * Get the city from `traits`, `traits.address`, `properties`, or
     * `properties.address`.
     */
    city(): unknown;
    /**
     * Get the region from `traits`, `traits.address`, `properties`, or
     * `properties.address`.
     */
    region(): unknown;
    type(): "page" | "identify" | "group" | "track" | "screen" | "alias";
    action(): "page" | "identify" | "group" | "track" | "screen" | "alias";
    active(): unknown;
  }

  export class Track<T = { [key: string]: any }> extends Facade<T> {
    /** Get the event name from `event`. */
    event(): string;
    /** Get the event value, usually the monetary value, from `properties.value`. */
    value(): unknown;
    /** Get the event cateogry from `properties.category`. */
    category(): unknown;
    /** Get the event ID from `properties.id`. */
    id(): string;
    /** Get the product ID from `properties.productId` || `properties.product_id` */
    productId(): unknown;
    /** Get the promotion ID from `properties.promotionId` || properties.promotion_id */
    promotionId(): unknown;
    /** Get the cart ID from `properties.cartId`. */
    cartId(): unknown;
    /** Get the checkout ID from `properties.checkoutId` || `properties.checkout_id` */
    checkoutId(): unknown;
    /** Get the payment ID from `properties.paymentId` || `properties.payment_id` */
    paymentId(): unknown;
    /** Get the coupon ID from `properties.couponId` || `properties.coupon_id` */
    couponId(): unknown;
    /** Get the wishlist ID from `properties.wishlistId` || `properties.wishlist_id` */
    wishlistId(): unknown;
    /** Get the review ID from `properties.reviewId` || `properties.review_id` */
    reviewId(): unknown;
    /** Get the order ID from `properties.id` or `properties.orderId` || `properties.order_id` */
    orderId(): unknown;
    /** Get the SKU from `properties.sku`. */
    sku(): unknown;
    /** Get the amount of tax for this purchase from `properties.tax`. */
    tax(): unknown;
    /** Get the name of this event from `properties.name`. */
    name(): unknown;
    /** Get the price of this purchase from `properties.price`. */
    price(): unknown;
    /** Get the total for this purchase from `properties.total`. */
    total(): unknown;
    /** Whether this is a repeat purchase from `properties.repeat`. */
    repeat(): unknown;
    /** Get the coupon for this purchase from `properties.coupon`. */
    coupon(): unknown;
    /** Get the shipping for this purchase from `properties.shipping`. */
    shipping(): unknown;
    /** Get the discount for this purchase from `properties.discount`. */
    discount(): unknown;
    /** Get the shipping method for this purchase from `properties.shippingMethod`. */
    shippingMethod(): unknown;
    /** Get the payment method for this purchase from `properties.paymentMethod` || `properties.payment_method` */
    paymentMethod(): unknown;
    /** Get a description for this event from `properties.description` */
    description(): unknown;
    /** Get a plan, as in the plan the user is on, for this event from */
    plan(): unknown;
    /**
     * Get the subtotal for this purchase from `properties.subtotal`.
     *
     * If `properties.subtotal` isn't available, then fall back to computing the
     * total from `properties.total` or `properties.revenue`, and then subtracting
     * tax, shipping, and discounts.
     *
     * If neither subtotal, total, nor revenue are available, then return 0.
     */
    subtotal(): unknown;
    /** Get the products for this event from `properties.products` if it's an array, falling back to an empty array. */
    products(): unknown[];
    /** Get the quantity for this event from `properties.quantity`, falling back to a quantity of one. */
    quantity(): unknown;
    /** Get the currency for this event from `properties.currency`, falling back to "USD". */
    currency(): unknown;
    /** Get the referrer for this event from `context.referrer.url`, `context.page.referrer`, or `properties.referrer`. */
    referrer(): unknown;
    /** Get the query for this event from `options.query`. */
    query(): unknown;
    /**
     * Get the page's properties. This is identical to how {@link Facade#traits}
     * works, except it looks at `properties.*` instead of `options.traits.*`.
     *
     * Properties are gotten from `properties`.
     *
     * The parameter `aliases` is meant to transform keys in `properties` into new
     * keys. Each alias like `{ "xxx": "yyy" }` will take whatever is at `xxx` in
     * the traits, and move it to `yyy`. If `xxx` is a method of this facade, it'll
     * be called as a function instead of treated as a key into the traits.
     *
     * @example
     * var obj = { properties: { foo: "bar" }, anonymousId: "xxx" }
     * var track = new Track(obj)
     *
     * track.traits() // { "foo": "bar" }
     * track.traits({ "foo": "asdf" }) // { "asdf": "bar" }
     * track.traits({ "sessionId": "rofl" }) // { "rofl": "xxx" }
     */
    properties(aliases?: object): { [key: string]: any };
    /**
     * Get the username of the user for this event from `traits.username`,
     * `properties.username`, `userId`, or `anonymousId`.
     */
    username(): unknown;
    /**
     * Get the email of the user for this event from `trais.email`,
     * `properties.email`, or `options.traits.email`, falling back to `userId` if
     * it looks like a valid email.
     *
     */
    email(): unknown;
    /**
     * Get the revenue for this event.
     *
     * If this is an "Order Completed" event, this will be the `properties.total`
     * falling back to the `properties.revenue`. For all other events, this is
     * simply taken from `properties.revenue`.
     *
     * If there are dollar signs in these properties, they will be removed. The
     * result will be parsed into a number.
     */
    revenue(): unknown;
    /**
     * Get the revenue for this event in "cents" -- in other words, multiply the
     * {@link Track#revenue} by 100, or return 0 if there isn't a numerical revenue
     * for this event.
     *
     */
    cents(): unknown;
    /**
     * Convert this event into an {@link Identify} facade.
     *
     * This works by taking this event's underlying object and creating an Identify
     * from it. This event's traits, taken from `options.traits`, will be used as
     * the Identify's traits.
     *
     */
    identify(): Identify;
  }

  export class Identify<T = { [key: string]: any }> extends Facade<T> {
    /**
     * Get the user's traits. This is identical to how {@link Facade#traits} works,
     * except it looks at `traits.*` instead of `options.traits.*`.
     *
     * Traits are gotten from `traits`, augmented with a property `id` with
     * the event's `userId`.
     *
     * The parameter `aliases` is meant to transform keys in `traits` into new
     * keys. Each alias like `{ "xxx": "yyy" }` will take whatever is at `xxx` in
     * the traits, and move it to `yyy`. If `xxx` is a method of this facade, it'll
     * be called as a function instead of treated as a key into the traits.
     *
     * @example
     * var obj = { traits: { foo: "bar" }, anonymousId: "xxx" }
     * var identify = new Identify(obj)
     *
     * identify.traits() // { "foo": "bar" }
     * identify.traits({ "foo": "asdf" }) // { "asdf": "bar" }
     * identify.traits({ "sessionId": "rofl" }) // { "rofl": "xxx" }
     *
     */
    traits(aliases?: object): { [key: string]: any };
    /**
     * Get the user's email from `traits.email`, falling back to `userId` only if
     * it looks like a valid email.
     *
     */
    email(): unknown;
    /**
     * Get the time of creation of the user from `traits.created` or
     * `traits.createdAt`.
     */
    created(): Date | string | number | object;
    /**
     * Get the time of creation of the user's company from `traits.company.created`
     * or `traits.company.createdAt`.
     *
     */
    companyCreated(): Date | string | number | object;
    /** Get the user's company name from `traits.company.name`. */
    companyName(): unknown;
    /**
     * Get the user's name `traits.name`, falling back to combining {@link
     * Identify#firstName} and {@link Identify#lastName} if possible.
     */
    name(): unknown;
    /**
     * Get the user's first name from `traits.firstName`, optionally splitting it
     * out of a the full name if that's all that was provided.
     *
     * Splitting the full name works on the assumption that the full name is of the
     * form "FirstName LastName"; it will not work for non-Western names.
     *
     */
    firstName(): unknown;
    /**
     * Get the user's last name from `traits.lastName`, optionally splitting it out
     * of a the full name if that's all that was provided.
     */
    lastName(): unknown;
  }

  export class Group<T = { [key: string]: any }> extends Facade<T> {
    /**
     * Get the group ID from `groupId`.
     *
     * This *should* be a string, but may not be if the client isn't adhering to
     * the spec.
     */
    groupId(): unknown;
    /**
     * Get the time of creation of the group from `traits.createdAt`,
     * `traits.created`, `properties.createdAt`, or `properties.created`.
     */
    created(): Date | string | number | object;
    /**
     * Get the group's traits. This is identical to how {@link Facade#traits}
     * works, except it looks at `traits.*` instead of `options.traits.*`.
     *
     * Traits are gotten from `traits`, augmented with a property `id` with
     * the event's `groupId`.
     *
     * The parameter `aliases` is meant to transform keys in `traits` into new
     * keys. Each alias like `{ "xxx": "yyy" }` will take whatever is at `xxx` in
     * the traits, and move it to `yyy`. If `xxx` is a method of this facade, it'll
     * be called as a function instead of treated as a key into the traits.
     */
    traits(aliases?: object): { [key: string]: any };
    /**
     * Get the group's email from `traits.email`, falling back to `groupId` only if
     * it looks like a valid email.
     */
    email(): unknown;
    /**
     * Get the group's name from `traits.name`.
     *
     * This *should* be a string, but may not be if the client isn't adhering to
     * the spec.
     */
    name(): unknown;
    /**
     * Get the group's industry from `traits.industry`.
     *
     * This *should* be a string, but may not be if the client isn't adhering to
     * the spec.
     */
    industry(): unknown;
    /**
     * Get the group's employee count from `traits.employees`.
     *
     * This *should* be a number, but may not be if the client isn't adhering to
     * the spec.
     */
    employees(): unknown;
    /**
     * Get the group's properties from `traits` or `properties`, falling back to
     * simply an empty object.
     */
    properties(): unknown;
  }

  export class Page<T = { [key: string]: any }> extends Facade<T> {
    /**
     * Get the page category from `category`.
     *
     * This *should* be a string, but may not be if the client isn't adhering to
     * the spec.
     */
    category(): unknown;
    /**
     * Get the page name from `name`.
     *
     * This *should* be a string, but may not be if the client isn't adhering to
     * the spec.
     */
    name(): unknown;
    /**
     * Get the page title from `properties.title`.
     *
     * This *should* be a string, but may not be if the client isn't adhering to
     * the spec.
     */
    title(): unknown;
    /**
     * Get the page path from `properties.path`.
     *
     * This *should* be a string, but may not be if the client isn't adhering to
     * the spec.
     */
    path(): unknown;
    /**
     * Get the page URL from `properties.url`.
     *
     * This *should* be a string, but may not be if the client isn't adhering to
     * the spec.
     */
    url(): unknown;
    /**
     * Get the HTTP referrer from `context.referrer.url`, `context.page.referrer`,
     * or `properties.referrer`.
     *
     * This *should* be a string, but may not be if the client isn't adhering to
     * the spec.
     *
     * @return {string}
     */
    referrer(): unknown;
    /**
     * Get the page's properties. This is identical to how {@link Facade#traits}
     * works, except it looks at `properties.*` instead of `options.traits.*`.
     *
     * Properties are gotten from `properties`, augmented with the page's `name`
     * and `category`.
     *
     * The parameter `aliases` is meant to transform keys in `properties` into new
     * keys. Each alias like `{ "xxx": "yyy" }` will take whatever is at `xxx` in
     * the traits, and move it to `yyy`. If `xxx` is a method of this facade, it'll
     * be called as a function instead of treated as a key into the traits.
     */
    properties(aliases?: object): { [key: string]: any };
    /**
     * Get the user's email from `context.traits.email` or `properties.email`,
     * falling back to `userId` if it's a valid email.
     *
     * This *should* be a string, but may not be if the client isn't adhering to
     * the spec.
     */
    email(): unknown;
    /**
     * Get the page fullName. This is `$category $name` if both are present, and
     * just `name` otherwiser.
     *
     * This *should* be a string, but may not be if the client isn't adhering to
     * the spec.
     */
    fullName(): unknown;
    /**
     * Get an event name from this page call. If `name` is present, this will be
     * `Viewed $name Page`; otherwise, it will be `Loaded a Page`.
     */
    event(name?: string): string;
    /**
     * Convert this Page to a {@link Track} facade. The inputted `name` will be
     * converted to the Track's event name via {@link Page#event}.
     */
    track(name?: string): Track;
  }

  export class Screen<T = { [key: string]: any }> extends Page<T> {}

  export class Delete<T = { [key: string]: any }> extends Facade<T> {}

  export class Alias<T = { [key: string]: any }> extends Facade<T> {
    /**
     * Get the user's previous ID from previousId or from.
     * This should be a string, but may not be if the client isn't adhering to the spec.
     */
    previousId(): unknown;
    /**
     * An alias for .previousId.
     */
    from(): unknown;
    /**
     * An alias for .userId
     */
    to(): unknown;
    /**
     * Get the user's new ID from userId or to.
     * This should be a string, but may not be if the client isn't adhering to the spec.
     */
    userId(): unknown;
  }
}