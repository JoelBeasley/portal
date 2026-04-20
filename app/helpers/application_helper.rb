module ApplicationHelper
  # e.g. Dec 11th, 2025
  def format_ordinal_date(value)
    return if value.blank?

    d = value.respond_to?(:to_date) ? value.to_date : value
    "#{d.strftime('%b')} #{d.day.ordinalize}, #{d.year}"
  end

  # Propshaft fingerprints CSS, but browsers (especially mobile) can still serve a stale Tailwind file in dev.
  # Append a build timestamp in development so every tailwindcss rebuild gets a fresh URL.
  def tailwind_stylesheet_link_tag
    href = path_to_stylesheet("tailwind.css")
    if Rails.env.development?
      build_file = Rails.root.join("app/assets/builds/tailwind.css")
      stamp = File.exist?(build_file) ? File.mtime(build_file).to_i : Time.current.to_i
      href = "#{href}#{href.include?('?') ? '&' : '?'}v=#{stamp}"
    end
    tag.link rel: "stylesheet", href: href, "data-turbo-track": "reload"
  end
end
