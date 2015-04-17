class RequestsController < ApplicationController
  def index
    conditions = { agency_responsible: @user.field_service_team, negation: "agency_responsible" }
    conditions[:service_request_id] = params[:ids].join(",") if params[:ids]
    if (center = params[:center]).present?
      conditions.update lat: center[0], long: center[1]
    end
    conditions[:radius] = params[:radius] if params[:radius]
    @requests = Request.where(conditions).try(:to_a)
    respond_to do |format|
      format.html { head :forbidden }
      format.js
      format.json { render json: @requests }
    end
  end

  def show
    return head(:not_found) unless (id = params[:id]).present?
    @request = Request.find(id)
  end

  def edit
    return head(:not_found) unless (id = params[:id]).present?
    @request = Request.find(id)
  end

  def update
    return head(:not_found) unless (id = params[:id]).present?
    req = Request.find(id)
    result = Request.patch(
      req.id, params.require(:request).
      permit(:service_code, :detailed_status, :title, :description).
      merge(api_key: Request.api_key, email: @user.email))
    if result.is_a?(Net::HTTPOK)
      @redirect = request_path(req)
      @success = I18n.t('messages.success.request_update')
    else
      @errors = result.errors
    end
  end
end
