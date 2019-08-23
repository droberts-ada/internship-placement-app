class PlacementsController < ApplicationController
  before_action :find_placement, only: [:show, :update, :duplicate]

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
      redirect_back(fallback_location: classroom_path(params[:classroom_id]))
    end
  end

  def show
  end

  def update
    begin
      updates = placement_update_params
      @placement.set_pairings(updates.delete('pairings'))
      @placement.update!(updates)

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

  def duplicate
    puts "Copying placement #{@placement.name}"
    copy = @placement.duplicate(@current_user)
    puts "Copy success! New placement is called #{copy.name}"

    respond_to do |format|
      format.html do
        return redirect_to placement_path(copy)
      end
      format.json do
        return render json: { errors: [], placement: {
          name: copy.name,
          id: copy.id,
          url: placement_path(copy)
        } }
      end
    end
  end

private
  def find_placement
    begin
      @placement = Placement.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end
  end

  def placement_update_params
    params.require(:placement).permit(:whiteboard, pairings: [:company_id, :student_id])
  end
end
