set :user, "rbrtmlnr"

# about the application
set :application, "rbrtmlnr.com"
set :port, 2222

# the type and location of the repository
set :scm, :git
set :repository, "."
# set :repository, "git@github.com:rbrtmlnr/rbrtmlnr.git"
# set :branch, "master"

# how and where it should be uploaded
set :deploy_to, "/home/#{user}/sites/#{application}"
set :deploy_via, :copy

# what should be left behind in the copy
set :copy_exclude, %w[.git .DS_Store .gitignore .gitmodules .sass-cache sass Capfile config config.rb]

# which server to use
server application, :app

# shared hosting != sudo privileges
set :use_sudo, false

# only keep the last four releases on the server
set :keep_releases, 4

namespace :deploy do
  desc "Add symlink to `public_html`"
  task :public_html_symlink, :rols => :app do
    on_rollback do
      if previous_release
        run "rm -f ~/public_html; ln -s #{previous_release} ~/public_html; true"
      else
        logger.important "no previous release to rollback to, rollback of symlink skipped for ~/public_html"
      end
    end

    run "rm -f ~/public_html && ln -s #{release_path} ~/public_html"
  end

  desc "Remove group write privileges"
  task :finalize_update do
    transaction do
      run "chmod -R g-w #{release_path}"

       # copy all items from the shared folder
      shared_children.map do |d|
        if d.rindex('/')
          run "rm -rf #{latest_release}/#{d} && mkdir -p #{latest_release}/#{d.slice(0..(d.rindex('/')))}"
        else
          run "rm -rf #{latest_release}/#{d}"
        end

        run "ln -s #{shared_path}/#{d.split('/').last} #{latest_release}/#{d}"
      end
    end
  end

  # disable rails stuff
  task :migrate do; end
  task :restart do; end
end

# removes older releases
after "deploy:update", "deploy:cleanup"

after "deploy:create_symlink", "deploy:public_html_symlink"
