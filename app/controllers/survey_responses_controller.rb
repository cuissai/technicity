class SurveyResponsesController < ApplicationController
  def create
    @study = Study.find(params[:survey][:study_id])
    @survey = Survey.find(@study.survey_id)

    params[:survey][:session_id] = request.session_options[:id]
    @survey_form = SurveyTakerForm.new(@survey.survey_questions, params[:survey])

    respond_to do |format|
      if @survey_form.save
        session.delete(:homepage_study)
        session.delete(@study.slug.to_sym)
        session[:completed_studies] << @study.id
        format.html { redirect_to home_path, notice: 'Thank you for completing the study!' }
      else
        format.html { redirect_to survey_path(@survey), notice: 'There was an error saving your response. Please try again.' }
      end
    end
  end

  def skip_survey
    session.delete(:homepage_study)
    session.delete(params[:s])
    session[:completed_studies] << params[:s_id]
    redirect_to home_path, notice: 'Thank you for completing the study!'
  end

end
