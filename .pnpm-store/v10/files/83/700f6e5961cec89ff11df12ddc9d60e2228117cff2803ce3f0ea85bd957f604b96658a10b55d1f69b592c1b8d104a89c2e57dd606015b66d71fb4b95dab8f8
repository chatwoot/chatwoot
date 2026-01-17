function parse_option(a, b) {
  return "undefined" == typeof a ? b : a;
}
function create_object_array(a) {
  const b = Array(a);
  for (let c = 0; c < a; c++)
    b[c] = create_object();
  return b;
}
function create_arrays(a) {
  const b = Array(a);
  for (let c = 0; c < a; c++)
    b[c] = [];
  return b;
}
function get_keys(a) {
  return Object.keys(a);
}
function create_object() {
  return /* @__PURE__ */ Object.create(null);
}
function concat(a) {
  return [].concat.apply([], a);
}
function sort_by_length_down(c, a) {
  return a.length - c.length;
}
function is_array(a) {
  return a.constructor === Array;
}
function is_string(a) {
  return "string" == typeof a;
}
function is_object(a) {
  return "object" == typeof a;
}
function is_function(a) {
  return "function" == typeof a;
}
export {
  concat,
  create_arrays,
  create_object,
  create_object_array,
  get_keys,
  is_array,
  is_function,
  is_object,
  is_string,
  parse_option,
  sort_by_length_down
};
