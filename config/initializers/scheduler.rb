require 'rufus-scheduler'

# Don't schedule when running tests or console commands
return if defined?(Rails::Console) || Rails.env.test? || File.split($0).last == 'rake'

scheduler = Rufus::Scheduler.singleton

# Schedule cleanup every 30 minutes
scheduler.every '30m' do
  Rails.logger.info "Scheduling cleanup job"
  CleanupDownloadsJob.perform_later
end
