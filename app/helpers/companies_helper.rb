module CompaniesHelper
  def display_cell(company, inner, args = {})
    if company.redirect_to
      inner_class = "deleted #{args[:class]}"
    else
      inner_class = args[:class]
    end

    if inner_class
      content_tag(:span, inner, class: inner_class)
    else
      inner
    end
  end
end
