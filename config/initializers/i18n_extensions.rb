module I18n
  def self.dir
    rtl_locales = [:ar, :arc, :dv, :fa, :ha, :khw, :ks, :ku, :ps, :ur, :yi]

    rtl_locales.include?(locale) ? 'rtl' : 'ltr'
  end
end
