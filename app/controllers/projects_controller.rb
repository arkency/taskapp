class ProjectsController < ApplicationController
  def index
    @pagy, @projects = pagy_countless(Project.all.order(:id), items: 10)
  end

  def show
    @project = Project.find(params[:id])
  end

  def extend_all_projects_deadline
    Project.find_each do |project|
      project.end_date = project.end_date + 1.week
      project.save!
      sleep 0.5
      Turbo::StreamsChannel.broadcast_replace_later_to(
        "projects",
        target: dom_id_for(project),
        partial: "projects/project",
        locals: { project: project },
      )
    end
  end

  def kanban
    @todo_projects = Project.where(status: 'planned')
    @in_progress_projects = Project.where(status: 'ongoing')
    @completed_projects = Project.where(status: 'completed')
  end

  def destroy
    @project = Project.find(params[:id])
    @project.destroy

    Turbo::StreamsChannel.broadcast_remove_to(
      "projects",
      target: @project,
    )

    respond_to do |format|
      format.html { redirect_to projects_url }
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove(dom_id_for(@project))
      end
    end
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
