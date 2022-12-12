export interface SynchronousPromise<T> extends Promise<T> {
  pause: () => SynchronousPromise<T>
  resume: () => SynchronousPromise<T>
}

export type ValueOrPromiseOfValue<T> = T | PromiseLike<T>
export type RejectedOutcome = {
  status: "rejected",
  reason: any
}
export type FulfilledOutcome<T> = {
  status: "fulfilled",
  value: T
}
export type SettledOutcome<T> = FulfilledOutcome<T> | RejectedOutcome

export interface SynchronousPromiseConstructor {
  /**
    * A reference to the prototype.
    */
  prototype: SynchronousPromise<any>;

  /**
    * Creates a new Promise.
    * @param executor A callback used to initialize the promise. This callback is passed two arguments:
    * a resolve callback used resolve the promise with a value or the result of another promise,
    * and a reject callback used to reject the promise with a provided reason or error.
    */
  new <T>(executor: (resolve: (value?: T | PromiseLike<T>) => void, reject: (reason?: any) => void) => void): SynchronousPromise<T>;

  /**
    * Creates a Promise that is resolved with an array of results when all of the provided Promises
    * resolve, or rejected when any Promise is rejected.
    * @param v1 An array of Promises
    * @returns A new Promise.
    */
  all<T>(v1: ValueOrPromiseOfValue<T>[]): SynchronousPromise<T[]>;
  /**
   * Creates a Promise that is resolved with an array of results when all of the provided Promises
   * resolve, or rejected when any Promise is rejected.
   * @param values Any number of Promises.
   * @returns A new Promise.
   */
  all<T>(...values: ValueOrPromiseOfValue<T>[]): SynchronousPromise<T[]>;

  /**
    * Creates a Promise that is resolved with an array of outcome objects after all of the provided Promises
    * have settled. Each outcome object has a .status of either "fulfilled" or "rejected" and corresponding
    * "value" or "reason" properties.
    * @param v1 An array of Promises.
    * @returns A new Promise.
    */
  allSettled<T>(v1: ValueOrPromiseOfValue<T>[]): SynchronousPromise<SettledOutcome<T>[]>;
  /**
   * Creates a Promise that is resolved with an array of outcome objects after all of the provided Promises
   * have settled. Each outcome object has a .status of either "fulfilled" or "rejected" and corresponding
   * "value" or "reason" properties.
   * @param values Any number of promises
   * @returns A new Promise.
   */
  allSettled<TAllSettled>(...values: ValueOrPromiseOfValue<TAllSettled>[]): SynchronousPromise<SettledOutcome<TAllSettled>[]>;

  /**
    * Creates a Promise that is resolved or rejected when any of the provided Promises are resolved
    * or rejected.
    * @param values An array of Promises.
    * @returns A new Promise.
    */
  // race<T>(values: IterableShim<T | PromiseLike<T>>): Promise<T>;

  /**
   * Creates a Promise that is resolved with the first value from the provided
   * Promises, or rejected when all provided Promises reject
    * @param v1 An array of Promises
   */
  any<T>(v1: ValueOrPromiseOfValue<T>[]): SynchronousPromise<T>;
  /**
   * Creates a Promise that is resolved with the first value from the provided
   * Promises, or rejected when all provided Promises reject
   * @param values Any number of Promises
   */
  any<T>(...values: ValueOrPromiseOfValue<T>[]): SynchronousPromise<T>;

  /**
    * Creates a new rejected promise for the provided reason.
    * @param reason The reason the promise was rejected.
    * @returns A new rejected Promise.
    */
  reject(reason: any): SynchronousPromise<void>;

  /**
    * Creates a new rejected promise for the provided reason.
    * @param reason The reason the promise was rejected.
    * @returns A new rejected Promise.
    */
  reject<T>(reason: any): SynchronousPromise<T>;

  /**
    * Creates a new resolved promise for the provided value.
    * @param value A promise.
    * @returns A promise whose internal state matches the provided promise.
    */
  resolve<T>(value: T | PromiseLike<T>): SynchronousPromise<T>;

  /**
    * Creates a new resolved promise .
    * @returns A resolved promise.
    */
  resolve(): SynchronousPromise<void>;

  /**
    * Creates a new unresolved promise with the `resolve` and `reject` methods exposed
    * @returns An unresolved promise with the `resolve` and `reject` methods exposed
    */
  unresolved<T>(): UnresolvedSynchronousPromise<T>;


  /**
    * Installs SynchronousPromise as the global Promise implementation.
    * When running from within typescript, you will need to use this to
    * patch the generated __awaiter to ensure it gets a _real_ Promise implementation
    * (see https://github.com/Microsoft/TypeScript/issues/19909).
    *
    * Use the following code:
    * declare var __awaiter: Function;
    * __awaiter = SynchronousPromise.installGlobally();
    *
    * This is non-destructive to the __awaiter: it simply wraps it in a closure
    * where the real implementation of Promise has already been captured.
    */
  installGlobally(__awaiter: Function): Function;

  /*
   * Uninstalls SynchronousPromise as the global Promise implementation,
   * if it is already installed.
   */
  uninstallGlobally(): void;
}

/**
 * Interface type only exposed when using the static unresolved() convenience method
 */
interface UnresolvedSynchronousPromise<T> extends SynchronousPromise<T>  {
  resolve<T>(data: T): void;
  resolve(): void;
  reject<T>(data: T): void;
}

export var SynchronousPromise: SynchronousPromiseConstructor;
