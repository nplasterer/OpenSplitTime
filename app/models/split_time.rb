class SplitTime < ActiveRecord::Base
  include Auditable
  enum data_status: [:bad, :questionable, :good, :confirmed]
  strip_attributes collapse_spaces: true
  belongs_to :effort
  belongs_to :split

  scope :valid_status, -> { where(data_status: [nil, data_statuses[:good], data_statuses[:confirmed]]) }
  scope :ordered, -> { includes(:split).order('splits.distance_from_start, split_times.sub_split_bitkey') }
  scope :finish, -> { includes(:split).where(splits: {kind: Split.kinds[:finish]}) }
  scope :start, -> { includes(:split).where(splits: {kind: Split.kinds[:start]}) }
  scope :out, -> { where(sub_split_bitkey: SubSplit::OUT_BITKEY) }
  scope :in, -> { where(sub_split_bitkey: SubSplit::IN_BITKEY) }

  attr_accessor :day_and_time_attr

  before_validation :delete_if_blank
  after_update :set_effort_data_status, if: :time_from_start_changed?

  validates_presence_of :effort_id, :split_id, :sub_split_bitkey, :time_from_start
  validates :data_status, inclusion: {in: SplitTime.data_statuses.keys}, allow_nil: true
  validates_uniqueness_of :split_id, scope: [:effort_id, :sub_split_bitkey],
                          message: 'only one of any given split/sub_split permitted within an effort'
  validate :course_is_consistent, unless: 'effort.nil? | split.nil?'

  def course_is_consistent
    if effort.event.course_id != split.course_id
      errors.add(:effort_id, 'the effort.event.course_id does not resolve with the split.course_id')
      errors.add(:split_id, 'the effort.event.course_id does not resolve with the split.course_id')
    end
  end

  def bitkey_hash
    {split_id => sub_split_bitkey}
  end

  def set_effort_data_status
    DataStatusService.set_data_status(effort)
  end

 def elapsed_time
    return nil if time_from_start.nil?
    seconds = time_from_start % 60
    minutes = (time_from_start / 60) % 60
    hours = time_from_start / (60 * 60)
    format("%02d:%02d:%02d", hours, minutes, seconds)
  end

  alias_method :formatted_time_hhmmss, :elapsed_time

  def elapsed_time=(elapsed_time)
    if elapsed_time.present?
      units = %w(hours minutes seconds)
      self.time_from_start = elapsed_time.split(':').map.with_index { |x, i| x.to_i.send(units[i]) }.reduce(:+).to_i
    else
      self.time_from_start = nil
    end
  end

  def day_and_time
    return nil if time_from_start.nil?
    event_start_time + effort_start_offset + time_from_start
  end

  def day_and_time=(absolute_time)
    if absolute_time.present?
      self.time_from_start = absolute_time - event_start_time - effort_start_offset
    else
      self.time_from_start = nil
    end
  end

  def military_time=(military_time)
    if military_time.present?
      self.day_and_time = effort.intended_datetime(military_time, split)
    else
      self.day_and_time = nil
    end
  end

  def self.confirmed!
    all.each { |split_time| split_time.confirmed! }
  end

  def self.good!
    all.each { |split_time| split_time.good! }
  end

  def split_name
    split.name(sub_split_bitkey)
  end

  def effort_name
    effort.full_name
  end

  def event_name
    effort.event_name
  end

  private

  def event_start_time
    effort.event_start_time
  end

  def effort_start_offset
    effort.start_offset
  end

  def delete_if_blank
    self.delete if elapsed_time == ""
  end

end