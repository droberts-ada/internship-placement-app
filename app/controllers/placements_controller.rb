class PlacementsController < ApplicationController
  before_action :find_placement, only: [:show, :update]

  def index
    @classrooms = Classroom.all
    @placements = Placement.all

    # If the request was for a particular classroom, filter for it
    @classroom_id = params[:classroom_id]
  end

  def create
    # params are always strings, but here we want a boolean
    run_solver = params[:run_solver] && params[:run_solver] != "false"
    @placement = Placement.build(classroom_id: params[:classroom_id], owner: @current_user)
    if @placement.save()
      if run_solver
        begin
          @placement.solve
        rescue StandardError => error
          flash[:status] = :failure
          flash[:message] = error.message
          redirect_to classroom_path(params[:classroom_id])
          return
        end
      end
      redirect_to placement_path(@placement)
    else
      flash[:status] = :failure
      flash[:message] = "Could not create placement"
      flash[:errors] = @placement.errors.messages
      redirect_back
    end
  end

  def show
  end

  def update
    begin
      @placement.set_pairings(placement_update_params['pairings'])

      puts "Transaction success!"
      render json: {
        errors: []
      }
    rescue ActiveRecord::RecordInvalid => invalid
      puts "Rendering bad request"
      render status: :bad_request, json: {
        errors: invalid.record.errors.messages
      }
    end
  end

private
  def find_placement
    begin
      @placement = Placement.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render status: :not_found, content: false
    end
  end

  def placement_update_params
    params.require(:placement).permit(pairings: [:company_id, :student_id])
  end
end
