import Handlebars from 'handlebars';
export function handlebars(source, data) {
  var template = Handlebars.compile(source);
  return template(data);
}