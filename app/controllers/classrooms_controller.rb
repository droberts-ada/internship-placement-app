class ClassroomsController < ApplicationController
  before_action :find_classroom, except: [:index, :new, :create]

  def index
    @classrooms = Classroom.all
  end

  def new
    @classroom = Classroom.new
  end

  def create
    # Make sure we have a valid interview file
    interviews_file = params[:interviews_csv]
    raise IOError.new('No interviews CSV file uploaded') unless interviews_file
    interviews_csv = CSV.parse(interviews_file.read).reject(&:empty?)

    Classroom.transaction do
      @classroom = Classroom.create(classroom_params) do |classroom|
        classroom.creator = @current_user
      end
      raise ActiveRecord::RecordInvalid unless @classroom.persisted?

      @classroom.setup_from_interviews!(interviews_csv)
    end

    flash[:status] = :success
    flash[:message] = "created classroom #{@classroom.name}"
    redirect_to @classroom
  rescue ActiveRecord::RecordInvalid => ex
    flash[:status] = :failure
    flash[:message] = "could not create classroom"
    flash[:errors] = @classroom.errors.messages.merge(error: [ex.message])

    render :new, status: :bad_request
  rescue IOError, CSV::MalformedCSVError => ex
    flash[:status] = :failure
    flash[:message] = "could not use interviews CSV file"
    flash[:errors] = {interviews_csv: [ex.message]}

    @classroom ||= Classroom.new(classroom_params)
    render :new, status: :bad_request
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

private
  def classroom_params
    params.require(:classroom).permit(:name)
  end

  def find_classroom
    @classroom = Classroom.find_by(id: params[:id])
    if @classroom.nil?
      render file: "public/404.html", status: :not_found
    end
  end
end
