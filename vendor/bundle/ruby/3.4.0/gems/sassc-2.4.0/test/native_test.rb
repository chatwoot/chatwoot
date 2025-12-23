# frozen_string_literal: true

require_relative "test_helper"

module SassC
  module NativeTest
    SAMPLE_SASS_STRING = "$size: 30px; .hi { width: $size; }"
    SPECIAL_SASS_STRING = "$sißßßßßße: 30px; .hßß©i { width: $size; }"
    SAMPLE_CSS_OUTPUT = ".hi {\n  width: 30px; }\n"
    BAD_SASS_STRING = "$size = 30px;"

    class General < MiniTest::Test
      def test_it_reports_the_libsass_version
        assert_equal "3.6.4", Native.version
      end
    end

    class DataContext < MiniTest::Test
      def teardown
        Native.delete_data_context(@data_context) if @data_context
      end

      def test_compile_status_is_zero_when_successful
        @data_context = Native.make_data_context(SAMPLE_SASS_STRING)
        context = Native.data_context_get_context(@data_context)

        status = Native.compile_data_context(@data_context)
        assert_equal 0, status

        status = Native.context_get_error_status(context)
        assert_equal 0, status
      end

      def test_compiled_css_is_correct
        @data_context = Native.make_data_context(SAMPLE_SASS_STRING)
        context = Native.data_context_get_context(@data_context)
        Native.compile_data_context(@data_context)

        css = Native.context_get_output_string(context)
        assert_equal SAMPLE_CSS_OUTPUT, css
      end

      def test_compile_status_is_one_if_failed
        @data_context = Native.make_data_context(BAD_SASS_STRING)
        context = Native.data_context_get_context(@data_context)

        status = Native.compile_data_context(@data_context)
        refute_equal 0, status

        status = Native.context_get_error_status(context)
        refute_equal 0, status
      end

      def test_multibyte_characters_work
        @data_context = Native.make_data_context(SPECIAL_SASS_STRING)
        context = Native.data_context_get_context(@data_context)

        status = Native.compile_data_context(@data_context)
        refute_equal 0, status
      end

      def test_custom_function
        data_context = Native.make_data_context("foo { margin: foo(); }")
        context = Native.data_context_get_context(data_context)
        options = Native.context_get_options(context)

        random_thing = FFI::MemoryPointer.from_string("hi")

        funct = FFI::Function.new(:pointer, [:pointer, :pointer]) do |s_args, cookie|
          Native.make_number(43, "px")
        end

        callback = Native.make_function(
          "foo()",
          funct,
          random_thing
        )

        list = Native.make_function_list(1)
        Native::function_set_list_entry(list, 0, callback);
        Native::option_set_c_functions(options, list)

        assert_equal Native.option_get_c_functions(options), list

        first_list_entry = Native.function_get_list_entry(list, 0)
        assert_equal Native.function_get_function(first_list_entry),
                     funct
        assert_equal Native.function_get_signature(first_list_entry),
                     "foo()"
        assert_equal Native.function_get_cookie(first_list_entry),
                     random_thing

        string = Native.make_string("hello")
        assert_equal :sass_string, Native.value_get_tag(string)
        assert_equal "hello", Native.string_get_value(string)

        number = Native.make_number(123.4, "rem")
        assert_equal 123.4, Native.number_get_value(number)
        assert_equal "rem", Native.number_get_unit(number)

        Native.compile_data_context(data_context)

        css = Native.context_get_output_string(context)
        assert_equal "foo {\n  margin: 43px; }\n", css
      end
    end

    class FileContext < MiniTest::Test
      include TempFileTest

      def teardown
        Native.delete_file_context(@file_context) if @file_context
      end

      def test_compile_status_is_zero_when_successful
        temp_file("style.scss", SAMPLE_SASS_STRING)

        @file_context = Native.make_file_context("style.scss")
        context = Native.file_context_get_context(@file_context)

        status = Native.compile_file_context(@file_context)
        assert_equal 0, status

        status = Native.context_get_error_status(context)
        assert_equal 0, status
      end

      def test_compiled_css_is_correct
        temp_file("style.scss", SAMPLE_SASS_STRING)

        @file_context = Native.make_file_context("style.scss")
        context = Native.file_context_get_context(@file_context)
        Native.compile_file_context(@file_context)

        css = Native.context_get_output_string(context)
        assert_equal SAMPLE_CSS_OUTPUT, css
      end

      def test_invalid_file_name
        temp_file("style.scss", SAMPLE_SASS_STRING)

        @file_context = Native.make_file_context("style.jajaja")
        context = Native.file_context_get_context(@file_context)
        status = Native.compile_file_context(@file_context)

        refute_equal 0, status

        error = Native.context_get_error_message(context)

        assert_match "Error: File to read not found or unreadable: style.jajaja",
                     error
      end

      def test_file_import
        temp_file("not_included.scss", "$size: 30px;")
        temp_file("import_parent.scss", "$size: 30px;")
        temp_file("import.scss", "@import 'import_parent'; $size: 30px;")
        temp_file("styles.scss", "@import 'import.scss'; .hi { width: $size; }")

        @file_context = Native.make_file_context("styles.scss")
        context = Native.file_context_get_context(@file_context)
        status = Native.compile_file_context(@file_context)

        assert_equal 0, status

        css = Native.context_get_output_string(context)
        assert_equal SAMPLE_CSS_OUTPUT, css

        included_files = Native.context_get_included_files(context)
        included_files.sort!

        assert_match /import.scss/, included_files[0]
        assert_match /import_parent.scss/, included_files[1]
        assert_match /styles.scss/, included_files[2]
      end

      def test_custom_importer
        temp_file("not_included.scss", "$size: $var + 25;")
        temp_file("styles.scss", "@import 'import.scss'; .hi { width: $size; }")

        @file_context = Native.make_file_context("styles.scss")
        context = Native.file_context_get_context(@file_context)
        options = Native.context_get_options(context)

        funct = FFI::Function.new(:pointer, [:pointer, :pointer, :pointer]) do |url, prev, cookie|
          list = Native.make_import_list(2)

          str = "$var: 5px;"
          data = FFI::MemoryPointer.from_string(str)
          data.autorelease = false

          entry0 = Native.make_import_entry("fake_includ.scss", data, nil)
          entry1 = Native.make_import_entry("not_included.scss", nil, nil)
          Native.import_set_list_entry(list, 0, entry0)
          Native.import_set_list_entry(list, 1, entry1)
          list
        end

        callback = Native.make_importer(funct, nil)
        list = Native.make_function_list(1)
        Native::function_set_list_entry(list, 0, callback)

        Native.option_set_c_importers(options, list)

        status = Native.compile_file_context(@file_context)
        assert_equal 0, status

        css = Native.context_get_output_string(context)
        assert_equal SAMPLE_CSS_OUTPUT, css
      end
    end
  end
end
