class ProjectsController < ApplicationController
  def index
    @projects = Project.all
  end

  def kanban
    @todo_projects = Project.where(status: 'planned')
    @in_progress_projects = Project.where(status: 'ongoing')
    @completed_projects = Project.where(status: 'completed')
  end

  def destroy
    @project = Project.find(params[:id])
    @project.destroy
  end

  def start
    @project = Project.find(params[:id])
    @project.status = 'ongoing'
    @project.save

    redirect_to kanban_path
  end

  def complete
    @project = Project.find(params[:id])
    @project.status = 'completed'
    @project.save

    redirect_to kanban_path
  end

  private

  def dom_id_for(project)
    "project_#{project.id}"
  end
end
