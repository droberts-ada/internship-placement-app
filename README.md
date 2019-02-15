# Internship Placer

## Setup

1. Install the Ruby listed in `.ruby-version`
2. Upgrade RubyGems to version 3.0:
```sh
gem update --system
```
3. Install Bundler 2:
```sh
gem install bundler
```
4. Install dependencies:
```sh
bundle install
```
5. Start PostgresQL:
```sh
# run "brew install postgres" if not installed.
brew services start postgresql
```
6. Initialize Database:
```sh
rake db:create
rake db:migrate
```
7. Log into typeform.com
  1. Select the form you are using for that cohort.
  2. Click "View" and save the URL in you `.env` file as `TYPEFORM_INTERVIEW_FORM`
  3. Generate a new secret using `rails secret` and save that in your `.env` file as `TYPEFORM_SECRET`.
  4. Put the secret into the form configuration.
    1. Click on "Connect" from the form page.
    2. Click on "Webhooks" and set `https://placement.adadevelopersacademy.org/interviews/feedback?typeform_secret=` using the value you generated as the value for the `typeform_secret` query parameter.
8. Google OAuth
  1. Get permissions from an existing Google Cloud Platform admin.  (They need to go into "IAM & admin" > "IAM" and add you as a "Project Owner".)
  2. Go to [cloud.google.com](https://cloud.google.com).
  3. Click "Console" .  Click "Select a project".  Chose "ADADEVELOPERSACADEMY.ORG" as the organization you are selecting from and pick `ada-placement-prod`.
  4. Click "APIs & Services" and pick "Credentials" from the sidebar.
  5. Click on "Placement App (dev)".
    1. Copy "Client ID" into your `.env` as `GOOGLE_OAUTH_CLIENT_ID`.
    2. Copy the "Client secret" to your `.env` as `GOOGLE_OAUTH_CLIENT_SECRET`.

## Tests

Run the tests with `bundle exec rake`

## Startup

Start the server with `rails s` and verify you can log in with your `@adadevelopersacademy.org` email.

## Heroku Access

To Get Deploy Access:
1. Create a [Heroku](https://heroku.com} account with your '@adadevelopersacademy.org' email.
2. Have an existing admin invite you to the team.

## Deploy

Once you have access to Heroku:
1. Create a PR on Github.
2. Open your [Heroku Dashboard](https://dashboard.heroku.com).
3. Toggle your team in the upper left to `adaacademy`.
4. Click on the `ada-placement` app.  From here you can promote your app to staging (`ada-placement-dev`) and production (`ada-placement-prod`).

## Wishlist
In no particular order:

- Rails server / API work
  - Ability to save a placement
  - Ability to load / copy a placement
  - Ability to see a list of placements
  - Different users / classes have different placements (?)
- Get some real data
  - Needs to be password-protected
- Change history / undo button
- Live collaboration from multiple devices
- General UI/UX improvements
  - Fit more companies on the screen (smaller text, less padding)
  - Show student / company ranking details
  - Better colors
  - Hotkeys?
    - Clear selection
    - Select next unplaced
- Get data into another format
  - Export to CSV
  - Google Docs API integration?
- A real README
  - Setup / installation instructions
- Send emails automatically at the end
