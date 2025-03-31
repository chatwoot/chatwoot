import { Ref, UnwrapRef, defineComponent, ComponentInternalInstance } from 'vue-demi';
type Component = ReturnType<typeof defineComponent>;

/*
 * Structure
 *
 * This package is mainly a validation engine. This engine requires 2
 * inputs: validation arguments and the state to be validated. The output
 * is a validation result.
 *
 * The structure of the validation object is constrained by the structure
 * of the validation arguments. These validation arguments also constraint
 * the type of the states that can be validated. And although the state does
 * not affect the structure of the validation result, it can narrow the
 * property "$model" in the validation result.
 *
 * Why do validation arguments constraint the type of the states that can
 * be validated? Because validation arguments make assumptions about the state.
 * For instance we expect a state `{ foo?: string }`, and we want to check
 * that `foo` is not empty, so we write `(foo?.length ?? 0) > 0`. If now we try
 * to validate the state `{ foo: [1] }` our validation result is meaningless.
 * This state would pass our test, but clearly it's not a valid object. This
 * situation was possible because that state violated our initial assumptions.
 *
 *
 *          Validation Arguments
 *                   |
 *              _____|____
 *             /          \
 *            |            |
 *            |      States to be validated
 *            |            |
 *            |            |
 *           Validation Result
 *
 */

export interface ValidatorResponse {
  $valid: boolean
  [key: string]: any
}

export type ValidatorFn <T = any, K = any, S = any> = (value: T, siblingState: K, vm: S) => boolean | ValidatorResponse | Promise<boolean | ValidatorResponse>;

export interface ValidationRuleWithoutParams <T = any> {
  $validator: ValidatorFn<T>
  $message?: string | Ref<string> | (() => string)
}

export interface ValidationRuleWithParams<P extends object = object, T = any> {
  $validator: ValidatorFn<T>
  $message: (input: { $params: P }) => string
  $params: P
}

export type ValidationRule <T = any> = ValidationRuleWithParams<any, T> | ValidationRuleWithoutParams<T> | ValidatorFn<T>;

export type ValidationRuleCollection <T = any> = Record<string, ValidationRule<T>>;

export type ValidationArgs<T = unknown> = {
  [key in keyof T]: ValidationArgs<T[key]> | ValidationRuleCollection<T[key]> | ValidationRule<T[key]>
}

export interface RuleResultWithoutParams {
  readonly $message: string
  readonly $pending: boolean
  readonly $invalid: boolean
  readonly $response: any
}

export interface RuleResultWithParams <P extends object = object> extends RuleResultWithoutParams {
  readonly $params: P
}

export type RuleResult = RuleResultWithoutParams | RuleResultWithParams;

type ExtractRuleResult <R extends ValidationRule> = R extends ValidationRuleWithParams<infer P> ? RuleResultWithParams<P> : RuleResultWithoutParams;

type ExtractRulesResults <T, Vrules extends ValidationRuleCollection<T> | undefined> = {
  readonly [K in keyof Vrules]: Vrules[K] extends ValidationRule ? ExtractRuleResult<Vrules[K]> : undefined;
};

export interface ErrorObject {
  readonly $propertyPath: string
  readonly $property: string
  readonly $validator: string
  readonly $message: string | Ref<string>
  readonly $params: object
  readonly $pending: boolean
  readonly $response: any,
  readonly $uid: string,
}

export type BaseValidation <
  T = unknown,
  Vrules extends ValidationRuleCollection<T> | undefined = undefined,
> = (
  Vrules extends ValidationRuleCollection<T>
    ? ExtractRulesResults<T, Vrules>
    : unknown) & {
  $model: T
  // const validationGetters
  readonly $dirty: boolean
  readonly $error: boolean
  readonly $errors: ErrorObject[]
  readonly $silentErrors: ErrorObject[]
  readonly $externalResults: ({ $validator: '$externalResults', $response: null, $pending: false, $params: {} } & ErrorObject)[]
  readonly $invalid: boolean
  readonly $anyDirty: boolean
  readonly $pending: boolean
  readonly $path: string

  // const validationMethods
  readonly $touch: () => void
  readonly $reset: () => void
  readonly $commit: () => void
  readonly $validate: () => Promise<boolean>

  // For accessing individual form properties on v$
  readonly [key: string]: any
};

export type NestedValidations <Vargs extends ValidationArgs = ValidationArgs, T = unknown> = {
  readonly [K in keyof Vargs]: BaseValidation<
  T extends Record<K, unknown> ? T[K] : unknown,
  Vargs[K] extends ValidationRuleCollection
    ? Vargs[K] : undefined
  > & (
    Vargs[K] extends Record<string, ValidationArgs>
      ? NestedValidations<Vargs[K], T extends Record<K, unknown> ? T[K] : unknown>
      : unknown
  )
};

interface ChildValidations {
  readonly $getResultsForChild: (key: string) => (BaseValidation & ChildValidations) | undefined
  readonly $clearExternalResults: () => void
}

export type Validation <Vargs extends ValidationArgs = ValidationArgs, T = unknown> =
  NestedValidations<Vargs, T> &
  BaseValidation<T, Vargs extends ValidationRuleCollection ? Vargs : any> &
  ChildValidations;

export type ExtractStateLeaf <Vrules extends ValidationRuleCollection> =
  Vrules extends ValidationRuleCollection<infer T>
    ? T
    : unknown;

export type ChildStateLeafs <Vargs extends ValidationArgs = ValidationArgs> = {
  [K in keyof Vargs]?: (
  Vargs[K] extends ValidationRuleCollection
    ? ExtractStateLeaf<Vargs[K]>
    : unknown
  ) & (
  Vargs[K] extends Record<string, ValidationArgs>
    ? ChildStateLeafs<Vargs[K]>
    : unknown
  )
};

export type ExtractState <Vargs extends ValidationArgs> = Vargs extends ValidationRuleCollection
  ? ExtractStateLeaf<Vargs> & ChildStateLeafs<Vargs>
  : ChildStateLeafs<Vargs>;

type ToRefs <T> = { [K in keyof T]: Ref<T[K]> };

export interface ServerErrors {
  [key: string]: string | string[] | ServerErrors
}

export interface GlobalConfig {
  $registerAs?: string
  $scope?: string | number | symbol | boolean
  $stopPropagation?: boolean
  $autoDirty?: boolean
  $lazy?: boolean,
  $externalResults?: ServerErrors | Ref<ServerErrors> | UnwrapRef<ServerErrors>,
  $rewardEarly?: boolean,
  currentVueInstance?: ComponentInternalInstance | null
}

export function useVuelidate(globalConfig?: GlobalConfig): Ref<Validation>;
export function useVuelidate<
  T extends {[key in keyof Vargs]: any},
  Vargs extends ValidationArgs = ValidationArgs,
  EState extends ExtractState<Vargs> = ExtractState<Vargs>
>(
  validationsArgs: Ref<Vargs> | Vargs,
  state: T | Ref<T> | ToRefs<T>,
  globalConfig?: GlobalConfig
): Ref<Validation<Vargs, T>>;

export default useVuelidate;
