# Virtual model for sticker authorization
# This class doesn't represent a database table but is used for Pundit authorization
class Sticker
  include ActiveModel::Model
  
  # This is a virtual model used only for authorization purposes
  # Actual sticker data is stored in Attachment model with sticker metadata
end