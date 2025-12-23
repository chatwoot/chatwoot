module Slim
  # Slim expression grammar
  # @api private
  module Grammar
    extend Temple::Grammar

    TextTypes << :verbatim | :explicit | :implicit | :inline

    Expression <<
      [:slim, :control, String, Expression]                 |
      [:slim, :output, Bool, String, Expression]            |
      [:slim, :interpolate, String]                         |
      [:slim, :embedded, String, Expression, HTMLAttrGroup] |
      [:slim, :text, TextTypes, Expression]                 |
      [:slim, :attrvalue, Bool, String]

    HTMLAttr <<
      [:slim, :splat, String]

    HTMLAttrGroup <<
      [:html, :attrs, 'HTMLAttr*']
  end
end
