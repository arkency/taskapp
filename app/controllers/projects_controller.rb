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
  end
end
