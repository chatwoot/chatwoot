# don't serialize tokens
if defined? Devise::Models::Authenticatable::UNSAFE_ATTRIBUTES_FOR_SERIALIZATION
  Devise::Models::Authenticatable::UNSAFE_ATTRIBUTES_FOR_SERIALIZATION << :tokens
else
  Devise::Models::Authenticatable::BLACKLIST_FOR_SERIALIZATION << :tokens
end
