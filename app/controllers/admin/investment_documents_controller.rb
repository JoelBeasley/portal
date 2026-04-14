class Admin::InvestmentDocumentsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def new
    load_form_collections
  end

  def create
    uploads = Array(params[:files]).reject(&:blank?)
    @document_type = params[:document_type].to_s
    @custom_document_type = params[:custom_document_type].to_s.strip
    mappings = normalize_mappings(params[:mappings])
    load_form_collections

    if uploads.empty?
      flash.now[:alert] = "Please choose one or more files to import."
      render :new, status: :unprocessable_entity
      return
    end

    unless InvestmentDocument.document_types.key?(@document_type)
      flash.now[:alert] = "Please choose a valid document type."
      render :new, status: :unprocessable_entity
      return
    end

    if @document_type == "custom" && @custom_document_type.blank?
      flash.now[:alert] = "Please enter a custom document type name."
      @pending_mappings = build_pending_mappings_for_view(uploads, mappings)
      render :new, status: :unprocessable_entity
      return
    end

    if mappings.size != uploads.size
      flash.now[:alert] = "Please map each selected file to an investor and investment."
      @pending_mappings = build_pending_mappings_for_view(uploads, mappings)
      render :new, status: :unprocessable_entity
      return
    end

    if mappings.any? { |m| m[:user_id].blank? || m[:investment_id].blank? }
      flash.now[:alert] = "Every selected file needs both an investor and an investment."
      @pending_mappings = build_pending_mappings_for_view(uploads, mappings)
      render :new, status: :unprocessable_entity
      return
    end

    records_to_save = []
    errors = []

    uploads.each_with_index do |upload, idx|
      mapping = mappings[idx] || {}
      user = User.find_by(id: mapping[:user_id])
      investment = Investment.find_by(id: mapping[:investment_id])

      record = InvestmentDocument.new(
        user: user,
        investment: investment,
        document_type: @document_type,
        custom_document_type: (@document_type == "custom" ? @custom_document_type : nil)
      )
      record.file.attach(upload)

      unless record.valid?
        filename = upload.original_filename.presence || "file"
        errors << "#{filename}: #{record.errors.full_messages.to_sentence}"
        next
      end

      records_to_save << record
    end

    if errors.any?
      @import_errors = errors
      @pending_mappings = build_pending_mappings_for_view(uploads, mappings)
      flash.now[:alert] = "#{errors.size} document(s) failed to import."
      render :new, status: :unprocessable_entity
      return
    end

    InvestmentDocument.transaction do
      records_to_save.each(&:save!)
    end

    redirect_to new_admin_investment_document_path,
                notice: "#{records_to_save.size} document(s) imported successfully."
  end

  private

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_user.can_access_admin_area?
  end

  def load_form_collections
    @users = User.where(role: [:investor, :admin, :super_admin]).order(:email)
    @investments = Investment.includes(:user, :project).order(created_at: :desc)
    @document_type_options = [
      ["K-1", "k1"],
      ["KYC", "kyc"],
      ["NDA", "nda"],
      ["Subscription Document", "subscription_document"],
      ["Custom", "custom"]
    ]
  end

  def normalize_mappings(raw_mappings)
    return [] if raw_mappings.blank?

    mappings_hash =
      if raw_mappings.respond_to?(:to_unsafe_h)
        raw_mappings.to_unsafe_h
      elsif raw_mappings.respond_to?(:to_h)
        raw_mappings.to_h
      else
        raw_mappings
      end

    mappings_hash
      .sort_by { |idx, _| idx.to_i }
      .map do |_idx, attrs|
        {
          user_id: attrs[:user_id].to_s,
          investment_id: attrs[:investment_id].to_s
        }
      end
  end

  def build_pending_mappings_for_view(uploads, mappings)
    uploads.each_with_index.map do |upload, idx|
      {
        filename: upload.original_filename.to_s,
        user_id: mappings[idx]&.dig(:user_id).to_s,
        investment_id: mappings[idx]&.dig(:investment_id).to_s
      }
    end
  end
end
