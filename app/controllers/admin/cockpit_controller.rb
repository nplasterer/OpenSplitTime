class Admin::CockpitController < AdminController
  before_action :authenticate_user!
  after_action :verify_authorized

  def cockpit
    authorize :cockpit, :show?
  end

  def check_split_times
    SplitTime.all.each do |split_time|
      split_time.data_status = 'bad' if split_time.segment_time < 0
    end

  end

end