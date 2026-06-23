class Users::PasswordsController < Devise::PasswordsController
  include ManagesInvestmentBitcoinAddresses

  def edit
    super
    prepare_welcome_bitcoin_setup(user_from_reset_token_param)
  end

  def update
    @submitted_bitcoin_addresses = investment_bitcoin_address_params

    if welcome_bitcoin_setup?(user_from_reset_token_param)
      update_with_welcome_bitcoin
    else
      update_with_standard_reset
    end
  end

  private

  def update_with_standard_reset
    self.resource = resource_class.reset_password_by_token(resource_params)

    if resource.errors.empty?
      complete_successful_password_reset
    else
      set_minimum_password_length
      respond_with(resource)
    end
  end

  def update_with_welcome_bitcoin
    user = user_from_reset_token_param
    unless user&.persisted?
      self.resource = resource_class.reset_password_by_token(resource_params)
      set_minimum_password_length
      render :edit, status: :unprocessable_entity
      return
    end

    @investment_bitcoin_errors = validate_investment_bitcoin_addresses(user, @submitted_bitcoin_addresses)
    if @investment_bitcoin_errors.any?
      self.resource = user
      resource.reset_password_token = resource_params[:reset_password_token]
      prepare_welcome_bitcoin_setup
      set_minimum_password_length
      render :edit, status: :unprocessable_entity
      return
    end

    self.resource = resource_class.reset_password_by_token(resource_params)
    if resource.errors.empty?
      apply_investment_bitcoin_addresses!(resource, @submitted_bitcoin_addresses)
      mark_welcome_password_set!
      complete_successful_password_reset
    else
      prepare_welcome_bitcoin_setup if welcome_bitcoin_setup?
      set_minimum_password_length
      render :edit, status: :unprocessable_entity
    end
  end

  def complete_successful_password_reset
    resource.unlock_access! if unlockable?(resource)
    if sign_in_after_reset_password?
      flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
      set_flash_message!(:notice, flash_message)
      resource.after_database_authentication
      sign_in(resource_name, resource)
    else
      set_flash_message!(:notice, :updated_not_active)
    end
    respond_with(resource, location: after_resetting_password_path_for(resource))
  end

  def user_from_reset_token_param
    token = params[:reset_password_token].presence || resource_params[:reset_password_token]
    return if token.blank?

    digest = Devise.token_generator.digest(resource_class, :reset_password_token, token)
    resource_class.find_by(reset_password_token: digest)
  end

  def welcome_bitcoin_setup?(user = resource)
    user&.persisted? && user.investor? && user.welcome_password_set_at.blank?
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
