import { FormKitNode, FormKitMessage } from '@formkit/core';
import { FormKitDependencies, FormKitObservedNode } from '@formkit/observer';

/**
 * Special validation properties that affect the way validations are applied.
 *
 * @public
 */
interface FormKitValidationHints {
    /**
     * If this validation fails, should it block the form from being submitted or
     * considered "valid"? There are some cases where it is acceptable to allow
     * an incorrect value to still be allowed to submit.
     */
    blocking: boolean;
    /**
     * Only run this rule after this many milliseconds of debounce. This is
     * particularity helpful for more "expensive" async validation rules like
     * checking if a username is taken from the backend.
     */
    debounce: number;
    /**
     * Normally the first validation rule to fail blocks other rules from running
     * if this flag is flipped to true, this rule will be run every time even if
     * a previous rule in the validation stack failed.
     */
    force: boolean;
    /**
     * Most validation rules are not run when the input is empty, but this flag
     * allows that behavior to be changed.
     */
    skipEmpty: boolean;
    /**
     * The actual name of the validation rule.
     */
    name: string;
}
/**
 * Defines what fully parsed validation rules look like.
 * @public
 */
type FormKitValidation = {
    /**
     * The actual rule function that will be called
     */
    rule: FormKitValidationRule;
    /**
     * Arguments to be passed to the validation rule
     */
    args: any[];
    /**
     * The debounce timer for this input.
     */
    timer: number;
    /**
     * The state of a validation, can be true, false, or null which means unknown.
     */
    state: boolean | null;
    /**
     * Determines if the rule should be considered for the next run cycle. This
     * does not mean the rule will be validated, it just means that it should be
     * considered.
     */
    queued: boolean;
    /**
     * Dependencies this validation rule is observing.
     */
    deps: FormKitDependencies;
    /**
     * The observed node that is being validated.
     */
    observer: FormKitObservedNode;
    /**
     * An observer that updates validation messages when it’s dependencies change,
     * for example, the label of the input.
     */
    messageObserver?: FormKitObservedNode;
} & FormKitValidationHints;
/**
 * Defines what validation rules look like when they are parsed, but have not
 * necessarily had validation rules substituted in yet.
 * @public
 */
type FormKitValidationIntent = [string | FormKitValidationRule, ...any[]];
/**
 * Signature for a generic validation rule. It accepts an input — often a string
 * — but should be able to accept any input type, and returns a boolean
 * indicating whether or not it passed validation.
 * @public
 */
type FormKitValidationRule = {
    (node: FormKitNode, ...args: any[]): boolean | Promise<boolean>;
    ruleName?: string;
} & Partial<FormKitValidationHints>;
/**
 * FormKit validation rules are structured as on object of key/function pairs
 * where the key of the object is the validation rule name.
 * @public
 */
interface FormKitValidationRules {
    [index: string]: FormKitValidationRule;
}
/**
 * The interface for the localized validation message function.
 * @public
 */
interface FormKitValidationMessage {
    (...args: FormKitValidationI18NArgs): string;
}
/**
 * The interface for the localized validation message registry.
 * @public
 */
interface FormKitValidationMessages {
    [index: string]: string | FormKitValidationMessage;
}
/**
 * The arguments that are passed to the validation messages in the i18n plugin.
 *
 * @public
 */
type FormKitValidationI18NArgs = [
    {
        node: FormKitNode;
        name: string;
        args: any[];
        message?: string;
    }
];
/**
 * The actual validation plugin function. Everything must be bootstrapped here.
 *
 * @param baseRules - Base validation rules to include in the plugin. By default,
 * FormKit makes all rules in the \@formkit/rules package available via the
 * defaultConfig.
 *
 * @public
 */
declare function createValidationPlugin(baseRules?: FormKitValidationRules): (node: FormKitNode) => void;
/**
 * Given a node, this returns the name that should be used in validation
 * messages. This is either the `validationLabel` prop, the `label` prop, or
 * the name of the input (in that order).
 * @param node - The node to display
 * @returns
 * @public
 */
declare function createMessageName(node: FormKitNode): string;
/**
 * Extracts all validation messages from the given node and all its descendants.
 * This is not reactive and must be re-called each time the messages change.
 * @param node - The FormKit node to extract validation rules from — as well as its descendants.
 * @public
 */
declare function getValidationMessages(node: FormKitNode): Map<FormKitNode, FormKitMessage[]>;

export { type FormKitValidation, type FormKitValidationHints, type FormKitValidationI18NArgs, type FormKitValidationIntent, type FormKitValidationMessage, type FormKitValidationMessages, type FormKitValidationRule, type FormKitValidationRules, createMessageName, createValidationPlugin, getValidationMessages };
