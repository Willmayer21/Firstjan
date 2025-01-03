class CleanupDownloadsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting scheduled cleanup (30-minute interval)"
    download_root = Rails.root.join('public', 'downloads')
    threshold = 30.minutes.ago

    # List current files before cleanup
    Rails.logger.info "Current files in downloads directory:"
    Dir.glob("#{download_root}/*").each do |entry|
      Rails.logger.info "Found: #{entry} (#{File.mtime(entry)})"
    end

    # Clean files older than 30 minutes
    Dir.glob("#{download_root}/*").each do |entry|
      begin
        if File.mtime(entry) < threshold
          Rails.logger.info "Removing old file: #{entry}"
          if File.directory?(entry)
            FileUtils.rm_rf(entry)
          else
            FileUtils.rm(entry)
          end
        else
          Rails.logger.info "Keeping recent file: #{entry}"
        end
      rescue => e
        Rails.logger.error "Error cleaning #{entry}: #{e.message}"
      end
    end

    # Verify cleanup
    remaining = Dir.glob("#{download_root}/*")
    Rails.logger.info "Remaining files after cleanup: #{remaining.length}"
    remaining.each do |entry|
      Rails.logger.info "Remaining: #{entry} (#{File.mtime(entry)})"
    end
  end
end
