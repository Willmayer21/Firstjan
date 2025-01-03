set :environment, ENV['RAILS_ENV']
set :output, 'log/cron.log'

every 30.minutes do
  runner "CleanupDownloadsJob.perform_now"
end
