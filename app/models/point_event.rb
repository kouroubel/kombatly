class PointEvent < ApplicationRecord
  belongs_to :bout
  belongs_to :athlete
end
