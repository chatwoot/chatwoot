/**
 * Namespace for matching utilities.
 * @namespace commons.matches
 * @memberof axe
 */
import attributes from './attributes';
import condition from './condition';
import explicitRole from './explicit-role';
import fromDefinition from './from-definition';
import fromFunction from './from-function';
import fromPrimative from './from-primative';
import implicitRole from './implicit-role';
import matches from './matches';
import nodeName from './node-name';
import properties from './properties';
import semanticRole from './semantic-role';

matches.attributes = attributes;
matches.condition = condition;
matches.explicitRole = explicitRole;
matches.fromDefinition = fromDefinition;
matches.fromFunction = fromFunction;
matches.fromPrimative = fromPrimative;
matches.implicitRole = implicitRole;
matches.nodeName = nodeName;
matches.properties = properties;
matches.semanticRole = semanticRole;

export default matches;
