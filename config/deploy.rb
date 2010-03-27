# Capistrano deploy specification.
# Integrated with poolparty by getting node addresses from poolparty, and use them to set cap roles.

# CAPISTRANO APPLICATION DEPLOYMENT 

# run: cap deploy:setup
# run: cap deploy


# -------------------------------------------------------------------
# SET DEPLOYMENT ENVIRONMENT - ASK THE DEVELOPER
# -------------------------------------------------------------------

# Whatever you set here will be taken and set as the default RAILS_ENV value


# colorize capistrano output
require 'capistrano_colors'

capistrano_color_matchers = [
  { :match => /command finished/,       :color => :hide,      :prio => 10 },
  { :match => /executing command/,      :color => :blue,      :prio => 10, :attribute => :underscore },
  { :match => /^transaction: commit$/,  :color => :magenta,   :prio => 10, :attribute => :blink },
  { :match => /svn/,                    :color => :white,     :prio => 20, :attribute => :reverse },
]

colorize( capistrano_color_matchers )


set :rails_env, "production" 

# -------------------------------------------------------------------
# GENERAL SETTINGS
# -------------------------------------------------------------------

set :application, "medistrano.vpc.com"

set :use_sudo, true

set :user, "ubuntu"

set :port, 22

default_run_options[:pty] = true

ssh_options[:paranoid] = false 
ssh_options[:keys] =  "~/.ec2/MACHINE-cruise"
ssh_options[:forward_agent] = true
#ssh_options[:user] =  "ubuntu"

# -------------------------------------------------------------------
# SUBVERSIONING
# -------------------------------------------------------------------

set :scm, "git"
set :repository, "git@github.com:mdsolgithubadmin/cruisecontrol.rb.git"
set :branch, "master"
set :git_enable_submodules, 1
#set :deploy_via, :remote_cache

# -------------------------------------------------------------------
# ROLES
# -------------------------------------------------------------------

role :web,      "10.225.50.7"
role :app,      "10.225.50.7"
role :db,       "10.225.50.7", :primary => true


# -------------------------------------------------------------------
# DEPLOY
# -------------------------------------------------------------------

deploy_dir = "/mnt/cruisecontrol"

set :deploy_to, deploy_dir

set :keep_releases, 10


# -------------------------------------------------------------------
# Passenger
# -------------------------------------------------------------------


deploy.task :restart, :roles => :app do
  run "#{latest_release}/cruise stop"
  run "#{latest_release}/cruise start -d"
  #run "sudo chown -R ubuntu:ubuntu #{latest_release}/tmp"
  nginx.restart
end







# -------------------------------------------------------------------
# nginx
# -------------------------------------------------------------------

after "deploy:setup", "nginx:setup"

namespace :nginx do

  task :start do
    run "sudo /etc/init.d/nginx start"
  end

  task :stop do
    run "sudo /etc/init.d/nginx stop"
  end

  task :restart do
    run "sudo /etc/init.d/nginx restart"
  end
  
  task :setup do
    nginx.stop
    run "sudo chown -R ubuntu:ubuntu /mnt/cruisecontrol"
    run "sudo rm -f /opt/nginx/conf/sites-enabled/cruisecontrol.conf"
    run "sudo rm -f /opt/nginx/conf/sites-available/cruisecontrol.conf"
    template_path     = File.expand_path(File.join(__FILE__,"..", "nginx.conf.erb"))
    compiled_template = ERB.new(File.read(template_path)).result(binding)
    sudo_put(compiled_template, "/opt/nginx/conf/sites-available/cruisecontrol.conf")
    run "sudo ln -s /opt/nginx/conf/sites-available/cruisecontrol.conf /opt/nginx/conf/sites-enabled/cruisecontrol.conf"  
    nginx.start
    nginx.restart
  end
  
end

# -------------------------------------------------------------------
# SETTTINGS
# -------------------------------------------------------------------

#after "deploy:update_code", "deploy:symlink_config"
#after "deploy:update_code", "deploy:symlink_db" 
#
#namespace :deploy do
#  desc "Symlink to the right database yaml"
#  task :symlink_db, :roles => :app do
#    run "ln -nfs #{release_path}/config/database.yml.production #{release_path}/config/database.yml"
#  end
#  desc "Symlink to the production webistrano configuration file" 
#  task :symlink_config, :roles => :app do
#    run "sudo mv #{release_path}/config/webistrano_config_production.rb #{release_path}/config/webistrano_config.rb" 
#  end
#end


# -------------------------------------------------------------------
# HELPERS
# -------------------------------------------------------------------

def sudo_put(data, target)
  tmp = "#{shared_path}/~tmp-#{rand(9999999)}"
  put data, tmp
  on_rollback { run "rm #{tmp}" }
  sudo "cp -f #{tmp} #{target} && rm #{tmp}"
end


# config/deploy.rb
after "deploy:update_code", "gems:install"
 
namespace :gems do
  desc "Install gems"
  task :install, :roles => :app do
    run "cd #{current_release} && #{sudo} rake gems:install RAILS_ENV=#{rails_env} "
  end
end


