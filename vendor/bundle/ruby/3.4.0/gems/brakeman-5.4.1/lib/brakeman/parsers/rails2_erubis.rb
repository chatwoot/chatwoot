Brakeman.load_brakeman_dependency 'erubis'

#Erubis processor which ignores any output which is plain text.
class Brakeman::ScannerErubis < Erubis::Eruby
  include Erubis::NoTextEnhancer
end
