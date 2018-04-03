Bundler.require

require './config/init'
require './helpers/user_helper'
require './lib/json_params'


class BaseController < Sinatra::Base
  require './lib/regex_pattern'

  helpers UserAppHelpers
  register Sinatra::JsonBodyParams

  configure do
    enable :protection # https://stackoverflow.com/questions/10509774/sinatra-and-rack-protection-setting
    enable :sessions
    enable :logging

    disable :show_exceptions

    set :template_engine, :haml
    set :root,  Pathname(File.expand_path('../..', __FILE__))
    set :views, 'views'
    set :public_folder, 'public'
    set :static, true
    set :static_cache_control, [:public, max_age: 0]
    set :session_secret, '%1qA2wS3eD4rF5tG6yH7uJ8iK9oL$'
  end


  set :sprockets, Sprockets::Environment.new(root) { |env|
    env.append_path(root.join(public_folder, 'javascripts'))
  }

  set(:auth) do |*roles|
    condition do
      unless logged_in? && roles.any? {|role| set_current_user.in_role? role }
        halt 401, {:response=>'Unauthorized access'}
      end
    end
  end

  set(:validate) do |*params_array|
    condition do
      params_array.any? do |k|
        unless params.key?(k)
          # https://stackoverflow.com/questions/3050518/what-http-status-response-code-should-i-use-if-the-request-is-missing-a-required
          halt 422, {:response=>'Any parameter are empty or null'}.to_json
        end
      end
      true # Return true
    end
  end

  set(:only_owner) do |model|
    condition do
      @model = model[params[:id]] or halt 404
      unless @model.user_id == session[:user]
        halt 401, {:response=>'Unauthorized access'}
      end
    end
  end

end