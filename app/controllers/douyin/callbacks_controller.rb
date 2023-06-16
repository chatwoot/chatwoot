class Douyin::CallbacksController < ApplicationController
  include DouyinConcern
  include DouyinHelper

  before_action :set_account,
                :set_account_douyin_hook, only: [:bind]

  # 将 open_id 和 account_id 绑定
  def bind
    @access_token_response = post_douyin_access_token(@account_douyin_hook)
    @account_douyin_hook.reference_id = open_id
    @account_douyin_hook.access_token = access_token
    @account_douyin_hook.save!

    redirect_to "/app/accounts/#{account_id}/settings/general"
  end

  private

  def account_id
    params[:state]
  end

  def set_account
    @account = ::Account.find(account_id)
  end

  def set_account_douyin_hook
    @account_douyin_hook = @account.hooks.where(app_id: 'douyin').first
  end

  # 用户在当前应用的唯一标识
  def open_id
    @access_token_response['data']['open_id']
  end

  def access_token
    @access_token_response['data']['access_token']
  end

  # 用户在当前开发者账号下的唯一标识（未绑定开发者账号没有该字段）
  def union_id
    @userinfo_response['data']['union_id']
  end

  def nickname
    @userinfo_response['data']['nickname']
  end

  def avatar
    @userinfo_response['data']['avatar']
  end
end
