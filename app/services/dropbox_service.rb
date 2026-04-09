class DropboxService
  def initialize
    @client = DropboxApi::Client.new(
      oauth2_refresh_token: Rails.application.credentials.dropbox[:refresh_token],
      oauth2_client_id: Rails.application.credentials.dropbox[:app_key],
      oauth2_client_secret: Rails.application.credentials.dropbox[:app_secret]
    )
  end

  def list_documents(dropbox_path)
    entries = []
    result = @client.list_folder(dropbox_path, recursive: false)

    result.entries.each do |entry|
      next unless entry.is_a?(DropboxApi::Metadata::File)

      link = @client.get_temporary_link(entry.path_lower)
      entries << {
        name: entry.name,
        size: entry.size,
        modified: entry.server_modified,
        download_url: link.link
      }
    end
    entries
  rescue => e
    Rails.logger.error "Dropbox error: #{e.message}"
    []
  end

  def create_folder(path)
    @client.create_folder(path)
    Rails.logger.info "Created Dropbox folder: #{path}"
  rescue DropboxApi::Errors::ApiError => e
    if e.message.include?("path/conflict")
      Rails.logger.info "Folder already exists: #{path}"
    else
      raise
    end
  end
end
