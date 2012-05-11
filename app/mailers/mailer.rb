class Mailer < ActionMailer::Base
  default :from => "STARTER@makeloveland.com"
  @@admins = [ 'larry@makeloveland.com', 'jerry@makeloveland.com', 'mary@makeloveland.com' ]
  
  private  
  
  def tag(str)
    "[STARTER#{Rails.env == 'production' ? '' : (' ' + Rails.env)}] #{str}"
  end
  def category(c)
    headers({ 'X-SMTPAPI' => { 'category' => "STARTER_#{Rails.env}_#{c}" }.to_json })
  end


end
