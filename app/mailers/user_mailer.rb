class UserMailer < ApplicationMailer
  default from: 'notifications@robots.com'

  def welcome_email
    @user = params[:user]
    @url = 'https://robots.themaclipper.nl'
    mail(to: @user.email, subject: 'Welcome to Robots!')
  end
end
