class User < ActiveRecord::Base
  devise :invitable, :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable, :invite_for => 1.week
  attr_reader :raw_invitation_token
  
  enum role: [:volunteer, :accompaniment_leader, :admin]
  enum volunteer_type: [:english_speaking, :spanish_interpreter, :lawyer]

  validates :first_name, :last_name, :email, :phone, :volunteer_type, :presence => true
  validates :email, uniqueness: true
  validates_inclusion_of :pledge_signed, :in => [true]

  has_many :user_friend_associations, dependent: :destroy
  has_many :friends, through: :user_friend_associations
  has_many :user_asylum_application_draft_associations, dependent: :destroy
  has_many :asylum_application_drafts, through: :user_asylum_application_draft_associations
  has_many :user_sijs_application_draft_associations, dependent: :destroy
  has_many :sijs_application_drafts, through: :user_sijs_application_draft_associations
  has_many :accompaniments, dependent: :destroy
  has_many :user_event_attendances, dependent: :destroy
  has_many :accompaniment_report_authorships, dependent: :destroy
  has_many :accompaniment_reports, through: :accompaniment_report_authorships

  def volunteer?
  	self.role == 'volunteer'
  end

  def admin?
  	self.role == 'admin'
  end

  def confirmed?
    self.invitation_accepted_at.present?
  end

  def name
    "#{first_name} #{last_name}"
  end

  def attending?(activity)
    activity.volunteers.include?(self)
  end

  def accompaniment_report_for(activity)
    self.accompaniment_reports.where(activity_id: activity.id).first
  end

  def generate_new_invitation
    User.invite!(email: self.email, skip_invitation: true)
    token = self.raw_invitation_token
    domain = ENV['MAILER_DOMAIN']
    "http://#{domain}/users/invitation/accept?invitation_token=#{token}"
  end
end
