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

  def confirmation_for(purpose, button_label:, button_classes: "btn-primary", confirmation_text:, action_path:, action_data: {})
    button_classes = "btn #{button_classes}"

    button = content_tag(:button, class: button_classes, type: "button",
                         data: { bs_toggle: "modal", bs_target: "##{purpose}Modal" }) do
      button_label
    end

    modal = content_tag(:div, class: "modal fade", id: "#{purpose}Modal", tabindex: "-1", aria_labelledby: "#{purpose}ModalLabel", aria_hidden: "true") do
      content_tag(:div, class: "modal-dialog") do
        content_tag(:div, class: "modal-content") do
          content_tag(:div, class: "modal-header") do
            content_tag(:h1, class: "modal-title fs-5", id: "#{purpose}ModalLabel") do
              button_label
            end + content_tag(:button, class: "btn-close", type: "button",
                              data: { bs_dismiss: "modal", aria_label: "Close" }) {}
          end + content_tag(:div, class: "modal-body") do
            content_tag(:p, confirmation_text)
          end + content_tag(:div, class: "modal-footer") do
            content_tag(:button, type: "button", class: "btn btn-secondary", data: { bs_dismiss: "modal" }) do
              "Naspäť"
            end + link_to("Ok", action_path, class: "btn btn-primary px-4", data: action_data)
          end
        end
      end
    end

    button + modal
  end
end
