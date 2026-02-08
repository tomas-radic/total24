module Player::EnrollmentsHelper
  def season_enrollment_notice(season, player)
    return if season.ended?
    enrollment = season.enrollments.find_by(player_id: player.id)
    return if enrollment&.canceled?
    return if enrollment&.active?

    if enrollment.blank?
      notice = content_tag( :div, class: "top-notice") do
        content_tag(:button, type: "button",
                    class: "p-0 border-0 bg-transparent text-decoration-underline text-reset",
                    data: { bs_toggle: "modal", bs_target: "#enrollment-modal" }) do
          "Zapíš sa"
        end + " do súčasnej sezóny a začni hrať!"
      end

      modal = modal("enrollment-modal", title: "Odsúhlasenie pravidiel",
                    submit_class: "d-none", size_class: "modal-fullscreen") do
        fore_text = content_tag(:p, class: "u-fs-big text-center m-4") do
          "Na tejto stránke si prečítaj pravidlá tejto súťaže a na spodu potvrď svoj súhlas. Ak s pravidlami súhlasíš, môžeš použiť QR kód nižšie pre platbu štartovného."
        end
        rules = render("pages/rules", season:)
        payment = render("player/enrollments/qr_payment")

        form = form_with(url: player_enrollments_path, method: :post) do |f|
          checkbox = content_tag(:div, class: "form-check d-flex justify-content-center my-4") do
            checkbox = f.check_box :agreement, required: true, value: "1", class: "form-check-input", style: "border-color: darkorange;"
            label = f.label :agreement, "Prečítal/a som si pravidlá a súhlasím s nimi.", class: "ms-2 form-check-label"
            checkbox + label
          end

          submit = content_tag(:div, class: "d-flex justify-content-center mt-3") do
            f.submit "Potvrdzujem", class: "btn btn-primary"
          end

          checkbox + submit
        end

        fore_text + rules + content_tag(:hr) + payment + form
      end

      notice + modal
    elsif enrollment.fee_amount_paid.blank?
      notice = content_tag( :div, class: "top-notice") do
        ("Tvoj zápis do sezóny je pripravený, ale stále čaká na " + content_tag(:button, type: "button",
                    class: "p-0 border-0 bg-transparent text-decoration-underline text-reset",
                    data: { bs_toggle: "modal", bs_target: "#payment-modal" }) do
          "zaplatenie štartovného."
        end).html_safe
      end

      modal = modal("payment-modal", title: "Platba štartovného",
                            submit_class: "d-none", size_class: "modal-fullscreen") do
        render("player/enrollments/qr_payment")
      end

      notice + modal
    end
  end
end
