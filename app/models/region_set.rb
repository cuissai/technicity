class RegionSet < ActiveRecord::Base
  attr_accessible :name, :public, :slug, :user_id

  has_many :regions, :through => :region_set_memberships
  belongs_to :user

  # Returns true if this is editable by the current user
  def editable?
    User::current_id == self.user_id
  end

end
