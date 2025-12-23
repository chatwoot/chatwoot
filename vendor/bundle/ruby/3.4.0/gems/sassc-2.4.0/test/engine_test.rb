# frozen_string_literal: true

require_relative "test_helper"

module SassC
  class EngineTest < MiniTest::Test
    include TempFileTest

    def render(data)
      Engine.new(data).render
    end

    def test_line_comments
      template = <<-SCSS
.foo {
  baz: bang; }
      SCSS
      expected_output = <<-CSS
/* line 1, stdin */
.foo {
  baz: bang; }
      CSS
      output = Engine.new(template, line_comments: true).render
      assert_equal expected_output, output
    end

    def test_one_line_comments
      assert_equal <<CSS, render(<<SCSS)
.foo {
  baz: bang; }
CSS
.foo {// bar: baz;}
  baz: bang; //}
}
SCSS
      assert_equal <<CSS, render(<<SCSS)
.foo bar[val="//"] {
  baz: bang; }
CSS
.foo bar[val="//"] {
  baz: bang; //}
}
SCSS
  end

    def test_variables
      assert_equal <<CSS, render(<<SCSS)
blat {
  a: foo; }
CSS
$var: foo;

blat {a: $var}
SCSS

      assert_equal <<CSS, render(<<SCSS)
foo {
  a: 2;
  b: 6; }
CSS
foo {
  $var: 2;
  $another-var: 4;
  a: $var;
  b: $var + $another-var;}
SCSS
    end

    def test_precision
      template = <<-SCSS
$var: 1;
.foo {
  baz: $var / 3; }
SCSS
      expected_output = <<-CSS
.foo {
  baz: 0.33333333; }
CSS
      output = Engine.new(template, precision: 8).render
      assert_equal expected_output, output
    end

    def test_precision_not_specified
      template = <<-SCSS
$var: 1;
.foo {
  baz: $var / 3; }
SCSS
      expected_output = <<-CSS
.foo {
  baz: 0.3333333333; }
CSS
      output = Engine.new(template).render
      assert_equal expected_output, output
    end

    def test_dependency_filenames_are_reported
      base = temp_dir("").to_s

      temp_file("not_included.scss", "$size: 30px;")
      temp_file("import_parent.scss", "$size: 30px;")
      temp_file("import.scss", "@import 'import_parent'; $size: 30px;")
      temp_file("styles.scss", "@import 'import.scss'; .hi { width: $size; }")

      engine = Engine.new(File.read("styles.scss"))
      engine.render
      deps = engine.dependencies

      expected = ["/import.scss", "/import_parent.scss"]
      assert_equal expected, deps.map { |dep| dep.options[:filename].gsub(base, "") }.sort
      assert_equal expected, deps.map { |dep| dep.filename.gsub(base, "") }.sort
    end

    def test_no_dependencies
      engine = Engine.new("$size: 30px;")
      engine.render
      deps = engine.dependencies
      assert_equal [], deps
    end

    def test_not_rendered_error
      engine = Engine.new("$size: 30px;")
      assert_raises(NotRenderedError) { engine.dependencies }
    end

    def test_source_map
      temp_dir('admin')

      temp_file('admin/text-color.scss', <<SCSS)
p {
  color: red;
}
SCSS
      temp_file('style.scss', <<SCSS)
@import 'admin/text-color';

p {
  padding: 20px;
}
SCSS
      engine = Engine.new(File.read('style.scss'), {
        source_map_file: "style.scss.map",
        source_map_contents: true
      })
      engine.render

      assert_equal <<MAP.strip, engine.source_map
{
\t"version": 3,
\t"file": "stdin.css",
\t"sources": [
\t\t"stdin",
\t\t"admin/text-color.scss"
\t],
\t"sourcesContent": [
\t\t"@import 'admin/text-color';\\n\\np {\\n  padding: 20px;\\n}\\n",
\t\t"p {\\n  color: red;\\n}\\n"
\t],
\t"names": [],
\t"mappings": "ACAA,AAAA,CAAC,CAAC;EACA,KAAK,EAAE,GAAG,GACX;;ADAD,AAAA,CAAC,CAAC;EACA,OAAO,EAAE,IAAI,GACd"
}
MAP
    end

    def test_no_source_map
      engine = Engine.new("$size: 30px;")
      engine.render
      assert_raises(NotRenderedError) { engine.source_map }
    end

    def test_omit_source_map_url
      temp_file('style.scss', <<SCSS)
p {
  padding: 20px;
}
SCSS
      engine = Engine.new(File.read('style.scss'), {
        source_map_file: "style.scss.map",
        source_map_contents: true,
        omit_source_map_url: true
      })
      output = engine.render

      refute_match /sourceMappingURL/, output
    end

    def test_load_paths
      temp_dir("included_1")
      temp_dir("included_2")

      temp_file("included_1/import_parent.scss", "$s: 30px;")
      temp_file("included_2/import.scss", "@import 'import_parent'; $size: $s;")
      temp_file("styles.scss", "@import 'import.scss'; .hi { width: $size; }")

      assert_equal ".hi {\n  width: 30px; }\n", Engine.new(
        File.read("styles.scss"),
        load_paths: [ "included_1", "included_2" ]
      ).render
    end

    def test_global_load_paths
      temp_dir("included_1")
      temp_dir("included_2")

      temp_file("included_1/import_parent.scss", "$s: 30px;")
      temp_file("included_2/import.scss", "@import 'import_parent'; $size: $s;")
      temp_file("styles.scss", "@import 'import.scss'; .hi { width: $size; }")

      ::SassC.load_paths << "included_1"
      ::SassC.load_paths << "included_2"

      assert_equal ".hi {\n  width: 30px; }\n", Engine.new(
        File.read("styles.scss"),
      ).render
      ::SassC.load_paths.clear
    end

    def test_env_load_paths
      expected_load_paths = [ "included_1", "included_2" ]
      ::SassC.instance_eval { @load_paths = nil }
      ENV['SASS_PATH'] = expected_load_paths.join(File::PATH_SEPARATOR)
      assert_equal expected_load_paths, ::SassC.load_paths
      ::SassC.load_paths.clear
    end

    def test_load_paths_not_configured
      temp_file("included_1/import_parent.scss", "$s: 30px;")
      temp_file("included_2/import.scss", "@import 'import_parent'; $size: $s;")
      temp_file("styles.scss", "@import 'import.scss'; .hi { width: $size; }")

      assert_raises(SyntaxError) do
        Engine.new(File.read("styles.scss")).render
      end
    end

    def test_sass_variation
      sass = <<SASS
$size: 30px
.foo
  width: $size
SASS

    css = <<CSS
.foo {
  width: 30px; }
CSS

      assert_equal css, Engine.new(sass, syntax: :sass).render
      assert_equal css, Engine.new(sass, syntax: "sass").render
      assert_raises(SyntaxError) { Engine.new(sass).render }
    end

    def test_encoding_matches_input
      input = String.new("$size: 30px;")
      input.force_encoding("UTF-8")
      output = Engine.new(input).render
      assert_equal input.encoding, output.encoding
    end

    def test_inline_source_maps
      template = <<-SCSS
.foo {
  baz: bang; }
      SCSS
      expected_output = <<-CSS
/* line 1, stdin */
.foo {
  baz: bang; }
      CSS

      output = Engine.new(template, {
        source_map_file: ".",
        source_map_embed: true,
        source_map_contents: true
      }).render

      assert_match /sourceMappingURL/, output
      assert_match /.foo/, output
    end

    def test_empty_template
      output = Engine.new('').render
      assert_equal '', output
    end

    def test_empty_template_returns_a_new_object
      input = String.new
      output = Engine.new(input).render
      assert !input.equal?(output), 'empty template must return a new object'
    end

    def test_empty_template_encoding_matches_input
      input = String.new.force_encoding("ISO-8859-1")
      output = Engine.new(input).render
      assert_equal input.encoding, output.encoding
    end

    def test_handling_of_frozen_strings
      output = Engine.new("body { background-color: red; }".freeze).render
      assert_equal output, "body {\n  background-color: red; }\n"
    end

    def test_import_plain_css
      temp_file("test.css", ".something{color: red}")
      expected_output = <<-CSS
.something {
  color: red; }
      CSS

      output = Engine.new("@import 'test'").render
      assert_equal expected_output, output
    end
  end
end
