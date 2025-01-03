class CleanupOldFilesJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Running scheduled cleanup job"
    controller = PlaylistsController.new
    controller.send(:cleanup_old_files, 30.minutes.ago)
  end
end
