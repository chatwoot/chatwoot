<% if namespaced? -%>
require_dependency "<%= namespaced_path %>/application_controller"

<% end -%>
<% module_namespacing do -%>
class <%= controller_class_name %>Controller < ApplicationController
  before_action :set_<%= singular_table_name %>, only: %i[ show edit update destroy ]

  # GET <%= route_url %> or <%= route_url %>.json
  def index
    @<%= plural_table_name %> = <%= orm_class.all(class_name) %>
  end

  # GET <%= route_url %>/1 or <%= route_url %>/1.json
  def show
  end

  # GET <%= route_url %>/new
  def new
    @<%= singular_table_name %> = <%= orm_class.build(class_name) %>
  end

  # GET <%= route_url %>/1/edit
  def edit
  end

  # POST <%= route_url %> or <%= route_url %>.json
  def create
    @<%= singular_table_name %> = <%= orm_class.build(class_name, "#{singular_table_name}_params") %>

    respond_to do |format|
      if @<%= orm_instance.save %>
        format.html { redirect_to <%= show_helper %>, notice: <%= %("#{human_name} was successfully created.") %> }
        format.json { render :show, status: :created, location: <%= "@#{singular_table_name}" %> }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: <%= "@#{orm_instance.errors}" %>, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT <%= route_url %>/1 or <%= route_url %>/1.json
  def update
    respond_to do |format|
      if @<%= orm_instance.update("#{singular_table_name}_params") %>
        format.html { redirect_to <%= show_helper %>, notice: <%= %("#{human_name} was successfully updated.") %> }
        format.json { render :show, status: :ok, location: <%= "@#{singular_table_name}" %> }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: <%= "@#{orm_instance.errors}" %>, status: :unprocessable_entity }
      end
    end
  end

  # DELETE <%= route_url %>/1 or <%= route_url %>/1.json
  def destroy
    @<%= orm_instance.destroy %>

    respond_to do |format|
      format.html { redirect_to <%= index_helper %>_url, notice: <%= %("#{human_name} was successfully destroyed.") %> }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_<%= singular_table_name %>
      @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
    end

    # Only allow a list of trusted parameters through.
    def <%= "#{singular_table_name}_params" %>
      <%- if attributes_names.empty? -%>
      params.fetch(<%= ":#{singular_table_name}" %>, {})
      <%- else -%>
      params.require(<%= ":#{singular_table_name}" %>).permit(<%= permitted_params %>)
      <%- end -%>
    end
end
<% end -%>
