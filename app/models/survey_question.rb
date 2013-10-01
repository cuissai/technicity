class SurveyQuestion < ActiveRecord::Base
  attr_accessible :description, :multiple_choice, :name, :order_by, :survey_id
  has_many :survey_options
  has_many :survey_responses
end
