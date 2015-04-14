defmodule Blog.Router do
  use Phoenix.Router

  pipeline :browser do
    plug :accepts, ~w(html)
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
  end

  pipeline :api do
    plug :accepts, ~w(json)
  end

  scope "/", Blog do
    pipe_through :browser # Use the default browser stack

    resources "posts", PostsController
    get "/", PagesController, :index, as: :page

  end

  scope "/users", Blog do
    pipe_through :browser # Use the default browser stack

    get "/sign_up", RegistrationsController, :new, as: :registrations
  end

  # Other scopes may use custom stacks.
  # scope "/api", MyApp do
  #   pipe_through :api
  # end
end
