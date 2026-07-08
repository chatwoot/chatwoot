class SuperAdmin::ProspectingScoringProfilesController < SuperAdmin::ApplicationController
  def index
    Autonomia::Prospecting::ScoringProfile.default_profile
    @profiles = Autonomia::Prospecting::ScoringProfile.order(default: :desc, name: :asc)
  end

  def new
    @profile = Autonomia::Prospecting::ScoringProfile.new(
      name: 'Novo perfil',
      weights: Autonomia::Prospecting::ScoringProfile::DEFAULT_WEIGHTS
    )
  end

  def edit
    @profile = profile
  end

  def create
    @profile = Autonomia::Prospecting::ScoringProfile.new(profile_attributes)
    @profile.created_by = current_super_admin
    @profile.updated_by = current_super_admin
    save_profile!

    redirect_to super_admin_prospecting_scoring_profiles_path, notice: 'Prospecting scoring profile created'
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def update
    @profile = profile
    @profile.assign_attributes(profile_attributes)
    @profile.updated_by = current_super_admin
    save_profile!

    redirect_to super_admin_prospecting_scoring_profiles_path, notice: 'Prospecting scoring profile updated'
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  def destroy
    current_profile = profile
    if current_profile.default? && Autonomia::Prospecting::ScoringProfile.where.not(id: current_profile.id).none?
      return redirect_to super_admin_prospecting_scoring_profiles_path,
                         alert: 'Create another profile before deleting the default profile'
    end

    current_profile.destroy!
    ensure_default_profile!
    redirect_to super_admin_prospecting_scoring_profiles_path, notice: 'Prospecting scoring profile deleted'
  end

  private

  def profile
    Autonomia::Prospecting::ScoringProfile.find(params[:id])
  end

  def profile_attributes
    profile_params = params.require(:autonomia_prospecting_scoring_profile)

    {
      name: profile_params[:name],
      default: ActiveModel::Type::Boolean.new.cast(profile_params[:default]),
      weights: scoring_weights_param
    }
  end

  def scoring_weights_param
    permitted = params.require(:autonomia_prospecting_scoring_profile).permit(
      weights: Autonomia::Prospecting::ScoringProfile::DEFAULT_WEIGHTS.keys
    )
    permitted.fetch(:weights, {}).to_h
  end

  def save_profile!
    ActiveRecord::Base.transaction do
      if @profile.default?
        Autonomia::Prospecting::ScoringProfile.where.not(id: @profile.id).update_all(default: false)
      elsif Autonomia::Prospecting::ScoringProfile.where(default: true).where.not(id: @profile.id).none?
        @profile.default = true
      end

      @profile.save!
    end
  end

  def ensure_default_profile!
    return if Autonomia::Prospecting::ScoringProfile.where(default: true).exists?

    Autonomia::Prospecting::ScoringProfile.order(:name).first&.update!(default: true)
  end
end
