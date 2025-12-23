begin
  require 'fiddle'
  require 'fiddle/import'
rescue LoadError
  module Reline::Terminfo
    def self.curses_dl
      false
    end
  end
end

module Reline::Terminfo
  extend Fiddle::Importer

  class TerminfoError < StandardError; end

  def self.curses_dl_files
    case RUBY_PLATFORM
    when /mingw/, /mswin/
      # aren't supported
      []
    when /cygwin/
      %w[cygncursesw-10.dll cygncurses-10.dll]
    when /darwin/
      %w[libncursesw.dylib libcursesw.dylib libncurses.dylib libcurses.dylib]
    else
      %w[libncursesw.so libcursesw.so libncurses.so libcurses.so]
    end
  end

  @curses_dl = false
  def self.curses_dl
    return @curses_dl unless @curses_dl == false
    if Fiddle.const_defined?(:TYPE_VARIADIC)
      curses_dl_files.each do |curses_name|
        result = Fiddle::Handle.new(curses_name)
      rescue Fiddle::DLError
        next
      else
        @curses_dl = result
        break
      end
    end
    @curses_dl = nil if @curses_dl == false
    @curses_dl
  end
end if not Reline.const_defined?(:Terminfo) or not Reline::Terminfo.respond_to?(:curses_dl)

module Reline::Terminfo
  dlload curses_dl
  #extern 'int setupterm(char *term, int fildes, int *errret)'
  @setupterm = Fiddle::Function.new(curses_dl['setupterm'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
  #extern 'char *tigetstr(char *capname)'
  @tigetstr = Fiddle::Function.new(curses_dl['tigetstr'], [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOIDP)
  begin
    #extern 'char *tiparm(const char *str, ...)'
    @tiparm = Fiddle::Function.new(curses_dl['tiparm'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VARIADIC], Fiddle::TYPE_VOIDP)
  rescue Fiddle::DLError
    # OpenBSD lacks tiparm
    #extern 'char *tparm(const char *str, ...)'
    @tiparm = Fiddle::Function.new(curses_dl['tparm'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VARIADIC], Fiddle::TYPE_VOIDP)
  end
  begin
    #extern 'int tigetflag(char *str)'
    @tigetflag = Fiddle::Function.new(curses_dl['tigetflag'], [Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
  rescue Fiddle::DLError
    # OpenBSD lacks tigetflag
    #extern 'int tgetflag(char *str)'
    @tigetflag = Fiddle::Function.new(curses_dl['tgetflag'], [Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
  end
  begin
    #extern 'int tigetnum(char *str)'
    @tigetnum = Fiddle::Function.new(curses_dl['tigetnum'], [Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
  rescue Fiddle::DLError
    # OpenBSD lacks tigetnum
    #extern 'int tgetnum(char *str)'
    @tigetnum = Fiddle::Function.new(curses_dl['tgetnum'], [Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
  end

  def self.setupterm(term, fildes)
    errret_int = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT)
    ret = @setupterm.(term, fildes, errret_int)
    errret = errret_int[0, Fiddle::SIZEOF_INT].unpack1('i')
    case ret
    when 0 # OK
      0
    when -1 # ERR
      case errret
      when 1
        raise TerminfoError.new('The terminal is hardcopy, cannot be used for curses applications.')
      when 0
        raise TerminfoError.new('The terminal could not be found, or that it is a generic type, having too little information for curses applications to run.')
      when -1
        raise TerminfoError.new('The terminfo database could not be found.')
      else # unknown
        -1
      end
    else # unknown
      -2
    end
  end

  class StringWithTiparm < String
    def tiparm(*args) # for method chain
      Reline::Terminfo.tiparm(self, *args)
    end
  end

  def self.tigetstr(capname)
    raise TerminfoError, "capname is not String: #{capname.inspect}" unless capname.is_a?(String)
    capability = @tigetstr.(capname)
    case capability.to_i
    when 0, -1
      raise TerminfoError, "can't find capability: #{capname}"
    end
    StringWithTiparm.new(capability.to_s)
  end

  def self.tiparm(str, *args)
    new_args = []
    args.each do |a|
      new_args << Fiddle::TYPE_INT << a
    end
    @tiparm.(str, *new_args).to_s
  end

  def self.tigetflag(capname)
    raise TerminfoError, "capname is not String: #{capname.inspect}" unless capname.is_a?(String)
    flag = @tigetflag.(capname).to_i
    case flag
    when -1
      raise TerminfoError, "not boolean capability: #{capname}"
    when 0
      raise TerminfoError, "can't find capability: #{capname}"
    end
    flag
  end

  def self.tigetnum(capname)
    raise TerminfoError, "capname is not String: #{capname.inspect}" unless capname.is_a?(String)
    num = @tigetnum.(capname).to_i
    case num
    when -2
      raise TerminfoError, "not numeric capability: #{capname}"
    when -1
      raise TerminfoError, "can't find capability: #{capname}"
    end
    num
  end

  def self.enabled?
    true
  end
end if Reline::Terminfo.curses_dl

module Reline::Terminfo
  def self.enabled?
    false
  end
end unless Reline::Terminfo.curses_dl
