defmodule Blester.Realtor do
  use Ash.Domain

  resources do
    resource Blester.Realtor.Property
    resource Blester.Realtor.Favorite
    resource Blester.Realtor.Inquiry
    resource Blester.Realtor.Viewing
  end

  @moduledoc """
  Unified context for property-related operations (properties, favorites, inquiries, viewings).
  """
  alias Blester.Realtor.Property
  alias Blester.Realtor.Favorite
  alias Blester.Realtor.Inquiry
  alias Blester.Realtor.Viewing
  require Ash.Query

  # --- Property Functions ---
  @spec create_property(map()) :: {:ok, Property.t()} | {:error, term()}
  def create_property(attrs) do
    attrs = for {key, val} <- attrs, into: %{} do
      case key do
        key when is_binary(key) -> {String.to_existing_atom(key), val}
        key when is_atom(key) -> {key, val}
      end
    end
    Property
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  @spec get_property(String.t()) :: {:ok, Property.t()} | {:error, term()}
  def get_property(id) do
    Property
    |> Ash.Query.filter(id: id)
    |> Ash.Query.load([:agent, :owner])
    |> Ash.read_one()
  end

  @spec list_properties() :: {:ok, [Property.t()]} | {:error, term()}
  def list_properties do
    Property
    |> Ash.Query.load([:agent, :owner])
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.read()
  end

  # --- Favorite Functions ---
  @spec create_favorite(String.t(), String.t()) :: {:ok, Favorite.t()} | {:error, term()}
  def create_favorite(user_id, property_id) do
    Favorite
    |> Ash.Changeset.for_create(:create, %{
      user_id: user_id,
      property_id: property_id
    })
    |> Ash.create()
  end

  @spec remove_favorite(String.t(), String.t()) :: :ok | {:error, :favorite_not_found}
  def remove_favorite(user_id, property_id) do
    Favorite
    |> Ash.Query.filter(user_id: user_id, property_id: property_id)
    |> Ash.read_one()
    |> case do
      {:ok, favorite} ->
        Ash.destroy(favorite)
      _ ->
        {:error, :favorite_not_found}
    end
  end

  @spec is_favorite(String.t(), String.t()) :: boolean()
  def is_favorite(_property_id, _user_id), do: false

  @spec get_user_favorites(String.t()) :: {:ok, [Favorite.t()]} | {:error, term()}
  def get_user_favorites(user_id) do
    Favorite
    |> Ash.Query.filter(user_id: user_id)
    |> Ash.Query.load([:property])
    |> Ash.read()
  end

  # --- Inquiry Functions ---
  @spec create_inquiry(map()) :: {:ok, Inquiry.t()} | {:error, term()}
  def create_inquiry(attrs) do
    attrs = for {key, val} <- attrs, into: %{} do
      case key do
        key when is_binary(key) -> {String.to_existing_atom(key), val}
        key when is_atom(key) -> {key, val}
      end
    end
    Inquiry
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  @spec get_inquiry(String.t()) :: {:ok, Inquiry.t()} | {:error, term()}
  def get_inquiry(id) do
    Inquiry
    |> Ash.Query.filter(id: id)
    |> Ash.Query.load([:user, :property, :agent])
    |> Ash.read_one()
  end

  @spec list_user_inquiries(String.t()) :: {:ok, [Inquiry.t()]} | {:error, term()}
  def list_user_inquiries(user_id) do
    Inquiry
    |> Ash.Query.filter(user_id: user_id)
    |> Ash.Query.load([:property, :agent])
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.read()
  end

  @spec list_agent_inquiries(String.t()) :: {:ok, [Inquiry.t()]} | {:error, term()}
  def list_agent_inquiries(agent_id) do
    Inquiry
    |> Ash.Query.filter(agent_id: agent_id)
    |> Ash.Query.load([:user, :property])
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.read()
  end

  @spec update_inquiry_status(String.t(), String.t()) :: {:ok, Inquiry.t()} | {:error, term()}
  def update_inquiry_status(id, status) do
    Inquiry
    |> Ash.Query.filter(id: id)
    |> Ash.read_one()
    |> case do
      {:ok, record} ->
        record
        |> Ash.Changeset.for_update(:update, %{status: status})
        |> Ash.update()
      {:error, _} ->
        {:error, :inquiry_not_found}
    end
  end

  # --- Viewing Functions ---
  @spec create_viewing(map()) :: {:ok, Viewing.t()} | {:error, term()}
  def create_viewing(attrs) do
    attrs = for {key, val} <- attrs, into: %{} do
      case key do
        key when is_binary(key) -> {String.to_existing_atom(key), val}
        key when is_atom(key) -> {key, val}
      end
    end
    Viewing
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  @spec get_viewing(String.t()) :: {:ok, Viewing.t()} | {:error, term()}
  def get_viewing(id) do
    Viewing
    |> Ash.Query.filter(id: id)
    |> Ash.Query.load([:user, :property, :agent])
    |> Ash.read_one()
  end

  @spec list_user_viewings(String.t()) :: {:ok, [Viewing.t()]} | {:error, term()}
  def list_user_viewings(user_id) do
    Viewing
    |> Ash.Query.filter(user_id: user_id)
    |> Ash.Query.load([:property, :agent])
    |> Ash.Query.sort(scheduled_date: :asc)
    |> Ash.read()
  end

  @spec list_agent_viewings(String.t()) :: {:ok, [Viewing.t()]} | {:error, term()}
  def list_agent_viewings(agent_id) do
    Viewing
    |> Ash.Query.filter(agent_id: agent_id)
    |> Ash.Query.load([:user, :property])
    |> Ash.Query.sort(scheduled_date: :asc)
    |> Ash.read()
  end

  @spec update_viewing_status(String.t(), String.t()) :: {:ok, Viewing.t()} | {:error, term()}
  def update_viewing_status(id, status) do
    Viewing
    |> Ash.Query.filter(id: id)
    |> Ash.read_one()
    |> case do
      {:ok, record} ->
        record
        |> Ash.Changeset.for_update(:update, %{status: status})
        |> Ash.update()
      {:error, _} ->
        {:error, :viewing_not_found}
    end
  end

  # Add stubs for missing functions as described above
  @spec list_properties_paginated(integer(), integer(), String.t(), map()) :: {:ok, {[Property.t()], integer()}} | {:error, term()}
  def list_properties_paginated(_limit, _offset, _search, _filters) do
    # This is a stub. The actual implementation would involve building a query
    # with Ash.Query and applying pagination, search, and filters.
    # For now, it returns an error as the full logic is not provided.
    {:error, :not_implemented}
  end

  @spec toggle_favorite(String.t(), String.t()) :: {:ok, Favorite.t()} | {:error, term()}
  def toggle_favorite(_user_id, _property_id) do
    # This is a stub. The actual implementation would involve checking if
    # the property is already favorited, and if so, removing it, otherwise adding it.
    # For now, it returns an error as the full logic is not provided.
    {:error, :not_implemented}
  end

  @spec create_inquiry(String.t(), String.t(), map()) :: {:ok, Inquiry.t()} | {:error, term()}
  def create_inquiry(_inquiry_params, _user_id, _property) do
    # This is a stub. The actual implementation would involve creating an inquiry
    # with the provided parameters and linking it to the user and property.
    # For now, it returns an error as the full logic is not provided.
    {:error, :not_implemented}
  end
end
