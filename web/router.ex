defmodule StressedSyllables.Router do
  use StressedSyllables.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", StressedSyllables do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

   # Other scopes may use custom stacks.
   scope "/api", StressedSyllables do
     pipe_through :api

     scope "/v1" do
       post "/get-stress", ApiController, :get_stress
     end
   end
end
