class SplitTimePolicy
  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @split_time = model
  end

  def import?
    @current_user.present?
  end

  def new?
    @current_user.present?
  end

  def edit?
    @current_user.authorized_to_edit?(@split_time)
  end

  def create?
    @current_user.present?
  end

  def update?
    @current_user.authorized_to_edit?(@split_time)
  end

  def destroy?
    @current_user.authorized_to_edit?(@split_time)
  end

end
