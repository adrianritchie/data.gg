class Route < ActiveRecord::Base
  
  has_many :route_stops
  has_many :stop_links
  belongs_to :timetable
  
  validates :name, presence: true
  validates :description, presence: true
  validates :start_day, presence: true
  validates :end_day, presence: true
end