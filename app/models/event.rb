class Event < ActiveRecord::Base
  belongs_to :course, touch: true
  belongs_to :race
  has_many :efforts, dependent: :destroy
  has_many :event_splits, dependent: :destroy
  has_many :splits, through: :event_splits

  validates_presence_of :course_id, :name, :first_start_time
  validates_uniqueness_of :name, case_sensitive: false

  def all_splits_on_course?
    splits.each do |split|
      return false if split.course_id != course_id
    end
    true
  end

  def split_ids
    splits.ordered.map &:id
  end

  def unreconciled_efforts
    efforts.where(participant_id: nil)
  end

  def unreconciled_efforts?
    efforts.where(participant_id: nil).count > 0
  end

  def set_start_and_finish
    splits << course.splits.start if splits.start.empty?
    splits << course.splits.finish if splits.finish.empty?
  end

  def waypoint_groups
    result = []
    splits.find_each do |split|
      result << split.waypoint_group.map(&:id)
    end
    result.uniq
  end

end
