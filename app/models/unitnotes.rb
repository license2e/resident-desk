class UnitNotes
  include DataMapper::Resource
  
  property :id, Serial
  property :unit, Integer
  property :note, Text
  
  property :deleted_at, ParanoidDateTime
  
  belongs_to :user, :required => false
  
  property :created_at, DateTime
  property :created_on, Date
  property :updated_at, DateTime
  property :updated_on, Date
end
#UnitNotes.auto_migrate! #unless UnitNotes.storage_exists?