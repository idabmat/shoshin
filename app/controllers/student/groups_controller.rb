class Student::GroupsController < StudentController
  def show
    @group = Group.includes(:teaching, chapters: [:lessons , :exercises])
                  .find(params[:id])
    redirect_to root_url unless current_user.in? @group.students
  end
end
