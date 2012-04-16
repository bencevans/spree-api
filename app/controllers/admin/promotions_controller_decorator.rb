Admin::PromotionsController.class_eval do
  $e1={"status_code"=>"500","status_message"=>"Your request parameters are incorrect."}
$e2={"status_code"=>"500","status_message"=>"Record not found"}
$e3={"status_code"=>"500","status_message"=>"Payment failed check the details entered"}
$e4={"status_code"=>"200","status_message"=>"destroyed"}
$e5={"status_code"=>"202","status_message"=>"Undefined method request check the url"}
require 'spree_core/action_callbacks'
  before_filter :check_http_authorization
  before_filter :load_resource
  skip_before_filter :verify_authenticity_token, :if => lambda { admin_token_passed_in_headers }
  authorize_resource
  attr_accessor :parent_data
  attr_accessor :callbacks
  helper_method :new_object_url, :edit_object_url, :object_url, :collection_url
 # respond_to :html
  respond_to :js, :except => [:show, :index]
   def index
     if !params[:format].nil? && params[:format] == "json"
					respond_with(@collection) do |format|
      format.html
      format.json { render :json => @collection}
    end
    end
  end
  def show
  if !params[:format].nil? && params[:format] == "json"
    respond_with(@object) do |format|
      format.json { render :json => @object.to_json(object_serialization_options) }
    end
    end
   end


  def create
    p "i am in api method"
    if !params[:format].nil? && params[:format] == "json"
    begin
    if @object.save
     render :json => @object.to_json, :status => 201
      else
       error = error_response_method($e1)
      render :json => error
    end
    rescue Exception=>e
     render :text => "#{e.message}", :status => 500
   end
   else
     invoke_callbacks(:create, :before)
     p @object
    if @object.save
     if controller_name == "taxonomies"
       @object.create_image(:attachment=>params[:taxon][:attachement])
    end
      invoke_callbacks(:create, :after)
      flash[:notice] = flash_message_for(@object, :successfully_created)
      respond_with(@object) do |format|
        format.html { redirect_to location_after_save }
        format.js   { render :layout => false }
      end
    else
      invoke_callbacks(:create, :fails)
      respond_with(@object)
    end
   end
  end

  def update
    if !params[:format].nil? && params[:format] == "json"
    begin
      if @object.update_attributes(params[object_name])
          render :json => @object.to_json, :status => 201
    else
      error = error_response_method($e1)
      render :json => error
      #respond_with(@object.errors, :status => 422)
    end
     rescue Exception=>e
     render :text => "#{e.message}", :status => 500
   end
   else
     p "i came inside"
      invoke_callbacks(:update, :before)
     if controller_name == "taxonomies"
    @image_object=@object.image
    @image_object.update_attributes(:attachment => params[:taxon][:attachement])
    end

    if @object.update_attributes(params[object_name])
     invoke_callbacks(:update, :after)
      flash[:notice] = flash_message_for(@object, :successfully_updated)
      respond_with(@object) do |format|
        format.html { redirect_to location_after_save }
        format.js   { render :layout => false }
      end
    else
      invoke_callbacks(:update, :fails)
      respond_with(@object)
    end
    end

    end
   def destroy
if !params[:format].nil? && params[:format] == "json"
@object=Promotion.find_by_id(params[:id])
if !@object.nil?
@object.destroy
if @object.destroy
   render :text => 'Destroyed' 
 end
else 
  error=error_response_method($e2)
        render:json=>error
        end
      else
          invoke_callbacks(:destroy, :before)
    if @object.destroy
      invoke_callbacks(:destroy, :after)
      flash[:notice] = flash_message_for(@object, :successfully_removed)
      respond_with(@object) do |format|
        format.html { redirect_to collection_url }
        format.js   { render :partial => "/admin/shared/destroy" }
      end
    else
      invoke_callbacks(:destroy, :fails)
      respond_with(@object) do |format|
        format.html { redirect_to collection_url }
      end
    end
    end
  end
 
  def admin_token_passed_in_headers
     if !params[:format].nil? && params[:format] == "json"
    request.headers['HTTP_AUTHORIZATION'].present?
    end
  end

  def access_denied
    if !params[:format].nil? && params[:format] == "json"
    render :text => 'access_denied', :status => 401
  end
  end

  # Generic action to handle firing of state events on an object
  def event
    if !params[:format].nil? && params[:format] == "json"
    valid_events = model_class.state_machine.events.map(&:name)
    valid_events_for_object = @object ? @object.state_transitions.map(&:event) : []

    if params[:e].blank?
      errors = t('api.errors.missing_event')
    elsif valid_events_for_object.include?(params[:e].to_sym)
      @object.send("#{params[:e]}!")
      errors = nil
    elsif valid_events.include?(params[:e].to_sym)
      errors = t('api.errors.invalid_event_for_object', :events => valid_events_for_object.join(','))
    else
      errors = t('api.errors.invalid_event', :events => valid_events.join(','))
    end

    respond_to do |wants|
      wants.json do
        if errors.blank?
          render :nothing => true
        else
          #error = error_response_method($e10001)
          render :json => errors.to_json, :status => 422
          #render :json => error
        end
      end
    end
  end
  end

  def error_response_method(error)
    if !params[:format].nil? && params[:format] == "json"
    @error = {}
    @error["code"]=error["status_code"]
    @error["message"]=error["status_message"]
    #@error["Code"] = error["error_code"]
    return @error
    end
  end

  protected
    def find_resource
      if !params[:format].nil? && params[:format] == "json"
      begin
        if parent.present?
          parent.send(controller_name).find(params[:id])
      else
        model_class.includes(eager_load_associations).find(params[:id])
      end
      rescue Exception => e
    render :text => "Resource not found (#{e.message})", :status => 500
  end
  else
  if parent_data.present?
      parent.send(controller_name).find(params[:id])
    else
      model_class.find(params[:id])
    end
  end
    end
    def collection
       if !params[:format].nil? && params[:format] == "json"
          return @search unless @search.nil?      
      params[:search] = {} if params[:search].blank?
      params[:search][:meta_sort] = 'created_at.desc' if params[:search][:meta_sort].blank?
      
      scope = parent.present? ? parent.send(controller_name) : model_class.scoped
     
      @search = scope.metasearch(params[:search]).relation.limit(100)
      @search
    else
		 params[:search] ||= {}
    params[:search][:meta_sort] ||= "ascend_by_name"
    @search = super.metasearch(params[:search])
    @zones = @search.paginate(:per_page => Spree::Config[:orders_per_page], :page => params[:page])
		end
    end

    def collection_serialization_options
     if !params[:format].nil? && params[:format] == "json"
      {}
      end
    end

    def object_serialization_options
       if !params[:format].nil? && params[:format] == "json"
      {}
      end
    end

    def eager_load_associations
       if !params[:format].nil? && params[:format] == "json"
      nil
      end
    end

    def object_errors
       if !params[:format].nil? && params[:format] == "json"
      {:errors => object.errors.full_messages}
      end
    end
  def object_url(object = nil, options = {})
     if !params[:format].nil? && params[:format] == "json"
      target = object ? object : @object
      if parent.present? && object_name == "state"
          send "api_country_#{object_name}_url", parent, target, options
      elsif parent.present? && object_name == "taxon"
          send "api_taxonomy_#{object_name}_url", parent, target, options
      elsif parent.present?
          send "api_#{parent[:model_name]}_#{object_name}_url", parent, target, options
      else
        send "api_#{object_name}_url",parent, target, options
      end
      else
          target = object ? object : @object
    if parent_data.present?
      send "admin_#{parent_data[:model_name]}_#{object_name}_url", parent, target, options
    else
      send "admin_#{object_name}_url", target, options
    end
      end
    end
     def collection_url(options = {})
    if parent_data.present?
      polymorphic_url([:admin, parent, model_class], options)
    else
      polymorphic_url([:admin, model_class], options)
    end
  end
  private
  def check_http_authorization
         if !params[:format].nil? && params[:format] == "json"
      if current_user.authentication_token!=params[:authentication_token]
        render :text => "Access Denied\n", :status => 401
    end if current_user
  end
end  
end