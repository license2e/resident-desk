class Unit
  include DataMapper::Resource
  
  property :unit, Integer, :key => true
  property :sublease, String
  property :pets, Integer
  
  property :created_at, DateTime
  property :created_on, Date
  property :updated_at, DateTime
  property :updated_on, Date
end
#Unit.auto_migrate! #unless Unit.storage_exists?