# Robots

The backend of an online singleplayer and multiplayer version of the popular board game
Ricochet Robots designed by Alex Randolph. Can be used in conjunction with this frontend:
https://github.com/ovedanner/robots.

## Design
The application's main models are Users, Access Tokens, Rooms, Games and Boards. Users can be created in
two ways:
* Through `POST /users`
* By providing a valid Google authorization code to `POST /access_tokens`

In the second case, when the application retrieves user information from google, if the email address
does not exist yet, the user is created. Access tokens can be created using username / password
or Google OAuth.

Users can join rooms. The owner of the room can initiate a game with a board. Boards are randomly
generated. Games are created and interacted with through Websockets (ActionCable). This was done
for learning purposes, but also because the game is quite interactive and everybody in
the room needs to be notified of actions. 

A user can only join the game
channel when he is a member of the room. Whenever the owner of the room leaves the game channel, 
the room (and the game along with it) is destroyed. I'm still working on something better :P. 
There is also a separate chat channel for every room.

## Dependencies
The project runs on the following:
* Ruby 2.5.3
* Rails 5.2.1
* PostgreSQL 9-ish
* Docker (17-ish) and Docker Compose (1.23-ish) (optional) 
* AWS CLI 1.17 (if you want to deploy to ECS)

## Development
Install `bundler` and run `bundle install` in the project root folder. Next, create
a `.env` file in the project root folder and specify the following env vars:
* POSTGRES_USER
* POSTGRES_PASSWORD
* POSTGRES_HOST
* POSTGRES_DB
* POSTGRES_TEST_DB
* GOOGLE_KEY
* GOOGLE_SECRET
* GOOGLE_REDIRECT_URI
* REDIS_HOST
* REDIS_PORT

The GOOGLE env vars only need to be specified if you want authentication using Google
OAuth. 

If you're going to develop using Docker and Docker Compose, you can set
POSTGRES_HOST to `db`, POSTGRES_USER to `postgres` and POSTGRES_PASSWORD to empty.
Running `docker-compose up -d` should do the trick. If you want a reverse proxy
in front of puma, you can also add a `web` section to `docker-compose.yml` and point
the `build` directive to `./docker/web/Dockerfile`. Don't forget to expose port 80!

If you don't want to develop using Docker, you can simply run `bundle exec puma`.

## Tests
Test cases are made with RSpec, so running `rspec` in the project root folder should do
the trick

## Deployment
There is a simple sample deploy script (`deploy.sh`) that builds the appropriate Docker image
and pushes it to an AWS ECS repository. Don't forget to set the right variables for the
repository URL, cluster and service.
