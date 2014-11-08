class App < Sinatra::Base
  
  ENV['RACK_ENV'] ||= "development"
  
  helpers Sinatra::SessionAuth::Helpers
  helpers Sinatra::ContentFor2
  register Sinatra::Head
  
  set :default_path, File.dirname(File.dirname(File.dirname(__FILE__)))
  set :views, File.join(settings.default_path, 'views')
  set :public_path, File.join(settings.default_path, 'public')
  set :config_path, File.join(settings.default_path, 'config')
  set :data_path, File.join(settings.default_path, 'data')
  set :run, false
  set :haml, :format => :html5, :attr_wrapper => '"'
  set :layout, true
  set :logging, true
  set :sessions, true
  set :session_secret, "3@83%106^$12J@l32k*76@SDFG&sd[36a}"
  set :layout_default, :'layout'  
  set :stylesheet_path, '/css'
  set :javascript_path, '/js'
  set :stylesheet_splitter, ' | '
  set :title_separator, ' - '
  set :protection, except: :session_hijacking
  
  # set Rack
  #use Rack::ShowExceptions
  #use Rack::ContentLength
  staticUrls = []
  staticUrls << settings.stylesheet_path
  staticUrls << settings.javascript_path
  staticUrls << "/favicon.gif"
  staticUrls << "/favicon.ico"
  staticUrls << "/apple-touch-icon-57x57.png"
  staticUrls << "/apple-touch-icon-72x72.png"
  staticUrls << "/apple-touch-icon-114x114.png"
  staticUrls << "/apple-touch-icon-144x144.png"
  staticUrls << "/apple-touch-icon-1024x1024.png"
  use Rack::Static, :urls => staticUrls, :root => 'public'
  
  # set utf-8 for outgoing
  before do
    headers "Content-Type" => "text/html; charset=utf-8"
    @body_id = "default-app"
    @uri = request.env["REQUEST_URI"]
    @aside = nil
    @nav = :"shared/nav"
    @page_title = "Resident Desk"
    @page_subtitle = ""
    @user = session[:auth_user] || {}
    @vb = valid_browser
  end
  
  configure :development do
    set :reload_templates, true
    # create, upgrade, or migrate tables automatically
    DataMapper::Model.raise_on_save_failure = true
  end
  
  configure do
    require 'app_settings'
  end
  
  get '/?' do
    authorize!
    if access_role?("concierge") then
      redirect '/inventory/'
    elsif access_role?("leasing") then
      redirect '/residents/'
    end
    title << "Resident Desk"
    @page_title = title.last
    @body_id = "home"
    
    @conciergeList = User.all(:is_concierge => true)
    @leasingList = User.all(:is_leasing => true)
    
    v :"home/article"
  end
  
  get '/inventory/?' do
    authorize!
    title << "Resident Desk"
    title << "Inventory"
    @page_title = title.last
    @page_subtitle = "Inventory Pickup"
    @body_id = "inventory"
    #@deliveries = Delivery.all(:fields => [:unit], :pickedup_at => nil, :unique => true, :order => [:unit.asc])
    @deliveries = DataMapper.repository.adapter.select('SELECT unit, SUM(`packages_number`) as packages_number FROM `deliveries` WHERE `resident_id` IS NULL GROUP BY `unit` ORDER BY `unit` ASC')
    @deliveries_pickedup = DataMapper.repository.adapter.select('SELECT unit, SUM(`packages_number`) as packages_number FROM `deliveries` WHERE `resident_id` IS NOT NULL AND `pickedup_at` > SUBDATE(NOW(), INTERVAL 1 MONTH) GROUP BY `unit` ORDER BY `unit` ASC')
    v :"inventory/article"
  end
  
  get '/inventory/:unit/pickedup/?' do
    authorize!
    check_unit!
    @unit = params[:unit].to_i
    title << "Resident Desk"
    title << "History"
    @page_title = title.last
    @page_subtitle = "History"
    @body_id = "inventory-pickedup"
    
    @deliveries = Delivery.all(:unit => @unit, :pickedup_at.not => nil, :order => [:created_at.desc])
    @unitNotes = UnitNotes.all(:unit => @unit, :order => [:created_at.desc])
    
    v :"inventory/pickedup"
  end
  
  get '/inventory/:unit/pickup/?' do
    authorize!
    check_unit!
    @unit = params[:unit].to_i
    title << "Resident Desk"
    title << "Pickup"
    @page_title = title.last
    @page_subtitle = "Pickup"
    @body_id = "inventory-pickup"
    
    @residents = Resident.all(:unit => @unit)
    @deliveries = Delivery.all(:unit => @unit, :pickedup_at => nil, :order => [:created_at.desc])
    
    if @deliveries.nil? || @deliveries.empty? then
      return redirect '/inventory/'
    end
    
    @unitNotes = UnitNotes.all(:unit => @unit, :order => [:created_at.desc])
    
    v :"inventory/pickup"
  end
  
  post '/inventory/:unit/pickup/?' do
    authorize!
    check_unit!
    unit = params[:unit].to_i
    delivery = params[:delivery]
    idList = delivery[:ids]
    
    msg = {}
    
    deliveryPackages = Delivery.all(:id => idList)
    resident = Resident.first(:id => delivery[:pickedup_by].to_i)
    usr = User.get(@user[:id].to_i)
    if !deliveryPackages.nil? then
      msg[:dels] = []
      deliveryPackages.each do |d|
        begin
          d.update({
            :resident => resident,
            :user => usr,
            :pickedup_at => DateTime.now,
            :pickedup_on => Time.now
          })
          msg[:dels] << d
        rescue DataMapper::SaveFailureError => e
          raise "#{e.to_s} -- validation(s): #{d.errors.values.join(', ')}"
        rescue StandardError => e
          msg[:exception] = "#{e.message}"
        end
      end
    end
    #msg.to_json
    #redirect "/inventory/#{unit}/pickedup/"
    redirect "/inventory/"
  end

  get '/checkin/?' do
    authorize!
    title << "Resident Desk"
    title << "Check In"
    @page_title = title.last
    @page_subtitle = "Check In"
    @body_id = "checkin"
    v :"checkin/article"
  end
  
  post '/checkin/?' do
    authorize!
    checkin = params[:checkin]
    msg = {}
    begin
      r_unit = checkin[:resident_unit]
      if !r_unit.nil? && !r_unit.empty? then
        residentList = Resident.all(:unit => r_unit.to_i)
      
        if !residentList.nil? && !residentList.empty? then 
          names = []
          email_addresses = []
          unit = nil
          qty = checkin[:qty].to_i
          residentList.each do |r|
            names << r.resident_name
            email_addresses << "#{r.email_address}"
            if !r.email_address2.nil? && !r.email_address2.empty? then
              email_addresses << "#{r.email_address2}"
            end
            unit = r.unit.to_i
          end
        
          pkg = Delivery.new({
            :unit => unit,
            :packages_number => qty
          })
          pkg.save
      
          email_options = {}
          email_options[:unit] = unit
          email_options[:name] = names.join(', ')
          email_options[:qty] = qty
          email_options[:created_on] = pkg.created_on
          @email_options = email_options
          email_options[:html_body] = haml :"email/html_email", :layout => false, :format => :html4
          email_options[:text_body] = haml :"email/text_email", :layout => false

          #send_emails = true
          email_addresses.each do |to|
            #if send_emails === true
              #begin
                Mailman.checkin(to, email_options).deliver
=begin
              #rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError, 
              rescue StandardError => e
                Emissary.summon().deliver
                send_emails = false
              end
=end
            #end
          end
          
          msg[:success] = "Successfully sent!"
      
        end
      else
        msg[:error] = "Please select a resident first. Thank you!"
      end
      
    rescue DataMapper::SaveFailureError => e
      raise "#{e.to_s} -- validation(s): #{pkg.errors.values.join(', ')}"
    rescue StandardError => e
      msg[:exception] = "#{e.message}"
    end
    msg.to_json
  end
  
  get '/residents/?' do
    authorize!
    title << "Resident Desk"
    title << "Resident List"
    @page_title = title.last
    @page_subtitle = "Resident List"
    @body_id = "residents"    
    v :"residents/article"
  end
  
  get '/residents/emails/?' do
    authorize!
    title << "Resident Desk"
    title << "Resident Emails"
    @page_title = title.last
    @page_subtitle = "Resident Emails"
    @body_id = "residents-emails"
    v :"residents/email"
  end

  get '/residents/former/?' do
    authorize!
    title << "Resident Desk"
    title << "Former Residents"
    @page_title = title.last
    @page_subtitle = "Former Residents"
    @body_id = "residents-formers"
    
    #@formers = Resident.with_deleted { Resident.all(:deleted_at => !nil) }
    @formers = DataMapper.repository.adapter.select("SELECT r.id, r.unit, r.resident_name, r.email_address, r.email_address2 FROM `residents` r LEFT JOIN `units` u ON r.unit = u.unit WHERE r.deleted_at IS NOT NULL")
    v :"residents/former"
  end

  get '/residents/former/:id/?' do
    authorize!
    @resident_id = params[:id].to_i
    title << "Resident Desk"
    title << "Former Resident"
    @page_title = title.last
    @page_subtitle = "Move-in"
    @body_id = "residents-former"
    
    #former = DataMapper.repository.adapter.select("SELECT r.id, r.unit, r.resident_name, r.email_address, r.email_address2 FROM `residents` r WHERE r.id = ?", @resident_id)
    #@former = former[0] 
    @former = Resident.with_deleted { Resident.first(:id => @resident_id) }
    v :"residents/former-info"
  end
  
  post '/residents/former/:id/?' do
    unit_no = params[:unit_no].to_i
    resident_id = params[:id].to_i
    msg = {}
    
    res = Resident.with_deleted { Resident.first(:id => resident_id) }
    #msg[:data] = res
    res.deleted_at
    if !res.nil? then
      begin
        res.update({:unit => unit_no, :deleted_at => nil})
      rescue DataMapper::SaveFailureError => e
        raise "#{e.to_s} -- validation(s): #{res.errors.values.join(', ')}"
      rescue StandardError => e
        msg[:exception] = "#{e.message}"
      end
      redirect "/resident-unit/#{unit_no}/"
    else
      msg[:exception] = "Couldn't find the resident specified"
      redirect "/residents/former/"
    end
    
    #msg.to_json
  end

  get '/residents/emails/:floor/?' do
    authorize!
    floor = params[:floor].to_i
    if floor != "all" && floor != "pets" then
      check_floor!
    end
    
    msg = {}
    msg[:e] = []
    msg[:c] = 0
    
    if floor == "all" then
      #residentsList = Resident.all()
      residentsList = DataMapper.repository.adapter.select("SELECT r.unit, r.resident_name, r.email_address, r.email_address2 FROM `residents` r WHERE (r.email_address IS NOT NULL OR r.email_address2 IS NOT NULL) AND r.deleted_at IS NULL")
    elsif floor == "pets" then
      residentsList = DataMapper.repository.adapter.select('SELECT r.unit, r.resident_name, r.email_address, r.email_address2, u.pets FROM `residents` r LEFT JOIN `units` u ON r.unit = u.unit WHERE (r.email_address IS NOT NULL OR r.email_address2 IS NOT NULL) AND r.deleted_at IS NULL AND u.pets > 0')
    else
      s = "#{floor}01".to_i
      e = "#{floor}18".to_i
      #residentsList = Resident.all(:unit => (s..e), , :deleted_at.not => nil)
      residentsList = DataMapper.repository.adapter.select("SELECT r.unit, r.resident_name, r.email_address, r.email_address2 FROM `residents` r LEFT JOIN `units` u ON r.unit = u.unit WHERE r.unit BETWEEN ? AND ? AND (r.email_address IS NOT NULL OR r.email_address2 IS NOT NULL) AND r.deleted_at IS NULL", s, e)
    end
    if !residentsList.nil? then
      residentsList.each do |r|
        msg[:e] << "#{r.resident_name} <#{r.email_address}>" unless r.email_address.nil?
        msg[:e] << "#{r.resident_name} <#{r.email_address2}>" unless r.email_address2.nil?
      end
      msg[:c] = residentsList.count
    end
    
    msg.to_json
  end
  
  post '/residents/lookup/' do
    authorize!
    lookup = params[:lookup]
    by = params[:by]
    msg = {}
    
    residentList = nil
    if by == "unit_no" then
      residentList = Resident.all(:unit => lookup.to_i)
    elsif by == "resident_name" then
      residentList = Resident.all(:resident_name.like => "%#{lookup}%", :order => [:unit.asc])
    end
    
    ret = {}
    residentList.each do |r|
      if !ret.has_key?(r.unit) then 
        ret[r.unit] = {}
        ret[r.unit][:leftv] = "# #{r.unit}"
        ret[r.unit][:rightv] = []
      end
      ret[r.unit][:rightv] << r.resident_name
    end
    ret[:length] = ret.count
    ret.to_json
  end
  
  get '/resident-floor/:floor/?' do
    authorize!
    check_floor!
    @floor = params[:floor].to_i
    title << "Resident Desk"
    title << "Resident List"
    @page_title = title.last
    @page_subtitle = "Resident List"
    @body_id = "resident-floor"
    
    s = "#{@floor}01".to_i
    e = "#{@floor}18".to_i
    
    residentList = Resident.all(:deleted_at => nil, :unit => (s..e))
    residentUnitOptions = Unit.all(:unit => (s..e))
    unitsWithPetsList = {}
    residentUnitOptions.each do |p|
      unitsWithPetsList[:"#{p.unit}"] = p.pets || 0
    end
    
=begin
    msg = {}
    msg[:query] = DataMapper.repository.adapter.send(:select_statement,residentList.query)
    msg[:data] = residentList
    return msg.to_json
=end    
    #Nokogiri::XML(residentList.to_xml).xpath('//resident_name/text()').map {|a| "#{a.text}"}.join(" ")
    
    @residents = {}
    residentList.each do |r|
      if !@residents.has_key?(:"#{r.unit}") then @residents[:"#{r.unit}"] = {} end
      if !@residents[:"#{r.unit}"].has_key?(:"all") then @residents[:"#{r.unit}"][:"all"] = [] end
      if !@residents[:"#{r.unit}"].has_key?(:"pets") then @residents[:"#{r.unit}"][:"pets"] = 0 end
      if unitsWithPetsList.has_key?(:"#{r.unit}") then @residents[:"#{r.unit}"][:"pets"] = unitsWithPetsList[:"#{r.unit}"] end
      @residents[:"#{r.unit}"][:"all"] << "#{r.resident_name}"
      #illi
    end
    
    # @residents.to_json
    v :"residents/floor"
  end
  
  get '/resident-unit/:unit/?' do
    authorize!
    check_unit!
    @unit = params[:unit].to_i
    @floor = get_floor(@unit)
    @back_url = "/resident-floor/#{@floor}/"
    if params.has_key?("s") && params["s"] == "1" then
      @back_url = "/residents/"
    end
    title << "Resident Desk"
    title << "Unit ##{@unit}"
    @page_title = title.last
    @page_subtitle = "#{@unit}"
    @body_id = "resident"
    @residents = Resident.all(:unit => @unit)
    @unitOptions = Unit.first(:unit => @unit)
    @unitNotes = UnitNotes.all(:unit => @unit, :order => [:created_at.desc])
    # @unitOptions.to_json
    v :"resident/article"
  end
  
  get '/resident-unit/:unit/edit/?' do    
    authorize!
    check_unit!
    @unit = params[:unit].to_i
    @floor = get_floor(@unit)
    title << "Resident Desk"
    title << "Unit ##{@unit}"
    @page_title = title.last
    @page_subtitle = "#{@unit}"
    @body_id = "resident-edit"
    @residents = Resident.all(:unit => @unit)
    if @residents.nil? || @residents.empty? then 
      @residents = []
      @residents << Resident.new({:unit => @unit})
    end
    @unitOptions = Unit.first(:unit => @unit)
    @residentFields = get_resident_fields
    #@residents.to_json
    v :"resident/edit"
  end
  
  def get_resident_fields
    return {
      :resident_name => {:label => "Name"},
      :phone_number => {:label => "Phone Number", :type => "tel"},
      :phone_number2 => {:label => "Alt Phone Number", :type => "tel"},
      :email_address => {:label => "Email Address"},
      :email_address2 => {:label => "Alt Email Address"},
      :license_plate => {:label => "License Plate"}
    }
  end
  
  post '/resident-unit/:unit/edit/?' do 
    authorize!
    check_unit!
    #residentFields = get_resident_fields
    msg = {}
    unit = params[:unit].to_i
    residentList = params[:resident]
    unitOptions = params[:options]
    unitOptions[:pets] = !unitOptions[:pets].nil? ? unitOptions[:pets].to_i : 0
    msg[:res] = []
    residentList.each_with_index do |r, i|
      if r[1][:name] != "" || r[1][:phone_number] != "" || r[1][:email_address] != "" then 
        resDB = nil
        if !r[1][:id].nil? then
          resDB = Resident.first(:id => r[1][:id].to_i)
        end
        resData = {
          :resident_name => !r[1][:resident_name].nil? && r[1][:resident_name] != "" ? r[1][:resident_name] : nil,
          :phone_number => !r[1][:phone_number].nil? && r[1][:phone_number] != "" ? formatted_number(r[1][:phone_number]) : nil,
          :phone_number2 => !r[1][:phone_number2].nil? && r[1][:phone_number2] != "" ? formatted_number(r[1][:phone_number2]) : nil,
          :email_address => !r[1][:email_address].nil? && r[1][:email_address] != "" ? r[1][:email_address] : nil,
          :email_address2 => !r[1][:email_address2].nil? && r[1][:email_address2] != "" ? r[1][:email_address2] : nil,
          :license_plate => !r[1][:license_plate].nil? && r[1][:license_plate] != "" ? r[1][:license_plate] : nil,
          :unit => unit
        }   
        begin
          if resDB.nil? then 
            res = Resident.new(resData)
            res.save
            msg[:res] << res
            res = nil
          else
            res = resDB
            res.update(resData)
            msg[:res] << res
          end
          resDB = nil
        rescue DataMapper::SaveFailureError => e
          raise "#{e.to_s} -- validation(s): #{res.errors.values.join(', ')}"
        rescue StandardError => e
          msg[:exception] = "#{e.message}"
        end
      end
    end
    msg[:uni] = nil
    unitDB = Unit.first(:unit => unit)
    unitData = {
      :sublease => !unitOptions[:sublease].nil? && unitOptions[:sublease] != "" ? unitOptions[:sublease] : nil,
      :pets => !unitOptions[:pets].nil? && unitOptions[:pets] != "" ? unitOptions[:pets] : 0
    }
    begin      
      if unitDB.nil? then 
        unitData[:unit] = unit
        uni = Unit.new(unitData)
        uni.save
        msg[:uni] = uni
        uni = nil
      else
        uni = unitDB
        uni.update(unitData)
        msg[:uni] = uni
      end
      unitDB = nil
    rescue DataMapper::SaveFailureError => e
      raise "#{e.to_s} -- validation(s): #{uni.errors.values.join(', ')}"
    rescue StandardError => e
      msg[:exception] = "#{e.message}"
    end
    msg[:success] = "Successfully processed residents"
    
    #msg.to_json
    redirect "/resident-unit/#{unit}/"
  end
  
  post '/resident-unit/:unit/delete/:id/?' do
    authorize!
    check_unit!
    msg = {}
    unit = params[:unit].to_i
    id = params[:id].to_i
    href = "/resident-unit/#{unit}/"

    begin   
      if id != "all" then
        del = Resident.get(id)
        del.destroy
        delDelivery = Delivery.all(:resident_id => id)
        delDelivery.destroy
        delChk = Resident.all(:unit => unit)
        if delChk.nil? || delChk.empty? then
          delUnit = Unit.all(:unit => unit)
          delUnit.destroy
          delNotes = UnitNotes.all(:unit => unit)
          delNotes.destroy
          
          floor = get_floor(unit)
          href = "/resident-floor/#{floor}/"
        end 
        msg[:success] = "Successfully deleted"
      else # clear all the data
        del = Resident.all(:unit => unit)        
        del.destroy
        delUnit = Unit.all(:unit => unit)
        delUnit.destroy
        delNotes = UnitNotes.all(:unit => unit)
        delNotes.destroy
        delDelivery = Delivery.all(:unit => unit)
        delDelivery.destroy
        
        floor = get_floor(unit)
        href = "/resident-floor/#{floor}/"
        msg[:success] = "Successfully deleted all"
      end
    rescue DataMapper::SaveFailureError => e
      raise "#{e.to_s} -- validation(s): #{del.errors.values.join(', ')}"
    rescue ArgumentError => e
      msg[:error] = "#{e.message}"
    rescue StandardError => e
      msg[:exception] = "#{e.message}"
    end  
    msg[:href] = href
    msg.to_json
  end 
  
  post '/resident-unit/:unit/add-note/' do
    authorize!
    check_unit!
    unit = params[:unit].to_i
    new_note = params[:new_note]
    msg = {}
    begin      
      if !new_note.nil? && new_note != "" then
        usr = User.get(@user[:id].to_i)
        note = UnitNotes.new({
          :unit => unit,
          :note => new_note,
          :user => usr,
        })
        note.save
        msg[:u] = unit
        msg[:d] = note.id 
        msg[:p] = {}
        msg[:p][:f] = usr.first_name
        msg[:p][:l] = usr.last_name[0..0]
        msg[:c] = note.created_at.strftime("%b %-d, %Y")
        msg[:success] = "Successfully added a new note!"
        note = nil
      else
        msg[:error] = "Please make sure the note is not empty."
      end
    rescue DataMapper::SaveFailureError => e
      raise "#{e.to_s} -- validation(s): #{note.errors.values.join(', ')}"
    rescue StandardError => e
      msg[:exception] = "#{e.message}"
    end
    msg.to_json
  end
  
  post '/resident-unit/:unit/delete-note/:delete_id/' do
    authorize!
    check_unit!
    unit = params[:unit].to_i
    delete_id = params[:delete_id].to_i
    msg = {}
    note = UnitNotes.first(:id => delete_id, :unit => unit)
    if !note.nil? then
      note.destroy
      msg[:success] = "Successfully delete note: #{delete_id}!"
    else
      msg[:error] = "Note not found"
    end
    msg.to_json
  end
  
  post '/search/?' do
    authorize!
    s = params[:search]
    if s.to_i.to_s.length == 10 || s =~ /^\d{3}-\d{3}-\d{4}$/ then
      s = formatted_number(s)
      results = Resident.all(:phone_number.like => "%#{s}%") | Resident.all(:phone_number2.like => "%#{s}%")
    else
      results = Resident.all(:resident_name.like => "%#{s}%") | Resident.all(:email_address.like => "%#{s}%") | Resident.all(:email_address2.like => "%#{s}%") | Resident.all(:license_plate.like => "%#{s}%") | Resident.all(:unit => s.to_i) | Resident.all(:phone_number.like => "%#{s}%") | Resident.all(:phone_number2.like => "%#{s}%")
    end
    ret = {}
    results.each do |r|
      if !ret.has_key?(r.unit) then 
        ret[r.unit] = {}
        ret[r.unit][:leftv] = "# #{r.unit}"
        ret[r.unit][:rightv] = []
      end
      ret[r.unit][:rightv] << r.resident_name
    end
    ret[:length] = ret.count
    ret.to_json
  end
  
  get '/login/?' do
    if authorized? then
      redirect '/'
    end
    title << "Resident Desk"
    @page_title = "Login"
    @body_id = "login"
    v :"login/article"
  end
  
  post '/login/?' do
    msg = {}
    msg[:error] = {}
    login = params[:login]
    
    if login[:username] == "" then 
      msg[:error][:username] = "Please enter in your username!"
    end
    if msg[:error].length > 0 then
      return msg.to_json
    end
    
    if login[:password] == "" then
      msg[:error][:password] = "Please enter the correct password!"
    end
    if msg[:error].length > 0 then 
      return msg.to_json 
    end
    
    # if we made it thus far, then proceed with the auth
    begin
      if !authenticate(User, login[:username], login[:password]) then
        msg[:error][:auth] = "Incorrect username or password, please try again!"
      end
      if msg[:error].length > 0 then 
        return msg.to_json 
      else
        msg = {}
        msg[:success] = "Successfully authenticated!"
      end
    rescue StandardError => e
      msg[:error] = {}
      msg[:error][:standard] = "#{e.to_s}"
    end
    
    msg.to_json
  end
  
  get '/logout/?' do
    logout!
    redirect '/login/'
  end
  
  def login_url_redirect
    if @vb.nil? then
      return '/upgrade/'
    end
    return '/login/'
  end
  
  def timeout_seconds 
    return (2*60*60).to_i
  end
  
  def set_user_data(u)
    session[:auth_user][:id] = u.id
    session[:auth_user][:login] = u.login
    session[:auth_user][:first_name] = u.first_name
    session[:auth_user][:last_name] = u.last_name
    session[:auth_user][:"is_su"] = u.is_su
    session[:auth_user][:"is_admin"] = u.is_admin
    session[:auth_user][:"is_leasing"] = u.is_leasing
    session[:auth_user][:"is_concierge"] = u.is_concierge
  end

  def access_role?(role)
    key = :"is_#{role}"
    if session[:auth_user].has_key?(key) && session[:auth_user][key] == true then
      return true
    end
    return false
  end
  
  def get_floor(unit)
    return unit.to_s.rjust(4,"0")[0,2].to_i
  end
  
  def get_unit_no(unit)
    return unit.to_s.rjust(4,"0")[2,2].to_i
  end
  
  def valid_floor?(floor)
    if !floor.to_i.between?(2,27) then
      return false
    end
    return true
  end
  
  def valid_unit?(unit)
    floor = get_floor(unit)
    if !valid_floor?(floor) then
      return false
    end
    unit_no = get_unit_no(unit)
    if !unit_no.to_i.between?(1,18) then
      return false
    end
    if floor == 2 && ( unit_no == 5 || unit_no == 7 || unit_no == 9 || unit_no == 11 || unit_no == 13 || unit_no == 15 ) then
      return false
    end
    return true
  end
  
  def check_floor! 
    if !params.has_key?("floor") || params[:floor].nil? || params[:floor].empty? || !valid_floor?(params[:floor].to_i) then
      halt 404
    end
  end
  
  def check_unit!
    if !params.has_key?("unit") || params[:unit].nil? || params[:unit].empty? || !valid_unit?(params[:unit].to_i) then
      halt 404
    end
  end
  
  get '/user/add/?' do
    authorize!
    title << "Resident Desk"
    title << "Add User"
    @page_title = title.last
    @page_subtitle = @page_title
    @body_id = "user-add"
    @user_fields = get_user_fields
    v :"user/add"
  end
  
  def get_user_fields
    return [
      {:key => "login", :label => "User", :required => true},
      {:key => "password", :label => "Password"},
      {:key => "first_name", :label => "First Name", :required => true},
      {:key => "last_name", :label => "Last Name", :required => true},
      {:key => "email_address", :label => "Email Address", :required => true},
      {:key => "phone_number", :label => "Phone Number", :required => true},
      {:key => "phone_number2", :label => "Alt Phone Number"},
      {:key => "is_admin", :label => "Admin?", :type => "checkbox", :access_role => "admin"},
      {:key => "is_concierge", :label => "Concierge?", :type => "checkbox", :access_role => "admin"},
      {:key => "is_leasing", :label => "Leasing Office?", :type => "checkbox", :access_role => "admin"},
    ]
  end
  
  post '/user/add/' do
    authorize!
    msg = {}
    user_params = params[:user]
    user_fields = get_user_fields
    
    user_data = {}
    user_fields.each do |f|
      key = f[:key]
      if key == "password" && !user_params[key].nil? && !user_params[key].empty? then
        user_data[key] = user_params[key]
      elsif key != "password" && !user_params[key].nil? then
        user_data[key] = user_params[key]
      end
      if key == "phone_number" || key == "phone_number2" then
        user_data[key] = formatted_number(user_data[key])
      end
    end
    
    begin
      user = User.new(user_data)
      # on save try logging in
      if user.save then
        msg[:created] = "Created user!"
      else
        msg[:error] = "Error creating user"
      end
    rescue DataMapper::SaveFailureError => e
      raise "#{e.to_s} -- validation(s): #{user.errors.values.join(', ')}"
    rescue StandardError => e
      msg[:exception] = "#{e.message}"
    end
    redirect '/'
  end
  
  get '/user/:id/?' do
    authorize!
    @user_data = User.get(params[:id].to_i)
    if @user_data.nil? then
      halt 404
    end
    
    if @user[:id].to_i != @user_data.id.to_i && !access_role?("admin") then
      halt 401
    end
    
    title << "Resident Desk"
    title << "View User"
    @page_title = title.last
    @page_subtitle = @page_title
    @body_id = "user-view"
    v :"user/article"
  end
  
  get '/user/:id/edit/?' do
    authorize!
    @user_data = User.get(params[:id].to_i)
    if @user_data.nil? then
      halt 404
    end

    if @user[:id].to_i != @user_data.id.to_i && !access_role?("admin") then
      halt 401
    end
    
    title << "Resident Desk"
    title << "Edit User"
    @page_title = title.last
    @page_subtitle = @page_title
    @body_id = "user-edit"
    @user_fields = get_user_fields
    v :"user/edit"
  end
  
  post '/user/:id/edit/' do
    authorize!
    msg = {}
    user_params = params[:user]
    user_fields = get_user_fields
    
    user_data = {}
    user_fields.each do |f|
      key = f[:key]
      if key == "password" && !user_params[key].nil? && !user_params[key].empty? then
        user_data[key] = user_params[key]
      elsif key != "password" && !user_params[key].nil? then
        user_data[key] = user_params[key]
      end
      if key == "phone_number" || key == "phone_number2" then
        user_data[key] = formatted_number(user_data[key])
      end
    end
    
    begin
      user = User.get(user_params[:id].to_i)
      user.update(user_data);
      # on save try logging in
      if user.save then
        msg[:created] = "Updated user!"
      else
        msg[:error] = "Error updating user"
      end
    rescue DataMapper::SaveFailureError => e
      raise "#{e.to_s} -- validation(s): #{user.errors.values.join(', ')}"
    rescue StandardError => e
      msg[:exception] = "#{e.message}"
    end
    redirect '/'
  end
  
  post '/user/:id/delete/' do    
    authorize!
    @user_data = User.get(params[:id].to_i)
    if @user_data.nil? then
      halt 404
    end

    if !access_role?("admin") then
      halt 401
    end
    
    msg = {}
    begin           
      @user_data.destroy
      msg[:success] = "Successfully deleted the user"
    rescue DataMapper::SaveFailureError => e
      raise "#{e.to_s} -- validation(s): #{@user_data.errors.values.join(', ')}"
    rescue StandardError => e
      msg[:exception] = "#{e.message}"
    end
    
    msg.to_json
  end

=begin   
  get '/admin/clear-data/' do
    Resident.auto_migrate! #unless Resident.storage_exists?
    Delivery.auto_migrate! #unless Delivery.storage_exists?
    Unit.auto_migrate! #unless Unit.storage_exists?
    UnitNotes.auto_migrate! #unless UnitNotes.storage_exists?
    redirect '/inventory/'
  end
=end

  not_found do
    title << "404 Not Found"
    @page_title = title.last
    v :"errors/404", :layout => :'layout'
  end

  error 401 do
    title << "401 Unauthorized"
    @page_title = title.last
    v :"errors/401", :layout => :'layout'
  end

  error 500..510 do
    title << "50X Error"
    @page_title = title.last
    v :"errors/50X", :layout => :'layout'
  end

  get '/upgrade/?' do
    
    @body_id = "upgrade"
    title << "Upgrade Browser"
    @page_title = title.last
    
    v :"errors/upgrade", :layout => false
  end
  
  # Private methods
  
  def formatted_number(number)
    digits = number.gsub(/\D/, '').split(//)

    if (digits.length == 11 and digits[0] == '1')
      digits.shift # Strip leading 1
    end

    if (digits.length == 10)
      '%s-%s-%s' % [ digits[0,3].join(""), digits[3,3].join(""), digits[6,4].join("") ]
    end
  end

  def v(template, options={}) 
    begin
      if !options.has_key?(:layout) then
        options = options.merge(:layout => settings.layout_default)
      end
      if request.xhr? then 
        options[:layout] = false
      end
      haml(template, options) 
    rescue StandardError => e
      "#{e.message}"
    end
  end
  
  def valid_browser
    b = Struct.new(:browser, :version)
    sb = [
      b.new("Chrome", "18.0"),
      b.new("Opera", "10.0"),
      b.new("Safari", "5.0"),
      b.new("Firefox", "13.0"),
      b.new("Internet Explorer", "10.0")
    ]
    user_agent = UserAgent.parse(request.user_agent)
    sb.detect { |br| br[:browser].match(user_agent.browser) && user_agent.version.to_s.to_f >= br[:version].to_f }
  end
  
  class Mailman < ActionMailer::Base
    def checkin(to, options)
      
      qty = options[:qty]
      html_body = options[:html_body]
      text_body = options[:text_body]

      mail(
        :to => ActionMailer::Base.default[:to_override] || "#{to}",
        :bcc => ActionMailer::Base.default[:app_email],
        :subject => "You received #{qty} #{qty > 1 ? "packages" : "package"}"
      ) do |format|    
        format.text { text_body.to_s }
        format.html { html_body }
      end

    end
  end
  
=begin
  class Emissary < EmissaryBase
    def summon()
  
      mail(
        :to => ActionMailer::Base.default[:app_email],
        :cc => ActionMailer::Base.default[:client_it_notify],
        :subject => "Email sending error"
      ) do |format|    
        format.text { "An error occurred while attempting to send email. \n The email server may be down. \n\n Thank you, \n Emissary Bot" }
        format.html { "An error occurred while attempting to send email. <br />\n The email server may be down. <br />\n<br />\n Thank you, <br />\n Emissary Bot" }
      end
      
    end
  end
=end
end
