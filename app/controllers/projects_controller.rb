class ProjectsController < ApplicationController
  def index
    @projects_count = Project.count
    @pagy, @projects = pagy_countless(Project.all, items: 10)
  end

  def kanban
    @todo_projects = Project.where(status: 'planned')
    @in_progress_projects = Project.where(status: 'ongoing')
    @completed_projects = Project.where(status: 'completed')
  end

  def destroy
    @project = Project.find(params[:id])
    @project.destroy

    redirect_to projects_path(format: :html)
  end

  def start
    @project = Project.find(params[:id])
    @project.status = 'ongoing'
    @project.save

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.prepend('ongoing_projects', partial: 'projects/kanban/ongoing_project', locals: { project: @project }),
          turbo_stream.remove(dom_id_for(@project))
        ]
      end
    end
  end

  def complete
    @project = Project.find(params[:id])
    @project.status = 'completed'
    @project.save

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.prepend('completed_projects', partial: 'projects/kanban/completed_project', locals: { project: @project }),
          turbo_stream.remove(dom_id_for(@project))
        ]
      end
    end
  end

  private

  def dom_id_for(project)
    "project_#{project.id}"
  end
end
