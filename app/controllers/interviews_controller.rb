class InterviewsController < ApplicationController
  before_action :lookup_company

  def new
    @interview = Interview.new
  end

  def create
    Student.transaction do
      student_names.each_with_index do |student_name, i|
        student = Student.find_or_create_by!(name: student_name, classroom: @company.classroom)
        Interview.create!({student: student, company: @company, scheduled_at: interview_times[i]})
      end

      flash[:status] = :success
      flash[:message] = "Interviews successfully scheduled!"
      redirect_to company_path(@company.uuid)
    end
  rescue ActiveRecord::RecordInvalid, ArgumentError => ex
    report_error(:bad_request, "Failed to schedule interview: #{ex.message}", render_view: :new)
  end

  private

  def lookup_company
    @company = Company.find_by(uuid: params[:company_id])

    return render_not_found if @company.nil?
  end

  def student_names
    students_text = params[:students]
    raise ArgumentError.new('"students" is required!') unless students_text

    names = students_text.lines.map {|l| l.strip }

    if @company.classroom.interviews_per_slot == names.length
      return names
    else
      raise ArgumentError.new(
              "expected #{@company.classroom.interviews_per_slot} students but got #{names.length}!"
            )
    end
  end

  def interview_times
    date = Date.parse(params[:date])

    if params[:commit].downcase.include? "morning"
      morning_times(date)
    elsif params[:commit].downcase.include? "afternoon"
      afternoon_times(date)
    else
      raise ArgumentError.new("Can only schedule morning or afternoon interviews got: #{params[:commit]}")
    end
  end

  def zone_offset
    prefix = '+'
    offset_raw = Time.now.in_time_zone('America/Los_Angeles').utc_offset
    if offset_raw < 0
      prefix = '-'
      offset_raw *= -1
    end
    offset_hours = offset_raw / 60 / 60
    offset_mins = offset_raw / 60 % 60

    return sprintf("%s%02d:%02d", prefix, offset_hours, offset_mins)
  end

  def morning_times(date)
    return [
      Time.new(date.year, date.month, date.day, 9, 0, 0, zone_offset),
      Time.new(date.year, date.month, date.day, 9, 40, 0, zone_offset),
      Time.new(date.year, date.month, date.day, 10, 20, 0, zone_offset),
      Time.new(date.year, date.month, date.day, 11, 0, 0, zone_offset),
      Time.new(date.year, date.month, date.day, 11, 40, 0, zone_offset),
      Time.new(date.year, date.month, date.day, 12, 20, 0, zone_offset)
    ]
  end

  def afternoon_times(date)
    return [
      Time.new(date.year, date.month, date.day, 13, 0, 0, zone_offset),
      Time.new(date.year, date.month, date.day, 13, 40, 0, zone_offset),
      Time.new(date.year, date.month, date.day, 14, 20, 0, zone_offset),
      Time.new(date.year, date.month, date.day, 15, 0, 0, zone_offset),
      Time.new(date.year, date.month, date.day, 15, 40, 0, zone_offset),
      Time.new(date.year, date.month, date.day, 16, 20, 0, zone_offset)
    ]
  end
end
