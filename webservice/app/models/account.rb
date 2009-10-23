# generated by technoweenie's restful-authentication:
# http://github.com/technoweenie/restful-authentication/tree/master

require 'rubygems'
require 'session'

require "rpam"
require 'digest/sha1'

class Account < ActiveRecord::Base
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :login
  validates_presence_of     :password,                   :if => :password_required?
  validates_length_of       :password, :within => 1..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 1..40
  validates_uniqueness_of   :login, :case_sensitive => false
  before_save :encrypt_password
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :password

  # Authenticates a user by their login name and unencrypted password with unix2_chkpwd
  def self.unix2_chkpwd(login, passwd)
     return false if login.match "'" or login.match /\\$/ #don't allow ' or \ in login to prevent security issues
     cmd = "/sbin/unix2_chkpwd rpam '#{login}'"
     se = Session.new
     result, err = se.execute cmd, :stdin => passwd #password needn't pt be escaped as it is on stdin
     return (se.get_status == 0)
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, passwd)
     # try rPAM first
     granted = authpam(login, passwd) rescue false         #much more faster
     # then chkpwd second
     granted = unix2_chkpwd(login, passwd) unless granted  #slowly but need no more additional PAM rights
     return nil unless granted
     # find/create the correspoding account record
     acc = find_by_login(login)
     unless acc
       acc = Account.new
       acc.login = login
     end
     @password = passwd
     acc.password = passwd   # Uh, oh, this saves a cleartext password ?!
     acc.save
     return acc
  end

  # Encrypts some data with the salt.
  def self.encrypt(data, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{data}--")
  end

  # Encrypts the data with the user salt
  def encrypt(data)
    self.class.encrypt(data, salt)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
#    remember_me_for 2.weeks
    remember_me_for 1.days
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{login}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    end
      
    def password_required?
      !password.blank?
    end
    
    
end
