class TasksController < ApplicationController
  before_action :set_task, only: %i[show edit update destroy]

  # GET /tasks or /
  def index
    @tasks = Task.order(created_at: :desc)
    @task = Task.new

    respond_to do |format|
      format.html
      format.json { render json: @tasks }
    end
  end

  # GET /tasks/:id
  def show
    respond_to do |format|
      format.html { redirect_to tasks_path }
      format.json { render json: @task }
    end
  end

  # GET /tasks/:id/edit
  def edit
  end

  # POST /tasks
  def create
    @task = Task.new(task_params)

    respond_to do |format|
      if @task.save
        format.html { redirect_to tasks_path, notice: "Task was successfully created." }
        format.json { render json: @task, status: :created }
      else
        @tasks = Task.order(created_at: :desc)
        format.html { render :index, status: :unprocessable_entity }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tasks/:id
  def update
    respond_to do |format|
      if @task.update(task_params)
        format.html { redirect_to tasks_path, notice: "Task was successfully updated." }
        format.json { render json: @task, status: :ok }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tasks/:id
  def destroy
    @task.destroy!

    respond_to do |format|
      format.html { redirect_to tasks_path, notice: "Task was removed." }
      format.json { head :no_content }
    end
  end

  private

  def set_task
    @task = Task.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to tasks_path, alert: "Task not found." }
      format.json { render json: { error: "Not found" }, status: :not_found }
    end
  end

  def task_params
    params.require(:task).permit(:title, :description, :completed)
  rescue ActionController::ParameterMissing
    # Allows raw JSON payloads like {"title": "Buy milk"} without a "task" wrapper
    params.permit(:title, :description, :completed)
  end
end