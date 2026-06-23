class Users::PasswordsController < Devise::PasswordsController
  include ManagesInvestmentBitcoinAddresses
  def edit
    super
    prepare_welcome_bitcoin_setup(user_from_reset_token_param)
  end

  def update
    @submitted_bitcoin_addresses = investment_bitcoin_address_params
    self.resource = load_resource_from_reset_token
    password_valid = validate_password_without_save(resource)

    bitcoin_errors = {}
    if password_valid && welcome_bitcoin_setup?
      prepare_welcome_bitcoin_setup
      bitcoin_errors = validate_investment_bitcoin_addresses(resource, @submitted_bitcoin_addresses)
    end

    if password_valid && bitcoin_errors.empty?
      save_password_and_bitcoin_addresses
    else
      @investment_bitcoin_errors = bitcoin_errors
      prepare_welcome_bitcoin_setup if welcome_bitcoin_setup?
      set_minimum_password_length
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_from_reset_token_param
    token = params[:reset_password_token].presence || resource_params[:reset_password_token]
    return if token.blank?

    digest = Devise.token_generator.digest(resource_class, :reset_password_token, token)
    resource_class.find_by(reset_password_token: digest)
  end

  def load_resource_from_reset_token
    token = resource_params[:reset_password_token]
    digest = Devise.token_generator.digest(resource_class, :reset_password_token, token)
    user = resource_class.find_or_initialize_with_error_by(:reset_password_token, digest)

    if user.persisted? && !user.reset_password_period_valid?
      user.errors.add(:reset_password_token, :expired)
    end

    user.reset_password_token = token if user.reset_password_token.present?
    user
  end

  def validate_password_without_save(user)
    password = resource_params[:password]
    confirmation = resource_params[:password_confirmation]

    if password.blank?
      user.errors.add(:password, :blank)
      return false
    end

    user.password = password
    user.password_confirmation = confirmation
    user.valid?
  end

  def save_password_and_bitcoin_addresses
    success = false

    ActiveRecord::Base.transaction do
      unless resource.reset_password(resource_params[:password], resource_params[:password_confirmation])
        raise ActiveRecord::Rollback
      end

      apply_investment_bitcoin_addresses!(resource, @submitted_bitcoin_addresses) if welcome_bitcoin_setup?
      mark_welcome_password_set!
      success = true
    end

    if success && resource.errors.empty?
      resource.unlock_access! if unlockable?(resource)
      if sign_in_after_reset_password?
        flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
        set_flash_message!(:notice, flash_message)
        resource.after_database_authentication
        sign_in(resource_name, resource)
      else
        set_flash_message!(:notice, :updated_not_active)
      end
      respond_with resource, location: after_resetting_password_path_for(resource)
    else
      set_minimum_password_length
      prepare_welcome_bitcoin_setup if welcome_bitcoin_setup?
      render :edit, status: :unprocessable_entity
    end
  end

  def welcome_bitcoin_setup?(user = resource)
    user&.investor? && user.welcome_password_set_at.blank?
  end

  def prepare_welcome_bitcoin_setup(user = resource)
    return unless welcome_bitcoin_setup?(user)

    @welcome_bitcoin_investments = user.investments_missing_bitcoin_address
  end

  def mark_welcome_password_set!
    return unless resource.respond_to?(:welcome_password_set_at)
    return if resource.welcome_password_set_at.present?

    resource.update_column(:welcome_password_set_at, Time.current)
  end
end
