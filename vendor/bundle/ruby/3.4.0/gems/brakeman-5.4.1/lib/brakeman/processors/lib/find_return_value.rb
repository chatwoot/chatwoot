require 'brakeman/processors/alias_processor'

#Attempts to determine the return value of a method.
#
#Preferred usage:
#
#  Brakeman::FindReturnValue.return_value exp
class Brakeman::FindReturnValue
  include Brakeman::Util

  #Returns a guess at the return value of a given method or other block of code.
  #
  #If multiple return values are possible, returns all values in an :or Sexp.
  def self.return_value exp, env = nil
    self.new.get_return_value exp, env
  end

  def initialize
    @uses_ivars = false
    @return_values = []
  end

  def uses_ivars?
    @uses_ivars
  end

  #Find return value of Sexp. Takes an optional starting environment.
  def get_return_value exp, env = nil
    process_method exp, env
    value = make_return_value
    value.original_line = exp.line
    value
  end

  #Process method (or, actually, any Sexp) for return value.
  def process_method exp, env = nil
    exp = Brakeman::AliasProcessor.new.process_safely exp, env

    find_explicit_return_values exp

    if node_type? exp, :defn, :defs
      body = exp.body

      unless body.empty?
        @return_values << last_value(body)
      else
        Brakeman.debug "FindReturnValue: Empty method? #{exp.inspect}"
      end
    elsif exp
      @return_values << last_value(exp)
    else
       Brakeman.debug "FindReturnValue: Given something strange? #{exp.inspect}"
    end

    exp
  end

  #Searches expression for return statements.
  def find_explicit_return_values exp
    todo = [exp]

    until todo.empty?
      current = todo.shift

      @uses_ivars = true if node_type? current, :ivar

      if node_type? current, :return
        @return_values << last_value(current.value) if current.value
      elsif sexp? current
        todo = current[1..-1].concat todo
      end
    end
  end

  #Determines the "last value" of an expression.
  def last_value exp
    case exp.node_type
    when :rlist, :block, :scope, Sexp
      last_value exp.last
    when :if
      then_clause = exp.then_clause
      else_clause = exp.else_clause

      if then_clause.nil? and else_clause.nil?
        nil
      elsif then_clause.nil?
        last_value else_clause
      elsif else_clause.nil?
        last_value then_clause
      else
        true_branch = last_value then_clause
        false_branch = last_value else_clause

        if true_branch and false_branch
          value = make_or(true_branch, false_branch)
          value.original_line = value.rhs.line
          value
        else #Unlikely?
          true_branch or false_branch
        end
      end
    when :lasgn, :iasgn, :op_asgn_or, :attrasgn
      last_value exp.rhs
    when :rescue
      values = []

      exp.each_sexp do |e|
        if node_type? e, :resbody
          if e.last
            values << last_value(e.last)
          end
        elsif sexp? e
          values << last_value(e)
        end
      end

      values.reject! do |v|
        v.nil? or node_type? v, :nil
      end

      if values.length > 1
        values.inject do |m, v|
          make_or(m, v)
        end
      else
        values.first
      end
    when :return
      if exp.value
        last_value exp.value
      else
        nil
      end
    when :nil
      nil
    else
      exp.original_line = exp.line unless exp.original_line
      exp
    end
  end

  def make_or lhs, rhs
    #Better checks in future
    if lhs == rhs
      lhs
    else
      Sexp.new(:or, lhs, rhs)
    end
  end

  #Turns the array of return values into an :or Sexp
  def make_return_value
    @return_values.compact!
    @return_values.uniq!

    if @return_values.empty?
      Sexp.new(:nil)
    elsif @return_values.length == 1
      @return_values.first
    else
      @return_values.reduce do |value, sexp|
        make_or value, sexp
      end
    end
  end
end
