# frozen_string_literal: true

module CallListHelper
  def call_list_sort_link(column, label)
    next_direction = @sort == column && @direction == "asc" ? "desc" : "asc"
    active = @sort == column

    link_to call_list_path(sort: column, direction: next_direction),
            class: "inline-flex items-center gap-1 hover:text-blue-700 #{'text-blue-700' if active}" do
      safe_join([
        label,
        call_list_sort_indicator(active, @direction)
      ])
    end
  end

  def call_list_invite_badge(user)
    if user.invite_accepted?
      tag.span "Invite accepted",
               class: "inline-flex items-center rounded-full bg-emerald-100 text-emerald-700 text-xs font-medium px-2 py-1"
    else
      tag.span "Invite pending",
               class: "inline-flex items-center rounded-full bg-amber-100 text-amber-800 text-xs font-medium px-2 py-1"
    end
  end

  def call_list_btc_badge(user)
    case user.bitcoin_address_status
    when :complete
      tag.span "Complete",
               class: "inline-flex items-center rounded-full bg-emerald-100 text-emerald-700 text-xs font-medium px-2 py-1"
    when :missing
      tag.span user.bitcoin_address_status_label,
               class: "inline-flex items-center rounded-full bg-amber-100 text-amber-800 text-xs font-medium px-2 py-1"
    else
      tag.span "No investments",
               class: "inline-flex items-center rounded-full bg-gray-100 text-gray-700 text-xs font-medium px-2 py-1"
    end
  end

  def call_list_phone_display(user)
    numbers = user.call_list_phone_numbers
    return "—" if numbers.empty?

    safe_join(numbers.map { |number| tag.div(number, class: "whitespace-nowrap") })
  end

  def call_list_bitcoin_addresses_display(user)
    addresses = user.bitcoin_addresses_for_call_list
    return "—" if addresses.empty?

    safe_join(addresses.map { |address| tag.div(address, class: "font-mono text-xs break-all") })
  end

  private

  def call_list_sort_indicator(active, direction)
    return tag.span("↕", class: "text-gray-400 text-xs", aria: { hidden: true }) unless active

    arrow = direction == "asc" ? "↑" : "↓"
    tag.span(arrow, class: "text-blue-700 text-xs", aria: { label: "Sorted #{direction}" })
  end
end
