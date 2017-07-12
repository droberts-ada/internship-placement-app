class User < ApplicationRecord
  has_many :classrooms
  has_many :placements
  validates :name, presence: true

  # Must have an email, and email must end with
  # @adadevelopersacademy.org
  validates :email, presence: true, format: { with: /.+@adadevelopersacademy\.org\z/, message: "Must be a valid email address under the adadevelopersacademy.org domain" }
  def self.from_omniauth(auth)
    # Check if the user already exists
    user = User.find_by(oauth_provider: auth.provider, oauth_uid: auth.uid)
    if user
      # TODO: figure out how to actually refresh the auth token
      user.oauth_token = auth.credentials.token
      user.refresh_token ||= auth.credentials.refresh_token
      user.token_expires_at = Time.at(auth.credentials.expires_at)
      user.save!
      return user
    end

    # No match -> create a new user
    user = User.new
    user.oauth_provider = auth.provider
    user.oauth_uid = auth.uid
    user.name = auth.info.name
    user.email = auth.info.email
    user.oauth_token = auth.credentials.token
    user.refresh_token = auth.credentials.refresh_token
    user.token_expires_at = Time.at(auth.credentials.expires_at)
    user.save
    return user
  end

end
