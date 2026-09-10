module ClearSiteData
  private

  def clear_site_data
    # Browser-owned cleanup clears origin storage across tabs and avoids
    # per-database deletion being blocked by another open connection.
    response.set_header('Clear-Site-Data', '"storage"')
  end
end
