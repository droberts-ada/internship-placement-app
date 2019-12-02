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

  def morning_times(date)
    return [
      "#{date} 09:00",
      "#{date} 09:40",
      "#{date} 10:20",
      "#{date} 11:00",
      "#{date} 11:40",
      "#{date} 12:20",
    ]
  end

  def afternoon_times(date)
    return [
      "#{date} 13:00",
      "#{date} 13:40",
      "#{date} 14:20",
      "#{date} 15:00",
      "#{date} 15:40",
      "#{date} 16:20",
    ]
  end
end
