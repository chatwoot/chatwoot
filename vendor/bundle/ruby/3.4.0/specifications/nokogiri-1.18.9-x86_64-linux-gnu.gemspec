# -*- encoding: utf-8 -*-
# stub: nokogiri 1.18.9 x86_64-linux-gnu lib

Gem::Specification.new do |s|
  s.name = "nokogiri".freeze
  s.version = "1.18.9".freeze
  s.platform = "x86_64-linux-gnu".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 3.3.22".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/sparklemotion/nokogiri/issues", "changelog_uri" => "https://nokogiri.org/CHANGELOG.html", "documentation_uri" => "https://nokogiri.org/rdoc/index.html", "homepage_uri" => "https://nokogiri.org", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/sparklemotion/nokogiri" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mike Dalessio".freeze, "Aaron Patterson".freeze, "Yoko Harada".freeze, "Akinori MUSHA".freeze, "John Shahid".freeze, "Karol Bucek".freeze, "Sam Ruby".freeze, "Craig Barnes".freeze, "Stephen Checkoway".freeze, "Lars Kanis".freeze, "Sergio Arbeo".freeze, "Timothy Elliott".freeze, "Nobuyoshi Nakada".freeze]
  s.date = "2025-07-21"
  s.description = "Nokogiri (\u92F8) makes it easy and painless to work with XML and HTML from Ruby. It provides a\nsensible, easy-to-understand API for reading, writing, modifying, and querying documents. It is\nfast and standards-compliant by relying on native parsers like libxml2, libgumbo, or xerces.\n".freeze
  s.email = "nokogiri-talk@googlegroups.com".freeze
  s.executables = ["nokogiri".freeze]
  s.extra_rdoc_files = ["ext/nokogiri/gumbo.c".freeze, "ext/nokogiri/html4_document.c".freeze, "ext/nokogiri/html4_element_description.c".freeze, "ext/nokogiri/html4_entity_lookup.c".freeze, "ext/nokogiri/html4_sax_parser.c".freeze, "ext/nokogiri/html4_sax_parser_context.c".freeze, "ext/nokogiri/html4_sax_push_parser.c".freeze, "ext/nokogiri/libxml2_polyfill.c".freeze, "ext/nokogiri/nokogiri.c".freeze, "ext/nokogiri/test_global_handlers.c".freeze, "ext/nokogiri/xml_attr.c".freeze, "ext/nokogiri/xml_attribute_decl.c".freeze, "ext/nokogiri/xml_cdata.c".freeze, "ext/nokogiri/xml_comment.c".freeze, "ext/nokogiri/xml_document.c".freeze, "ext/nokogiri/xml_document_fragment.c".freeze, "ext/nokogiri/xml_dtd.c".freeze, "ext/nokogiri/xml_element_content.c".freeze, "ext/nokogiri/xml_element_decl.c".freeze, "ext/nokogiri/xml_encoding_handler.c".freeze, "ext/nokogiri/xml_entity_decl.c".freeze, "ext/nokogiri/xml_entity_reference.c".freeze, "ext/nokogiri/xml_namespace.c".freeze, "ext/nokogiri/xml_node.c".freeze, "ext/nokogiri/xml_node_set.c".freeze, "ext/nokogiri/xml_processing_instruction.c".freeze, "ext/nokogiri/xml_reader.c".freeze, "ext/nokogiri/xml_relax_ng.c".freeze, "ext/nokogiri/xml_sax_parser.c".freeze, "ext/nokogiri/xml_sax_parser_context.c".freeze, "ext/nokogiri/xml_sax_push_parser.c".freeze, "ext/nokogiri/xml_schema.c".freeze, "ext/nokogiri/xml_syntax_error.c".freeze, "ext/nokogiri/xml_text.c".freeze, "ext/nokogiri/xml_xpath_context.c".freeze, "ext/nokogiri/xslt_stylesheet.c".freeze, "README.md".freeze]
  s.files = ["README.md".freeze, "bin/nokogiri".freeze, "ext/nokogiri/gumbo.c".freeze, "ext/nokogiri/html4_document.c".freeze, "ext/nokogiri/html4_element_description.c".freeze, "ext/nokogiri/html4_entity_lookup.c".freeze, "ext/nokogiri/html4_sax_parser.c".freeze, "ext/nokogiri/html4_sax_parser_context.c".freeze, "ext/nokogiri/html4_sax_push_parser.c".freeze, "ext/nokogiri/libxml2_polyfill.c".freeze, "ext/nokogiri/nokogiri.c".freeze, "ext/nokogiri/test_global_handlers.c".freeze, "ext/nokogiri/xml_attr.c".freeze, "ext/nokogiri/xml_attribute_decl.c".freeze, "ext/nokogiri/xml_cdata.c".freeze, "ext/nokogiri/xml_comment.c".freeze, "ext/nokogiri/xml_document.c".freeze, "ext/nokogiri/xml_document_fragment.c".freeze, "ext/nokogiri/xml_dtd.c".freeze, "ext/nokogiri/xml_element_content.c".freeze, "ext/nokogiri/xml_element_decl.c".freeze, "ext/nokogiri/xml_encoding_handler.c".freeze, "ext/nokogiri/xml_entity_decl.c".freeze, "ext/nokogiri/xml_entity_reference.c".freeze, "ext/nokogiri/xml_namespace.c".freeze, "ext/nokogiri/xml_node.c".freeze, "ext/nokogiri/xml_node_set.c".freeze, "ext/nokogiri/xml_processing_instruction.c".freeze, "ext/nokogiri/xml_reader.c".freeze, "ext/nokogiri/xml_relax_ng.c".freeze, "ext/nokogiri/xml_sax_parser.c".freeze, "ext/nokogiri/xml_sax_parser_context.c".freeze, "ext/nokogiri/xml_sax_push_parser.c".freeze, "ext/nokogiri/xml_schema.c".freeze, "ext/nokogiri/xml_syntax_error.c".freeze, "ext/nokogiri/xml_text.c".freeze, "ext/nokogiri/xml_xpath_context.c".freeze, "ext/nokogiri/xslt_stylesheet.c".freeze]
  s.homepage = "https://nokogiri.org".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new([">= 3.1".freeze, "< 3.5.dev".freeze])
  s.rubygems_version = "3.3.26".freeze
  s.summary = "Nokogiri (\u92F8) makes it easy and painless to work with XML and HTML from Ruby.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<racc>.freeze, ["~> 1.4".freeze])
end
