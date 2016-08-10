# capistranoのバージョン固定
lock '3.4.0'

# デプロイするアプリケーション名を記載する
set :application, 'achieve'

# cloneするgitのレポジトリを指定、環境変数化する
set :repo_url, ENV['REPO_URL']

# deployするブランチ、記載しないとデフォルトはmaster
set :branch, 'master'

# deploy先のディレクトリ構造に合わせて記載する
set :deploy_to, '/var/www/achieve'

# シンボリックリンクを貼るファイル一式をハッシュ形式で記載する
set :linked_files, %w{ config/database.yml config/secrets.yml .env }

# シンボリックリンクをはるフォルダを記載する
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# 保持する世代数の個数
set :keep_releases, 5

# rubyのバージョンの指定
set :rbenv_ruby, '2.3.0'

#出力するログのレベル
set :log_level, :debug

# cap deployで実行される一連の処理
namespace :deploy do
  
  # Unicorn再起動を実行するタスク
  desc 'Restart application'
  task :restart do
    invoke 'unicorn:restart'
  end
  
  # rake db:createを実行するタスク
  desc 'Create database'
  task :db_create do
    on roles(:db) do |host|
      with rails_env: fetch(:rails_env) do
        within current_path do
          execute :bundle, :exec, :rake, 'db:create'
        end
      end
    end
  end
  
  # rake db:seedを実行するタスク
  desc 'Run seed'
  task :seed do
    on roles(:app) do
      with rails_env: fetch(:rails_env) do
        within current_path do
          execute :bundle, :exec, :rake, 'db:seed'
        end
      end
    end
  end
  
  after :publishing, :restart
  
  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
    end
  end

  # .env以外のgitignoreファイルをアップロードするタスク
  desc 'Upload config files'
    task :config_upload do
      on roles(:app) do |host|
        if test "[ ! -d #{shared_path}/config ]"
          execute "mkdir -p #{shared_path}/config"
        end
        upload!('config/database.yml', "#{shared_path}/config/database.yml")
        upload!('config/secrets.yml', "#{shared_path}/config/secrets.yml")      
    end
  end
  before :started, 'deploy:config_upload'
end

# .envファイルのみをアップロードするタスク、Deploy前に一度実行する
desc 'upload importabt files'
  task :env_upload do
    on roles(:app) do |host|
      if test "[ ! -d #{shared_path}/config ]"
        execute "mkdir -p #{shared_path}/config"
      end
      upload!('.env', "#{shared_path}/.env")
  end
end
