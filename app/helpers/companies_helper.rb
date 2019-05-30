module CompaniesHelper
  def format_date(date)
    return "#{date.strftime("%a %B %d")} at #{date.strftime("%l:%M %p")}"
  end
end
