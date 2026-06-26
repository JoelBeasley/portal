module ApplicationHelper
  def nav_user
    current_user
  end

  def show_sites_nav_link?
    nav_user&.can_access_sites?
  end

  def show_call_list_nav_link?
    nav_user&.can_access_call_list?
  end

  def sites_nav_link_classes
    base = "whitespace-nowrap transition"
    if nav_user&.can_access_admin_area?
      "text-sm lg:text-base text-blue-300 font-medium hover:text-blue-200 #{base}"
    else
      "text-sm lg:text-base text-slate-200 hover:text-white #{base}"
    end
  end

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
