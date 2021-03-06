class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :blocked?

  def blocked?
    if current_user.present? && current_user.blocked?
      sign_out current_user
      flash[:error] = "This account has been suspended...."
      redirect_to '/'
    end
  end

  protected

  # Authorization
  def require_model_ownership(model)
    result = model.find(params[:id])

    if result.user != current_user
      respond_to do |format|
        format.html { redirect_to model, alert: "You can only modify your own #{model.to_s.titleize.pluralize}." }
      end
    end
    result
  end

  def trigger_403(message)
    respond_to do |format|
      format.html {
        redirect_to :controller=>'static_pages', :action => 'denied'
      }
    end
  end
end
