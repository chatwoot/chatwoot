module Brakeman::ModuleHelper
  def handle_module exp, tracker_class, parent = nil
    name = class_name(exp.module_name)

    if @current_module
      outer_module = @current_module
      name = (outer_module.name.to_s + "::" + name.to_s).to_sym
    end

    if @current_class
      name = (@current_class.name.to_s + "::" + name.to_s).to_sym
    end

    if @tracker.libs[name]
      @current_module = @tracker.libs[name]
      @current_module.add_file @current_file, exp
    else
      @current_module = tracker_class.new name, parent, @current_file, exp, @tracker
      @tracker.libs[name] = @current_module
    end

    exp.body = process_all! exp.body

    if outer_module
      @current_module = outer_module
    else
      @current_module = nil
    end

    exp
  end

  def handle_class exp, collection, tracker_class
    name = class_name(exp.class_name)
    parent = class_name exp.parent_name

    if @current_class
      outer_class = @current_class
      name = (outer_class.name.to_s + "::" + name.to_s).to_sym
    end

    if @current_module
      name = (@current_module.name.to_s + "::" + name.to_s).to_sym
    end

    if collection[name]
      @current_class = collection[name]
      @current_class.add_file @current_file, exp
    else
      @current_class = tracker_class.new name, parent, @current_file, exp, @tracker
      collection[name] = @current_class
    end

    exp.body = process_all! exp.body

    yield if block_given?

    if outer_class
      @current_class = outer_class
    else
      @current_class = nil
    end

    exp
  end

  def process_defs exp
    name = exp.method_name

    if node_type? exp[1], :self
      if @current_class
        target = @current_class.name
      elsif @current_module
        target = @current_module.name
      else
        target = nil
      end
    else
      target = class_name exp[1]
    end

    @current_method = name
    res = Sexp.new :defs, target, name, exp.formal_args, *process_all!(exp.body)
    res.line(exp.line)
    @current_method = nil

    if @current_class
      @current_class.add_method @visibility, name, res, @current_file
    elsif @current_module
      @current_module.add_method @visibility, name, res, @current_file
    end
    res
  end

  def process_defn exp
    name = exp.method_name

    @current_method = name
    res = Sexp.new :defn, name, exp.formal_args, *process_all!(exp.body)
    res.line(exp.line)
    @current_method = nil

    if @current_class
      @current_class.add_method @visibility, name, res, @current_file
    elsif @current_module
      @current_module.add_method @visibility, name, res, @current_file
    end

    res
  end
end
