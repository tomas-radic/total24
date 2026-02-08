module ApplicationHelper
  def shorten_text(text, max_length = nil)
    max_length ||= 24
    dots = "..." if text.length > max_length
    "#{text[0...max_length]}#{dots}"
  end


  def app_date(datetime, prefix: false, vertical: false)
    result = ""
    return result if datetime.blank?

    days = ["pon", "uto", "str", "štv", "pia", "sob", "ned"]
    months = ["jan", "feb", "mar", "apr", "máj", "jún", "júl", "aug", "sep", "okt", "nov", "dec"]

    datetime = datetime.to_date

    if prefix
      result = case (Time.zone.now.to_date - datetime).to_i
               when 1
                 "včera"
               when 0
                 "dnes"
               when -1
                 "zajtra"
               else
                 ""
               end
    end

    day = days[datetime.wday - 1]
    date = "#{datetime.day}. #{months[datetime.month - 1]}"

    if vertical
      content_tag :span do
        result += "<br>" if result.present?
        result += (day + "<br>" + date)
        result.html_safe
      end.html_safe
    else
      result += " - " if result.present?
      result += "#{day}, #{date}"
      result
    end
  end


  def app_time(datetime)
    "#{app_date(datetime)} - #{datetime.strftime("%k:%M")}".html_safe
  end


  def text_success_css(success_count, total_count)
    half = total_count / 2.0

    if success_count > half
      "u-nav-green"
    elsif success_count < half
      "u-red"
    end
  end


  def error_for(attribute, object)
    if object.errors[attribute].present?
      content_tag :p, class: "u-red" do
        "Chýbajúci, alebo nesprávny údaj."
      end
    end
  end


  def break_whitespace(text)
    text.gsub(/\s+/, "<br>").html_safe
  end


  def formatted_phone_nr(phone_nr, dialable: false, classes: nil)
    phone_nr.gsub!(/[^0-9]/, "")
    return "" if phone_nr.length < 9

    phone_nr.reverse!.insert(3, " ").insert(7, " ")
    phone_nr = (phone_nr[0..10] + "0").reverse
    return phone_nr unless dialable

    link_to phone_nr, "tel:#{phone_nr.gsub(/[^0-9]/, "")}", class: classes.to_s
  end


  def inactive_css_class(inactive = true)
    inactive ? "u-grey" : ""
  end

  def confirmation_for(label, message:, button_classes: "btn-primary", action_path:, action_data: {})
    button_classes = "btn #{button_classes}"

    content_tag(:button, class: button_classes, type: "button",
                data: {
                  bs_toggle: "modal",
                  bs_target: "#confirmation-modal",
                  bs_title: label,
                  bs_message: message,
                  bs_action_path: action_path,
                  bs_action_data: action_data
                }) do
      label
    end
  end

  def modal(id, title:, submit_label: "Ok", submit_class: "btn-primary", size_class: nil, data_attributes: {})
    content_tag(:div, class: "modal fade", id:, tabindex: "-1",
                aria: { labelledby: "#{id}-label", hidden: "true" }, data: data_attributes) do
      content_tag(:div, class: "modal-dialog #{size_class}") do
        content_tag(:div, class: "modal-content") do
          m_header = content_tag(:div, class: "modal-header") do
            m_title = content_tag(:h1, title,
                                  class: "modal-title fs-5", id: "#{id}-label")
            m_close = content_tag(:button, "", type: "button",
                                  class: "btn-close", data: { bs_dismiss: "modal" }, aria: { label: "Close" })
            m_title + m_close
          end

          m_content = content_tag(:div, class: "modal-body") do
            yield
          end

          m_footer = content_tag(:div, class: "modal-footer") do
            content_tag(:button, "Naspäť", type: "button",
                        class: "btn btn-secondary", data: { bs_dismiss: "modal" }
            ) + link_to(submit_label, "#",
                            id: "default-modal-submit", class: "btn #{submit_class} px-4")
          end

          m_header + m_content + m_footer
        end
      end
    end
  end
end
