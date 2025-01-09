defmodule TamedWildsWeb.Router do
  use TamedWildsWeb, :router

  import TamedWildsWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TamedWildsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TamedWildsWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/", TamedWildsWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :exploration_live,
      on_mount: [{TamedWildsWeb.UserAuth, :ensure_authenticated}] do
      live "/exploration_live", ExplorationLive
    end

    scope "/exploration" do
      get "/", ExplorationController, :index
      post "/explore", ExplorationController, :explore
      post "/attack", ExplorationController, :attack
      post "/kill", ExplorationController, :kill
      post "/tame", ExplorationController, :tame

      scope "/companion" do
        post "/send_to_camp", ExplorationController, :send_companion_to_camp
      end

      scope "/taming" do
        post "/feed", ExplorationController, :taming_feed
        post "/cancel", ExplorationController, :taming_cancel
      end

      # TODO: Remove this
      post "/regenerate", ExplorationController, :regenerate
    end

    scope "/character" do
      get "/", CharacterController, :index

      scope "/attributes" do
        post "/spend_point", CharacterController, :spend_attribute_point
        post "/reset_points", CharacterController, :reset_attribute_points
      end
    end

    scope "/inventory" do
      get "/", InventoryController, :index
    end

    scope "/camp" do
      get "/", CampController, :index
      post "/construct", CampController, :construct

      scope "/stoneheart" do
        get "/", Camp.StoneheartController, :index
        post "/choose_companion", Camp.StoneheartController, :choose_companion
        post "/leave_companion", Camp.StoneheartController, :leave_companion

        scope "/creatures/:creature_id" do
          get "/", Camp.StoneheartController, :show_creature

          scope "/attributes" do
            post "/spend_point", Camp.StoneheartController, :spend_creature_attribute_point
            post "/reset_points", Camp.StoneheartController, :reset_creature_attribute_points
          end
        end
      end

      scope "/campfire" do
        get "/", Camp.CampfireController, :index
        post "/craft", Camp.CampfireController, :craft
      end
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", TamedWildsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:tamed_wilds, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TamedWildsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", TamedWildsWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{TamedWildsWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", TamedWildsWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{TamedWildsWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", TamedWildsWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{TamedWildsWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
