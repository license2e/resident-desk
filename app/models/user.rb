class User
  include DataMapper::Resource
  include Sinatra::SessionAuth::ModelHelpers
  
  property :id, Serial
  property :login, String
  property :salt, String
  property :hashed_password, String
  property :first_name, String
  property :last_name, String
  property :email_address, String
  property :phone_number, String
  property :phone_number2, String
  property :is_su, Boolean, :default => false
  property :is_admin, Boolean, :default => false
  property :is_concierge, Boolean, :default => false
  property :is_leasing, Boolean, :default => false
  property :lastlogin_at, DateTime
  
  property :delete_at, ParanoidDateTime
  
  property :created_at, DateTime
  property :created_on, Date
  property :updated_at, DateTime
  property :updated_on, Date
end
#User.auto_migrate! #unless User.storage_exists?
