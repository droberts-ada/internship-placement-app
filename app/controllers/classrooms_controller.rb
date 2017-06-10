require 'classroom_generator'
require 'interview_result_spreadsheet'
require 'student_preference_spreadsheet'

class ClassroomsController < ApplicationController
  before_action :find_classroom, except: [:index, :new, :create]

  def index
    @classrooms = Classroom.all
  end

  def new
    @classroom = Classroom.new
  end

  def create
    if params[:generate]
      @classroom = ClassroomGenerator::build_classroom
      redirect_to classroom_path(@classroom)

    else
      @classroom = Classroom.new(classroom_params)
      @classroom.creator = @current_user

      if @classroom.save
        flash[:status] = :success
        flash[:message] = "created classroom #{@classroom.id}"
        redirect_to classroom_path(@classroom)

      else
        flash[:status] = :failure
        flash[:message] = "could not create classroom"
        flash[:errors] = @classroom.errors.messages
        render :new

      end
    end
  end

  def show
  end

  def edit
  end

  def update
    @classroom.update_attributes(classroom_params)

    if @classroom.save
      flash[:status] = :success
      flash[:message] = "updated classroom #{@classroom.id}"
      redirect_to classroom_path(@classroom)

    else
      flash[:status] = :failure
      flash[:message] = "could not update classroom"
      flash[:errors] = @classroom.errors.messages
      render :edit

    end
  end

  def destroy
    # TODO DPR: destroy all placements
    @classroom.destroy
    redirect_to classrooms_path
  end

  def populate
    # flash[:status] = :failure
    # flash[:message] = "Not yet implemented"
    # redirect_to classroom_path(params[:classroom_id])
    interview_sheet = InterviewResultSpreadsheet.new(@classroom.interview_result_spreadsheet, @current_user)
    interviews = interview_sheet.populate

    student_sheet = StudentPreferenceSpreadsheet.new(@classroom.student_preference_spreadsheet, @current_user)
    preferences = student_sheet.populate

    @classroom.from_spreadsheets(interviews, preferences)

    # render :populate
    redirect_to classroom_path(@classroom)
  end

private
  def classroom_params
    params.require(:classroom).permit(:name, :interview_result_spreadsheet, :student_preference_spreadsheet, :interviews_per_slot)
  end

  def find_classroom
    @classroom = Classroom.find_by(id: params[:id])
    if @classroom.nil?
      render file: "public/404.html", status: :not_found
    end
  end
end
