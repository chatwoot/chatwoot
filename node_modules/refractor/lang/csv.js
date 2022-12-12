'use strict'

module.exports = csv
csv.displayName = 'csv'
csv.aliases = []
function csv(Prism) {
  // https://tools.ietf.org/html/rfc4180
  Prism.languages.csv = {
    value: /[^\r\n,"]+|"(?:[^"]|"")*"(?!")/,
    punctuation: /,/
  }
}
