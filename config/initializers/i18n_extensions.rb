module I18n
  def self.dir(locale)
    rtl_locales = [:ar, :arc, :dv, :fa, :ha, :he, :khw, :ks, :ku, :ps, :ur, :yi]
    rtl_locales.include?(locale.to_sym) ? 'rtl' : 'ltr'
  end
end
