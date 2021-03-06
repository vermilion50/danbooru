class UsersController < ApplicationController
  respond_to :html, :xml, :json
  before_filter :member_only, :only => [:edit, :update, :upgrade]
  rescue_from User::PrivilegeError, :with => :access_denied

  def new
    @user = User.new
    respond_with(@user)
  end

  def edit
    @user = User.find(params[:id])
    check_privilege(@user)
    respond_with(@user)
  end

  def index
    if params[:name].present?
      @user = User.find_by_name(params[:name])
      redirect_to user_path(@user)
    else
      @users = User.search(params[:search]).order("users.id desc").paginate(params[:page], :limit => params[:limit], :search_count => params[:search])
      respond_with(@users) do |format|
        format.xml do
          render :xml => @users.to_xml(:root => "users")
        end
      end
    end
  end

  def search
  end

  def show
    @user = User.find(params[:id])
    @presenter = UserPresenter.new(@user)
    respond_with(@user, :methods => [:wiki_page_version_count, :artist_version_count, :artist_commentary_version_count, :pool_version_count, :forum_post_count, :comment_count, :appeal_count, :flag_count, :positive_feedback_count, :neutral_feedback_count, :negative_feedback_count])
  end

  def create
    @user = User.create(params[:user], :as => CurrentUser.role)
    if @user.errors.empty?
      session[:user_id] = @user.id
    end
    set_current_user
    respond_with(@user)
  end

  def update
    @user = User.find(params[:id])
    check_privilege(@user)
    @user.update_attributes(params[:user].except(:name), :as => CurrentUser.role)
    cookies.delete(:favorite_tags)
    cookies.delete(:favorite_tags_with_categories)
    if @user.errors.any?
      flash[:notice] = @user.errors.full_messages.join("; ")
    else
      flash[:notice] = "Settings updated"
    end
    respond_with(@user)
  end

  def cache
    @user = User.find(params[:id])
    @user.update_cache
    render :nothing => true
  end

private

  def check_privilege(user)
    raise User::PrivilegeError unless (user.id == CurrentUser.id || CurrentUser.is_admin?)
  end
end
