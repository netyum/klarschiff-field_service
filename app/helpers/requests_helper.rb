module RequestsHelper
  def mark_trust(request)
    trust = request.extended_attributes.trust
    content_tag(:span, class: 'label label-default') do 
      content_tag(:span) do
        trust.times do
          concat content_tag(:span, nil, class: 'glyphicon glyphicon-star', "aria-hidden" => true)
        end
      end
    end if trust > 0
  end

  def mark_photo_required(request)
    content_tag(:span, class: 'label label-default') do
      content_tag :span, nil, class: 'glyphicon glyphicon-camera', "aria-hidden" => true
    end if request.extended_attributes.photo_required
  end

  def status(request)
    status = t(request.detailed_status.downcase, scope: :status)
    if date = request.extended_attributes.detailed_status_datetime
      status << " (#{ t('requests.status.since') } #{ l(date.to_date) })"
    end
    status << ", #{ t('requests.status.currently') } #{ request.agency_responsible }"
  end

  def statuses(request)
    Settings::Map.default_requests_states.split(', ').select { |st|
      st.in?(Settings::Request.permissable_states | [request.detailed_status])
    }.map { |st| [t(st.downcase, scope: :status), st] }
  end

  def categories(type, current = nil)
    categories = Service.collection.select { |s| s.type == type }.map(&:group).uniq.sort
    unless current
      categories.insert 0, [t('placeholder.select.category'), disabled: true, selected: current.nil?, class: :placeholder]
    end
    options_for_select categories, current
  end

  def services(category = nil)
    Service.collection.select { |s| s.group == category }.map { |s|
      [s.service_name, s.service_code]
    }.insert 0, [t('placeholder.select.service'), disabled: true, class: :placeholder]
  end
end
