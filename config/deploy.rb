require 'action_mailer'
set :application, "resident-desk"
set :current_path, "clt-resdesk.previewfor.net"
set :prod_path, "residentdesk.com"
set :prod_app, "#{prod_path}"
set :prod_static_path, "shindy@shindyapin.com:/home/shindy/static.residentdesk.com"
 
default_run_options[:pty] = true
 
set :scm, :git
 
role :web, "ps77562.dreamhostps.com"       # Your HTTP server, Apache/etc
role :app, "ps77562.dreamhostps.com"       # This may be the same as your `Web` server
 
namespace :deploy do
  
  set(:user) do
    Capistrano::CLI.ui.ask("Enter user: ")
  end
  
  set(:commit_msg) do
    Capistrano::CLI.ui.ask("Enter commit message, or default => ") {|q| 
      q.default = "General Updates on #{DateTime.now.strftime("%m/%d/%Y %H:%I:%S")}"
    }
  end
 
  set(:last_commit_msg) do
    run_locally "git log -n1 --pretty=oneline --abbrev-commit"
  end
  
  set(:run_static_updates) do
    Capistrano::CLI.ui.ask("Run updates to the static site? [Y/n] or default => ") {|q| 
      q.default = "n"
    }
  end
  
  task :setup_notifier do
    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.smtp_settings = {
      :address => "smtp.gmail.com",
      :port => "587",
      :domain => "gmail.com",
      :enable_starttls_auto => true,
      :authentication => :login,
      :user_name => "info@eonmediagroup.com",
      :password => "infoEONmedia"
    }
    ActionMailer::Base.raise_delivery_errors = false
    
    class Deployer < ActionMailer::Base
      def notify_testing_team(settings)
 
        html_body = "<div>The latest changes were deployed to http://#{settings[:app]}!</div><div style=\"background:#eeeeee;border:1px solid #004a5f;margin:25px 15px;\"><span style=\"background: #004a5f; color: #fff; font-weight: bold; display: block; width: 72px; text-align: center; padding: 5px; margin-top: -10px; margin-left: -10px;\">#{if "prod".match(settings[:type]) then "Production" else "Staging" end}</span><div style=\"padding:25px;\">#{settings[:message]}</div></div><div>Thank you,<br />The Deploy Bot</div>"
        text_body = "The latest changes were deployed to http://#{settings[:app]}!\n\n#{settings[:message]}\n\nThank you,\nThe Deploy Bot"
 
        mail(
          :to => "EMG QA Testing <testing@eonmediagroup.com>",
          :from => "info@eonmediagroup.com",
          :subject => "Deployment to http://#{settings[:app]}"
        ) do |format|    
          format.text { text_body.to_s }
          format.html { html_body }
        end
 
      end
    end
  end
  
  desc "Deploy to production"
  task :production do
    puts "Deploying to production"
    transaction do
      setup_notifier
      update_prod_code
      #gem_bundle
      restart_prod
      sync_static_site
      notify_prod_team
    end
  end
  
  desc "Continue deploy if error occurred"
  task :staging do
    setup_notifier
    push_code
    update_code
    restart
    notify_team
  end
  
  desc "Running update"
  task :update do
    transaction do
      setup_notifier
      commit_code
      push_code
      update_code
      #gem_bundle
      restart
      notify_team
    end
  end
  
  desc "Running static site sync"
  task :sync_static_site do
    transaction do
      puts "  * Check for static site sync:"
      if run_static_updates == "Y" then
        puts ""
        puts "  * Updating the static site:"
        run "rsync -av #{prod_path}/public/* #{prod_static_path}/public/"
        puts "    ... done!"
      else
        puts "    ... skipping!"
      end
    end
  end
  
  task :notify do 
    setup_notifier
    notify_team
  end
  
  task :commit_code, :except => { :no_release => true } do
    run_locally "git status"
    run_locally "git add ."
    run_locally "git commit -m '#{commit_msg}'"
  end
  
  task :push_code, :except => { :no_release => true } do
    run_locally "git push origin master"
  end
  task :update_code, :except => { :no_release => true } do
    run "cd #{current_path} && git reset --hard && git pull"
    run "cd #{current_path} && rm Gemfile*"
  end
 
  task :gem_bundle, :except => { :no_release => true } do
    run "cd #{current_path} && bundle"
  end
 
  task :update_prod_code, :except => { :no_release => true } do
    run "cd #{prod_path} && git reset --hard && git pull"
  end
  
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end
  
  desc "Restarting mod_rails with restart.txt"
  task :restart_prod, :roles => :app, :except => { :no_release => true } do
    run "touch #{prod_path}/tmp/restart.txt"
  end
  
  desc "Notify the team that the latest changes were deployed to staging"
  task :notify_team do    
    Deployer.notify_testing_team({:app => current_path, :message => last_commit_msg, :type => "staging"}).deliver
  end
 
  desc "Notify the team that the latest changes were deployed to prod"
  task :notify_prod_team do    
    Deployer.notify_testing_team({:app => prod_app, :message => "Deployment from staging to Production environment.", :type => "prod"}).deliver
  end

  [:start, :stop, :check, :setup].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end
end
 
namespace :db do
  desc "Upgrade the database columns"
  task :upgrade do
    puts "  * Running the upgrade tasks:"
    $:.unshift File.expand_path("../../lib", __FILE__)
    $:.unshift File.expand_path("../../app", __FILE__)
    $:.unshift File.expand_path("../../config", __FILE__)
    puts "    - done with library setup, continue with require's"
    puts "    - requiring sintra/base"
    require 'sinatra/base'
    puts "    - requiring sintra/sessionauth"
    require 'sinatra/sessionauth'
    puts "    - requiring data_mapper"
    require 'data_mapper'
    puts "    - requiring app_settings"
    require 'app_settings'
    puts "    ... done with setup!"
    puts ""
    puts "  * Upgrading the database:"
    DataMapper.auto_upgrade!
    DataMapper.finalize
    puts "    ... done upgrading!"
    puts ""
  end
  
  desc "Initial setup of the database"
  task :setup do
    upgrade
    puts "  * Running the setup tasks:"
    puts "  * Checking for super users..."
    admins = User.first(:is_su => true)
    if admins.nil? then
      begin
        user = User.new({
          :login => "admin",
          :password => "12345",
          :first_name => "Admin",
          :last_name => "ResidentDesk",
          :is_admin => true,
          :is_su => true,
        })
        # on save try logging in
        if user.save then
          puts "    ... done creating super user!"
        else
          puts "    ... Error creating super user: #{e.to_s} -- validation(s): #{user.errors.values.join(', ')}"
        end
      rescue StandardError => e
        puts "    ... exception: #{e.message}"
      end
    else 
      puts "    ... superuser exists: '#{admins.login}'!"
     end
    puts ""
   end
end
 
namespace :gems do
  set(:unpack_gems) do
    Capistrano::CLI.ui.ask("What gems? ")
  end
  
  desc "Move the gems to the library file"
  task :libify do 
    unpack
    move
    cleanup
  end
  
  task :unpack do
    puts "  * checking for vendor directory"
    run_locally "if [[ ! -d ./vendor ]]; then mkdir ./vendor; fi"
    for g in unpack_gems.strip.split(" ") do
      run_locally "gem unpack --target=./vendor/ #{g}"
     end
   end
  
  task :move do
    run_locally "for D in `find ./vendor/* -type d -depth 0`; do LIB=\"./$D/lib\"; if [[ -d $LIB ]]; then cp -R $LIB/* ./lib/; fi; done"
  end
  
  task :cleanup do
    run_locally "rm -rf ./vendor"
  end
end
