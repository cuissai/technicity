class StudyLaunchValidator < ActiveModel::Validator

  def validate(study)
    # These conditions really only apply if a study is opening
    if study.active

      if study.region_set.nil?
        study.errors[:base] << 'A study must have one image set'

      else

        if study.opened_at.nil?
          study.errors[:base] << 'A open study must have an "opened at" date'
        end

        if study.region_set.regions.length < 1
          study.errors[:base] << 'A study\'s image set must have at least one area'
        end

        study.region_set.regions.each do |region|
          if region.locations.length < 2
            study.errors[:base] << 'Each area must have at least two images'
          end
        end
      end

      if study.has_survey
        if study.survey_id.nil?
          study.errors[:base] << 'If a study is configured to have a survey (edit study info), one must be created prior to launch'
        elsif study.survey.survey_questions.length == 0
          study.errors[:base] << 'A survey must have at least one question'
        end
      end

    end
  end
end

class Study < ActiveRecord::Base

  include ActiveModel::Validations
  validates_with StudyLaunchValidator
  validate :numeric_votes

  extend FriendlyId
  friendly_id :name, use: [:slugged, :history]
  validates_presence_of :name, :slug, :question, :description, :user_id

  attr_accessible :name, :public, :question, :description, :slug, :user_id, :active,
                  :has_survey, :survey_required_votes, :limit_votes, :survey_id

  belongs_to :region_set
  belongs_to :user
  belongs_to :survey
  has_many :comparisons, :dependent => :destroy
  has_many :regions, :through => :region_set
  has_many :locations, :through => :regions
  has_many :survey_responses

  def numeric_votes
    if has_survey || limit_votes
      greater_than_zero = survey_required_votes.to_i > 0
      errors.add(:survey_required_votes, 'must be greater than 0') unless greater_than_zero
    end
  end

  def randomLocation

    logger.debug(self)
    # Note, we could use rand() / random() to make this faster
    # but that would be SQL engine specific
    ids = Location.where('id IN (
      SELECT l.id
      FROM locations l
      JOIN regions r on l.region_id = r.id
      JOIN region_set_memberships rsm on r.id = rsm.region_id
      WHERE rsm.region_set_id = ?)', self.region_set_id).pluck(:id)

    logger.debug(ids)
    Location.find(ids.sample)

  end

  def randomLocationPair
    location1 = self.randomLocation
    location2 = self.randomLocation

    # Some checks to make sure we get different locations
    # and a hedge against infinite loops which should not be possible
    # due to pre-launch study validation.
    i = 0
    while (location1.id == location2.id) && i < 1000
      location2 = self.randomLocation
      i += 1
    end

    [location1, location2]
  end

  def self.search(term)
    q = "%#{term}%"
    Study.joins(:user).where("studies.name like ? or users.username like ?", q, q)
    # Study.where("name like ? or description like ?", q, q)
  end

  def self.random_active(excluded_ids)
    excluded_ids = '' if excluded_ids.blank?
    offset = rand(Study.where(active: true).where('id not in (?)', excluded_ids).count)
    Study.where(active: true).first(offset: offset)
  end

  def self.random_promoted_active(excluded_ids)
    excluded_ids = '' if excluded_ids.blank?
    offset = rand(Study.where(active: true).where(promoted: true).where('id not in (?)', excluded_ids).count)
    Study.where(active: true).where(promoted: true).where('id not in (?)', excluded_ids).first(offset: offset)
  end

  def self.random(excluded_ids)
    study = self.random_promoted_active(excluded_ids)
    study = self.random_active(excluded_ids) if study.blank?
    return study
  end

  def vote_fix_time
    "16/May/2013 09:26:30 -0400".to_datetime
  end

  def comparisons_before_fix
    Comparison.where(["study_id = ? and created_at < ?", self.id, vote_fix_time])
  end

  def results
    result_set = ActiveRecord::Base.connection.exec_query("
    SELECT
      l.id AS location_id,
      l.latitude,
      l.longitude,
      l.heading,
      l.pitch,
      IFNULL(cl.chosen, 0) AS chosen,
      IFNULL(rl.rejected, 0) AS rejected,
      IFNULL(cl.chosen, 0) + IFNULL(rl.rejected, 0) as total_votes,
      CASE
        WHEN IFNULL(cl.chosen, 0) + IFNULL(rl.rejected, 0) > 0 THEN 100 * IFNULL(cl.chosen, 0) / (IFNULL(cl.chosen, 0) + IFNULL(rl.rejected, 0))
        ELSE 0
        END as percent_chosen,
      r.name AS region_name,
      s.slug AS study,
      s.question
    FROM locations l
    LEFT JOIN (
      SELECT
        chosen_location_id as id,
        count(*) as chosen
      FROM comparisons
      WHERE study_id = #{self.id}
      GROUP BY chosen_location_id
    ) cl on cl.id = l.id
    LEFT JOIN (
      SELECT
        rejected_location_id as id,
        count(*) as rejected
      FROM comparisons
      WHERE study_id = #{self.id}
      GROUP BY rejected_location_id
    ) rl on rl.id = l.id
    LEFT JOIN regions r ON r.id = l.region_id
    LEFT JOIN studies s ON s.id = #{self.id}
    WHERE
      l.region_id IN (
        SELECT r.id
        FROM regions r
        JOIN region_set_memberships rsm ON rsm.region_id = r.id
        JOIN region_sets rs on rs.id = rsm.region_set_id
        JOIN studies s on s.region_set_id = rs.id
        WHERE s.id = #{self.id})
    ")
    result_set
  end

  def region_results
    result_set = ActiveRecord::Base.connection.exec_query("
      SELECT
        r.id,
        r.name,
        r.latitude,
        r.longitude,
        r.zoom,
        lc.locations,
        IFNULL(cl.chosen, 0) as chosen,
        IFNULL(rl.rejected, 0) as rejected,
        cl.chosen + rl.rejected as total,
        CASE
          WHEN cl.chosen + rl.rejected > 0 THEN cl.chosen / (cl.chosen + rl.rejected)
          ELSE 0
          END as percent_favored

      FROM regions r
      JOIN region_set_memberships rsm ON rsm.region_id = r.id
      JOIN region_sets rs on rs.id = rsm.region_set_id
      JOIN studies s on s.region_set_id = rs.id
      JOIN (
        SELECT r.id, COUNT(*) as locations
        FROM regions r
        JOIN locations l on l.region_id = r.id
        JOIN region_set_memberships rsm ON rsm.region_id = r.id
        JOIN region_sets rs on rs.id = rsm.region_set_id
        JOIN studies s on s.region_set_id = rs.id
        WHERE s.id=#{self.id}
        GROUP BY r.id
        ) lc on lc.id = r.id
      LEFT JOIN (
        SELECT
          cl.region_id,
          count(*) as chosen
        FROM comparisons c
        JOIN locations cl ON c.chosen_location_id = cl.id
        JOIN locations rl ON c.rejected_location_id = rl.id
        WHERE c.study_id = #{self.id} AND cl.region_id <> rl.region_id
        GROUP BY cl.region_id
      ) cl ON cl.region_id = r.id
      LEFT JOIN (
        SELECT
          rl.region_id,
          count(*) as rejected
        FROM comparisons c
        LEFT JOIN locations cl ON c.chosen_location_id = cl.id
        LEFT JOIN locations rl ON c.rejected_location_id = rl.id
        WHERE c.study_id = #{self.id} AND cl.region_id <> rl.region_id
        GROUP BY rl.region_id
      ) rl ON rl.region_id = r.id
      WHERE s.id=#{self.id}
                                                          ")
  end

  def full_results
    Comparison.includes(:chosen_location, {:chosen_location => :region}, :rejected_location, {:rejected_location => :region}).joins(:chosen_location, {:chosen_location => :region}, :rejected_location, {:rejected_location => :region}).where(:study_id => self.id)
  end

  def to_csv(options = {})
    study_results = self.results
    CSV.generate(options) do |csv|
      csv << study_results.first.keys.push('image_url')
      study_results.each do |location|
        location['image_url'] = "http://maps.googleapis.com/maps/api/streetview?size=470x306&location=#{location['latitude']}%2C#{location['longitude']}&heading=#{location['heading']}&pitch=#{location['pitch']}&sensor=false"
        csv << location.values
      end
    end
  end

  def full_csv(options = {})
    CSV.generate(options) do |csv|
      header = %w(comparison_id date ip_address voter_latitude voter_longitude study question chosen_id chosen_latitude chosen_longitude chosen_pitch chosen_heading chosen_region_name chosen_image_url rejected_id rejected_latitude rejected_longitude rejected_pitch rejected_heading rejected_region_name rejected_image_url)

      if has_survey
        survey = Survey.find(survey_id)
        header += survey.csv_header
      end

      csv << header

      self.full_results.each do |comparison|
        #abort(comparison.to_yaml)
        body =
            [
                comparison.id,
                comparison.created_at,
                comparison.voter_remote_ip,
                comparison.voter_latitude,
                comparison.voter_longitude,
                self.slug,
                self.question,
                comparison.chosen_location.id,
                comparison.chosen_location.latitude,
                comparison.chosen_location.longitude,
                comparison.chosen_location.pitch,
                comparison.chosen_location.heading,
                comparison.chosen_location.region.name,
                comparison.chosen_location.image_url,
                comparison.rejected_location.id,
                comparison.rejected_location.latitude,
                comparison.rejected_location.longitude,
                comparison.rejected_location.pitch,
                comparison.rejected_location.heading,
                comparison.rejected_location.region.name,
                comparison.rejected_location.image_url,
            ]

        body += survey_csv_body(comparison.voter_session_id) if has_survey

        csv << body
      end
    end
  end

  def survey_csv_body(session_id)
    survey_responses.questions_and_answers(session_id).map(&:answer)
  end

end
