# encoding: US-ASCII

require "minitest/autorun"
require "ruby_parser_extras"
require "ruby_parser"

class TestStackState < Minitest::Test
  attr_reader :s

  def setup
    @s = RubyParserStuff::StackState.new :test
  end

  def assert_encoding str, default = false
    orig_str = str.dup
    p = RubyParser.latest
    s = nil

    out, err = capture_io {
      s = p.handle_encoding str
    }

    assert_equal orig_str.sub(/\357\273\277/, ""), s

    exp_err = ""

    if defined?(Encoding) then
      assert_equal "UTF-8", s.encoding.to_s, str.inspect
    else
      exp_err = "Skipping magic encoding comment\n" unless default
    end

    assert_equal "", out, str.inspect
    assert_equal exp_err, err, str.inspect # HACK
  end

  def test_handle_encoding_bom
    # bom support, default to utf-8
    assert_encoding "\xEF\xBB\xBF# blah"
    # we force_encode to US-ASCII, then encode to UTF-8 so our lexer will work
    assert_encoding "\xEF\xBB\xBF# encoding: US-ASCII"
  end

  def test_handle_encoding_default
    assert_encoding "blah", :default
  end

  def test_handle_encoding_emacs
    # Q: how many different ways can we screw these up? A: ALL OF THEM

    assert_encoding "# - encoding: utf-8 -"
    assert_encoding "# - encoding:utf-8"
    assert_encoding "# -* coding: UTF-8 -*-"
    assert_encoding "# -*- coding: UTF-8 -*-"
    assert_encoding "# -*- coding: utf-8 -*"
    assert_encoding "# -*- coding: utf-8 -*-"
    assert_encoding "# -*- coding: utf-8; mode: ruby -*-"
    assert_encoding "# -*- coding: utf-8; mode: ruby; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2"
    assert_encoding "# -*- coding:utf-8; mode:ruby; -*-"
    assert_encoding "# -*- encoding: UTF-8 -*-"
    assert_encoding "# -*- encoding: utf-8 -*"
    assert_encoding "# -*- encoding: utf-8 -*-"
    assert_encoding "# -*- mode:ruby; coding:utf-8 -*-"
    assert_encoding "# -*- ruby encoding: utf-8 -*-"
    assert_encoding "# -- encoding: utf-8 --"
    assert_encoding "# ~*~ encoding: utf-8 ~*~"
    assert_encoding "#-*- coding: utf-8 -*-"
    assert_encoding "#-*- coding:utf-8"
    assert_encoding "#--  -*- mode: ruby; encoding: utf-8 -*-\n"
  end

  def test_handle_encoding_wtf
    assert_encoding "# coding : utf-8"
    assert_encoding "# Ruby 1.9: encoding: utf-8"
    assert_encoding "# Encoding: UTF-8 <-- required, please leave this in."
    assert_encoding "# Encoding: UTF-8"
    assert_encoding "# coding: utf-8"
    assert_encoding "# coding:utf-8"
    assert_encoding "# coding=utf-8"
    assert_encoding "# encoding: ASCII"
    assert_encoding "# encoding: ASCII-8BIT"
    assert_encoding "# encoding: ISO-8859-1"
    assert_encoding "# encoding: UTF-8"
    assert_encoding "# encoding: ascii-8bit"
    assert_encoding "# encoding: cp1252"
    assert_encoding "# encoding: euc-jp -*-"
    assert_encoding "# encoding: utf-8 # -*- ruby -*-"
    assert_encoding "# encoding: utf-8 require 'github_api/utils/url'"
    assert_encoding "# encoding: utf-8!"
    assert_encoding "# encoding: utf-8"
    assert_encoding "#<Encoding:UTF-8>"
    assert_encoding "#Encoding: UTF-8"
    assert_encoding "#coding:utf-8"
    assert_encoding "#encoding: UTF-8!"
    assert_encoding "#encoding: UTF-8"
    assert_encoding "#encoding: cp1252"
    assert_encoding "#encoding: sjis"
    assert_encoding "#encoding: utf-8"
  end

  def test_handle_encoding_normal
    assert_encoding "# encoding: UTF-8"
    assert_encoding "# encoding: UTF-8\r\n" # UGH I hate windoze
    assert_encoding "# coding: UTF-8"
    assert_encoding "# encoding = UTF-8"
    assert_encoding "# coding = UTF-8"
  end

  def test_handle_encoding_vim
    assert_encoding "#  vim: set fileencoding=utf-8 filetype=ruby ts=2 : "
    assert_encoding "# vim: fileencoding=UTF-8 ft=ruby syn=ruby ts=2 sw=2 ai eol et si"
    assert_encoding "# vim: fileencoding=UTF-8 nobomb sw=2 ts=2 et"
    assert_encoding "# vim: filetype=ruby, fileencoding=UTF-8, tabsize=2, shiftwidth=2"
    assert_encoding "# vim: set fileencoding=utf-8"
    assert_encoding "# vim:encoding=UTF-8:"
    assert_encoding "# vim:fileencoding=UTF-8:"
    assert_encoding "# vim:set fileencoding=utf-8 filetype=ruby"
    assert_encoding "# vim:set fileencoding=utf-8:"
  end

  def test_stack_state
    s.push true
    s.push false
    s.lexpop
    assert_equal [false, true], s.stack
  end

  def test_is_in_state
    assert_equal false, s.is_in_state
    s.push false
    assert_equal false, s.is_in_state
    s.push true
    assert_equal true, s.is_in_state
    s.push false
    assert_equal false, s.is_in_state
  end

  def test_lexpop
    assert_equal [false], s.stack
    s.push true
    s.push false
    assert_equal [false, true, false], s.stack
    s.lexpop
    assert_equal [false, true], s.stack
  end

  def test_pop
    assert_equal [false], s.stack
    s.push true
    assert_equal [false, true], s.stack
    assert_equal true, s.pop
    assert_equal [false], s.stack
  end

  def test_push
    assert_equal [false], s.stack
    s.push true
    s.push false
    assert_equal [false, true, false], s.stack
  end
end

class TestEnvironment < Minitest::Test
  def deny t
    assert !t
  end

  def setup
    @env = RubyParserStuff::Environment.new
    @env[:blah] = 42
    assert_equal 42, @env[:blah]
  end

  def test_var_scope_dynamic
    @env.extend :dynamic
    assert_equal 42, @env[:blah]
    @env.unextend
    assert_equal 42, @env[:blah]
  end

  def test_var_scope_static
    @env.extend
    assert_nil @env[:blah]
    @env.unextend
    assert_equal 42, @env[:blah]
  end

  def test_all_dynamic
    expected = { :blah => 42 }

    @env.extend :dynamic
    assert_equal expected, @env.all
    @env.unextend
    assert_equal expected, @env.all
  end

  def test_all_static
    @env.extend
    expected = { }
    assert_equal expected, @env.all

    @env.unextend
    expected = { :blah => 42 }
    assert_equal expected, @env.all
  end

  def test_all_static_deeper
    expected0 = { :blah => 42 }
    expected1 = { :blah => 42, :blah2 => 24 }
    expected2 = { :blah => 27 }

    @env.extend :dynamic
    @env[:blah2] = 24
    assert_equal expected1, @env.all

    @env.extend
    @env[:blah] = 27
    assert_equal expected2, @env.all

    @env.unextend
    assert_equal expected1, @env.all

    @env.unextend
    assert_equal expected0, @env.all
  end
end

class Fake20
  include RubyParserStuff

  def initialize
  end

  def s(*a) # bypass lexer/lineno stuff that RP overrides in
    Kernel.send :s, *a
  end
end

class TestValueExpr < Minitest::Test
  def assert_value_expr exp, input
    assert_equal exp, Fake20.new.value_expr(input.line(1))
  end

  def assert_remove_begin exp, input
    assert_equal exp, Fake20.new.remove_begin(input.line(1))
  end

  def test_value_expr
    assert_value_expr s(:nil),                     s(:begin)
    assert_value_expr s(:nil),                     s(:begin, s(:nil))
    assert_value_expr s(:nil),                     s(:begin, s(:begin, s(:nil)))
    assert_value_expr s(:begin, s(:nil), s(:nil)), s(:begin, s(:nil), s(:nil))
  end

  def test_remove_begin
    assert_remove_begin s(:nil),                     s(:begin)
    assert_remove_begin s(:nil),                     s(:begin, s(:nil))
    assert_remove_begin s(:nil),                     s(:begin, s(:begin, s(:nil)))
    assert_remove_begin s(:begin, s(:nil), s(:nil)), s(:begin, s(:nil), s(:nil))
  end
end
