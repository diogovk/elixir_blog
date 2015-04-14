defmodule BlogTest do
  use ExUnit.Case
  use PlugHelper
  use EctoHelper

  import Blog.Router.Helpers
  import Phoenix.Controller
  import Blog.Authenticable

  alias Blog.Post
  alias Blog.User
  alias Blog.Repo

  def should_be_authenticated!(%Plug.Conn{} = conn) do
    conn = request(conn)
    assert get_flash(conn, :alert) == "You must be authenticated to proceed"
    assert conn.status == 302
  end

  def should_be_unauthenticated!(%Plug.Conn{} = conn, user \\ create_user) do
    conn = sign_in(conn, user)
    conn = request(conn)
    assert get_flash(conn, :alert) == "You're already logged in"
    assert conn.status == 302
  end

  def create_user do
    Repo.insert(User.changeset(%User{}, %{ email: "foo@bar.com", password: "master123", password_confirmation: "master123" }))
  end

  def create_post do
    Repo.insert(%Post{ title: "hello", content: "world" })
  end

  test "PostsController GET index" do
    conn = request(:get, posts_path(Blog.Endpoint, :index))
    assert conn.status == 200
    assert conn.state == :sent
  end

  test "PostsController GET new" do
    conn = create_conn(:get, posts_path(Blog.Endpoint, :new))
    should_be_authenticated!(conn)

    conn = sign_in(conn, create_user)
    conn = request(conn)

    assert conn.status == 200
    assert conn.state == :sent
  end

  test "PostsController POST create" do
    conn = create_conn(:post, posts_path(Blog.Endpoint, :create), %{ post: %{ title: "foo", content: "bar" } })
    should_be_authenticated!(conn)

    conn = sign_in(conn, create_user)
    conn = request(conn)

    assert [%Post{content: "bar", title: "foo"}] = Repo.all(Post)
    assert conn.status == 302
    assert conn.state == :sent
    assert get_flash(conn, :notice) == "Post 'foo' created!"
  end

  test "PostsController GET edit" do
    conn = create_conn(:get, posts_path(Blog.Endpoint, :edit, create_post.id))
    should_be_authenticated!(conn)

    conn = sign_in(conn, create_user)
    conn = request(conn)

    assert conn.status == 200
    assert conn.state == :sent
  end

  test "PostsController PUT update" do
    conn = create_conn(:put, posts_path(Blog.Endpoint, :update, create_post.id), %{ post: %{ title: "new title", content: "new content" } })
    should_be_authenticated!(conn)

    conn = sign_in(conn, create_user)
    conn = request(conn)

    assert [%Post{title: "new title", content: "new content"}] = Repo.all(Post)
    assert conn.status == 302
    assert conn.state == :sent
    assert get_flash(conn, :notice) == "Post 'new title' updated!"
  end

  test "PostsController DELETE delete" do
    conn = request(:delete, posts_path(Blog.Endpoint, :delete, create_post.id))
    assert Repo.all(Post) == []
    assert conn.status == 302
    assert conn.state == :sent
    assert get_flash(conn, :notice) == "Post deleted!"
  end

  test "PagesController GET index" do
    conn = request(:get, page_path(Blog.Endpoint, :index))
    assert conn.status == 302
    assert conn.state == :sent
  end

  test "RegistrationsController GET new" do
    conn = create_conn(:get, registrations_path(Blog.Endpoint, :new))
    should_be_unauthenticated!(conn)
    conn = request(conn)

    assert conn.status == 200
    assert conn.state == :sent
  end

  test "RegistrationsController POST create" do
    conn = create_conn(:post, registrations_path(Blog.Endpoint, :create), %{ user: %{ email: "foo@bar.com", password: "master123", password_confirmation: "master123" } })
    should_be_unauthenticated!(conn)
    conn = request(conn)

    assert %User{email: "foo@bar.com", encrypted_password: "master123"} = User.last
    assert current_user(conn) == User.last
    assert conn.status == 302
    assert conn.state == :sent
    assert get_flash(conn, :notice) == "Welcome!"
  end

  test "SessionsController GET new" do
    conn = create_conn(:get, sessions_path(Blog.Endpoint, :new))
    should_be_unauthenticated!(conn)
    conn = request(conn)

    assert conn.status == 200
    assert conn.state == :sent
  end

  test "SessionsController POST create" do
    conn = create_conn(:post, sessions_path(Blog.Endpoint, :create), %{ user: %{ email: "foo@bar.com", password: "wrong" } })
    user = create_user
    should_be_unauthenticated!(conn, user)
    conn = request(conn)
    assert get_flash(conn, :alert) == "Incorrect email or password"

    conn = request(:post, sessions_path(Blog.Endpoint, :create), %{ user: %{ email: "lorem@bar.com", password: "master123" } })
    assert get_flash(conn, :alert) == "Incorrect email or password"

    conn = request(:post, sessions_path(Blog.Endpoint, :create), %{ user: %{ email: "foo@bar.com", password: "master123" } })
    assert get_flash(conn, :notice) == "Welcome!"
    assert current_user(conn).id == user.id
    assert conn.status == 302
    assert conn.state == :sent
  end

  test "SessionsController DELETE delete" do
    user = create_user
    conn = create_conn(:delete, sessions_path(Blog.Endpoint, :delete))
    conn = sign_in(conn, user)
    assert current_user(conn).id == user.id

    conn = request(conn)
    assert !current_user(conn)
    assert get_flash(conn, :notice) == "See you later"
    assert conn.status == 302
    assert conn.state == :sent
  end
end
