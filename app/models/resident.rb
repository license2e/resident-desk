class Resident
  include DataMapper::Resource
  
  property :id, Serial
  property :resident_name, String
  property :phone_number, String
  property :phone_number2, String
  property :email_address, String
  property :email_address2, String
  property :unit, Integer, :required => true, :index => true
  property :license_plate, String
  
  property :deleted_at, ParanoidDateTime
  
  property :created_at, DateTime
  property :created_on, Date
  property :updated_at, DateTime
  property :updated_on, Date
  
  def floor 
    return self.unit.to_s.rjust(4,"0")[0,2].to_i
  end
end

class Delivery
  include DataMapper::Resource
  
  property :id, Serial
  property :unit, Integer
  property :packages_number, Integer
  
  belongs_to :resident, :required => false
  belongs_to :user, :required => false
  
  property :pickedup_at, DateTime
  property :pickedup_on, Date
  
  property :created_at, DateTime
  property :created_on, Date
  property :updated_at, DateTime
  property :updated_on, Date
end

#Resident.auto_migrate! #unless Resident.storage_exists?
#Delivery.auto_migrate! #unless Delivery.storage_exists?
