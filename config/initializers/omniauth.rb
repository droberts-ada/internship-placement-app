Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
      ENV["GOOGLE_OAUTH_CLIENT_ID"],
      ENV["GOOGLE_OAUTH_CLIENT_SECRET"],
      {
        scope: 'email profile spreadsheets drive',
        access_type: 'offline',
        approval_prompt: 'force',
        hd: 'adadevelopersacademy.org' # Note: not secure, still need to check domain at user create time
      }
end
