class Api::V1::Accounts::CampaignsController < Api::V1::Accounts::BaseController
  before_action :campaign, except: [:index, :create, :preview_audience]
  before_action :check_authorization

  RESULTS_PER_PAGE = 25

  def index
    @campaigns = Current.account.campaigns
  end

  def show; end

  def create
    @campaign = Current.account.campaigns.create!(campaign_params)
  end

  def update
    @campaign.update!(campaign_params)
  end

  def destroy
    @campaign.destroy!
    head :ok
  end

  def preview_audience
    preview_params = params[:campaign].presence || params
    inbox = Current.account.inboxes.find(preview_params[:inbox_id])
    render json: Campaigns::AudiencePreviewService.new(
      account: Current.account,
      inbox: inbox,
      audience: preview_params[:audience]
    ).perform
  end

  def export_recipients
    scope = @campaign.campaign_recipients.includes(:contact).order(id: :asc)
    scope = scope.where(status: params[:status]) if params[:status].present?
    q = params[:q].to_s.strip
    if q.present?
      scope = scope.left_joins(:contact).where(
        'campaign_recipients.phone_number ILIKE :q OR contacts.name ILIKE :q',
        q: "%#{ActiveRecord::Base.sanitize_sql_like(q)}%"
      )
    end

    headers = %w[contact_name phone_number status error_code error_title error_message sent_at delivered_at read_at failed_at]
    rows = scope.map do |row|
      [
        row.contact&.name.to_s,
        row.phone_number.presence || row.contact&.phone_number.to_s,
        row.status.to_s,
        row.error_code.to_s,
        row.error_title.to_s,
        row.error_message.to_s,
        row.sent_at&.iso8601,
        row.delivered_at&.iso8601,
        row.read_at&.iso8601,
        row.failed_at&.iso8601
      ]
    end

    export_format = params[:export_format].to_s.downcase == 'xlsx' ? 'xlsx' : 'csv'
    if export_format == 'xlsx'
      package = Axlsx::Package.new
      package.workbook.add_worksheet(name: 'Recipients') do |sheet|
        types = Array.new(headers.length, :string)
        sheet.add_row headers
        rows.each { |row| sheet.add_row row, types: types }
      end
      send_data(
        package.to_stream.read,
        filename: "campaign_#{@campaign.display_id}_recipients.xlsx",
        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        disposition: 'attachment'
      )
    else
      csv = CSV.generate do |out|
        out << headers
        rows.each do |row|
          out << [row[0], "\t#{row[1]}", *row[2..]]
        end
      end
      send_data(
        "\xEF\xBB\xBF#{csv}",
        filename: "campaign_#{@campaign.display_id}_recipients.csv",
        type: 'text/csv',
        disposition: 'attachment'
      )
    end
  end

  private

  def campaign
    @campaign ||= Current.account.campaigns.find_by!(display_id: params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(:title, :description, :message, :enabled, :trigger_only_during_business_hours,
                                     :inbox_id, :sender_id, :scheduled_at, :campaign_status,
                                     audience: [:type, :id], trigger_rules: {}, template_params: {})
  end
end
