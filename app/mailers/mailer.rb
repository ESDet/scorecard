class Mailer < ActionMailer::Base
  default :from => "esd@makeloveland.com"
  @@admins = [ 'larry@makeloveland.com', 'jerry@makeloveland.com', 'mary@makeloveland.com' ]
  
  private  
  
  def tag(str)
    "[ESD#{Rails.env == 'production' ? '' : (' ' + Rails.env)}] #{str}"
  end
  def category(c)
    headers({ 'X-SMTPAPI' => { 'category' => "esd_#{Rails.env}_#{c}" }.to_json })
  end


end
