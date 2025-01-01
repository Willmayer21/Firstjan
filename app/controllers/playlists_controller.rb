class PlaylistsController < ApplicationController
  require 'csv'
  require 'rspotify'
  require 'open3'
  require 'fileutils'
  require 'shellwords'
  require 'mp3info'
  require 'open-uri'

  def new
  end

  def download
    @playlist_id = params[:playlist_id]
    RSpotify.authenticate(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_CLIENT_SECRET'])

    begin
      @playlist = RSpotify::Playlist.find_by_id(@playlist_id)
      raise "Playlist not found" unless @playlist

      folder_name = "spotify_downloads_#{sanitize_filename(@playlist.name)}"
      download_dir = Rails.root.join('public', 'downloads', folder_name)
      FileUtils.mkdir_p(download_dir)

      ActionCable.server.broadcast "progress_channel", {
        type: "playlist_info",
        name: @playlist.name,
        total_tracks: @playlist.tracks.count
      }

      @playlist.tracks.each_with_index do |track, index|
        artwork_url = track.album.images.max_by { |img| img['height'].to_i }&.fetch('url')
        artwork_data = get_artwork_data(artwork_url)

        ActionCable.server.broadcast "progress_channel", {
          type: "track_progress",
          track_name: track.name,
          artist_name: track.artists.first.name,
          index: index + 1
        }

        download_track(track.name, track.artists.first.name, artwork_data, download_dir)
      end

      zip_file_path = Rails.root.join('public', 'downloads', "#{folder_name}.zip").to_s
      system('zip', '-r', zip_file_path, download_dir.to_s)

      ActionCable.server.broadcast "progress_channel", {
        type: "complete",
        download_path: "/downloads/#{folder_name}.zip"
      }

    rescue => e
      ActionCable.server.broadcast "progress_channel", {
        type: "error",
        message: e.message
      }
    end

    head :ok
  end

  private

  def sanitize_filename(filename)
    filename.gsub(/[\x00\/\\:*?"<>|]/, '_')
  end

  def get_artwork_data(url)
    return nil unless url
    begin
      URI.open(url, &:read)
    rescue
      nil
    end
  end

  def download_track(track_name, artist_name, artwork_data, output_dir)
    search_query = "#{track_name} #{artist_name}"
    filename = sanitize_filename("#{artist_name} - #{track_name}")
    output_path = "#{output_dir}/#{filename}.mp3"

    command = [
      'yt-dlp',
      '--extract-audio',
      '--audio-format', 'mp3',
      '--audio-quality', '0',
      '--output', output_path,
      '--no-playlist',
      '--no-warnings',
      "ytsearch1:#{search_query}"
    ]

    success = system(*command)

    if success && File.exist?(output_path)
      begin
        Mp3Info.open(output_path) do |mp3|
          mp3.tag.title = track_name
          mp3.tag.artist = artist_name
          mp3.tag2.add_picture(artwork_data) if artwork_data
        end
      rescue => e
        logger.warn "Could not set metadata: #{e.message}"
      end
    else
      logger.warn "Download failed for #{track_name}"
    end
  end
end
