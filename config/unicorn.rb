# Railsのルートパスを求める。(RAILS_ROOT/config/unicorn.rbに配置している場合。)
rails_root = File.expand_path('../../', __FILE__)

# Capistranoでunicornを使ったアプリをデプロイしているとBundler::GemfileNotFoundという例外があがることがあるため設定
ENV['BUNDLE_GEMFILE'] = rails_root + "/Gemfile"

#ワーカー数を定義、サーバーのメモリなどによって変更する
worker_processes 2

# Unicornの起動コマンドの実行を許可するディレクトリを指定
working_directory rails_root

# 接続タイムアウト時間
timeout 30

# Unicornのエラーログと通常ログの位置を指定
stderr_path File.expand_path('../../log/unicorn_stderr.log', __FILE__)
stdout_path File.expand_path('../../log/unicorn_stdout.log', __FILE__)

# nginxで使用する場合に指定
 listen File.expand_path('../../tmp/sockets/unicorn.sock', __FILE__)

# プロセスの停止などに必要なPIDファイルの保存先を指定
pid File.expand_path('../../tmp/pids/unicorn.pid', __FILE__)

# Unicornの再起動時にダウンタイムなしで再起動を行う
preload_app true

# USR2シグナルを受けると古いプロセスを止める。
before_fork do |server, worker|
  defined?(ActiveRecord::Base) and
      ActiveRecord::Base.connection.disconnect!
  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end
after_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end
