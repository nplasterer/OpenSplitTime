class CoursesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :best_efforts]
  before_action :set_course, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show, :best_efforts]

  def index
    @courses = Course.paginate(page: params[:page], per_page: 25).order(:name)
    session[:return_to] = courses_path
  end

  def show
    @course_view = CourseShowView.new(@course, params)
    session[:return_to] = course_path(@course)
  end

  def new
    @course = Course.new
    authorize @course
  end

  def edit
    authorize @course
  end

  def create
    @course = Course.new(course_params)
    authorize @course

    if @course.save
      @course.update_initial_splits
      redirect_to new_event_path(course_id: @course.id)
    else
      render 'new'
    end
  end

  def update
    authorize @course

    if @course.update(course_params)
      redirect_to session.delete(:return_to) || @course
    else
      render 'edit'
    end
  end

  def destroy
    authorize @course
    if @course.events.present?
      flash[:danger] = 'Course cannot be deleted if events are present on the course. Delete the related events individually and then delete the course.'
    else
      @course.destroy
      flash[:success] = 'Course deleted.'
    end

    session[:return_to] = params[:referrer_path] if params[:referrer_path]
    redirect_to session.delete(:return_to) || courses_path
  end

  def best_efforts
    course = Course.find(params[:id])
    if course.visible_events.count < 1
      flash[:danger] = "No events yet held on this course"
      redirect_to course_path(course)
    elsif Effort.visible.on_course(course).count < 1
      flash[:danger] = "No efforts yet run on this course"
      redirect_to course_path(course)
    end
    params[:gender] ||= 'combined'
    @best_display = BestEffortsDisplay.new(course, params)
    session[:return_to] = best_efforts_course_path(course)
  end

  def segment_picker
    authorize @course
  end

  def plan_effort
    course = Course.find(params[:id])
    authorize course
    unless course.events
      flash[:danger] = "No events yet held on this course"
      redirect_to course_path(course)
    end
    @plan_display = PlanDisplay.new(course, params)
    session[:return_to] = plan_effort_course_path(course)
  end

  private

  def course_params
    params.require(:course).permit(:name, :description, :next_start_time,
                                   splits_attributes: [:id, :course_id, :location_id, :base_name,
                                                       :description, :kind, :sub_split_bitmap,
                                                       :distance_from_start, :distance_as_entered,
                                                       :vert_gain_from_start, :vert_gain_as_entered,
                                                       :vert_loss_from_start, :vert_loss_as_entered])
  end

  def query_params
    params.permit(:name)
  end

  def set_course
    @course = Course.find(params[:id])
  end

end
