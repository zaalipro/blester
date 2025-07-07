defmodule BlesterWeb.RealtorLive.Index do
  use BlesterWeb, :live_view
  require Ash.Query
  alias Blester.Realtor

  @impl true
  def mount(_params, _session, socket) do
    # Get current user info from socket assigns (set by plugs)
    current_user = socket.assigns[:current_user]
    current_user_id = socket.assigns[:current_user_id]
    cart_count = socket.assigns[:cart_count] || 0

    socket = assign(socket,
      properties: [],
      total_pages: 0,
      current_page: 1,
      total_count: 0,
      search: "",
      filters: %{
        property_type: "all",
        min_price: "",
        max_price: "",
        bedrooms: "all",
        bathrooms: "all",
        city: "all",
        state: "all",
        status: "all"
      },
      property_types: ["House", "Condo", "Townhouse", "Apartment", "Land", "Commercial"],
      cities: [],
      states: [],
      loading: false,
      current_user: current_user,
      current_user_id: current_user_id,
      cart_count: cart_count
    )

    # Load initial data - temporarily skip filter options
    socket = load_properties(socket)
    # socket = load_filter_options(socket)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"page" => page}, _url, socket) do
    page = String.to_integer(page)
    socket = assign(socket, current_page: page)
    socket = load_properties(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    socket = assign(socket, search: search, current_page: 1)
    socket = load_properties(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    # Ensure all expected keys are present
    merged_filters =
      @default_filters
      |> Map.merge(for {k, v} <- filters, into: %{}, do: {String.to_atom(k), v})
    socket = assign(socket, filters: merged_filters, current_page: 1)
    socket = load_properties(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    socket = assign(socket,
      filters: %{
        property_type: "all",
        min_price: "",
        max_price: "",
        bedrooms: "all",
        bathrooms: "all",
        city: "all",
        state: "all",
        status: "all"
      },
      search: "",
      current_page: 1
    )
    socket = load_properties(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle_favorite", %{"property_id" => property_id}, socket) do
    case socket.assigns.current_user do
      nil ->
        {:noreply, put_flash(socket, :error, "Please log in to save favorites")}

      user ->
        case toggle_favorite(user.id, property_id) do
          {:ok, _} ->
            socket = load_properties(socket)
            {:noreply, put_flash(socket, :info, "Favorite updated")}
          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to update favorite")}
        end
    end
  end

  defp load_properties(socket) do
    assign(socket, loading: true)

    limit = 12
    offset = (socket.assigns.current_page - 1) * limit

    case Blester.Realtor.list_properties_paginated(limit, offset, socket.assigns.search, socket.assigns.filters) do
      {:ok, {properties, total_count}} ->
        total_pages = ceil(total_count / limit)
        assign(socket,
          properties: properties,
          total_pages: total_pages,
          total_count: total_count,
          loading: false
        )
      _ ->
        assign(socket,
          properties: [],
          total_pages: 0,
          total_count: 0,
          loading: false
        )
    end
  end

  defp toggle_favorite(user_id, property_id) do
    Blester.Realtor.toggle_favorite(user_id, property_id)
  end

  defp format_price(price) do
    case price do
      %Decimal{} ->
        price
        |> Decimal.round(0)
        |> Decimal.to_string()
        |> then(&"$#{&1}")
      _ -> "$0"
    end
  end

  defp format_square_feet(square_feet) do
    case square_feet do
      %Decimal{} ->
        square_feet
        |> Decimal.round(0)
        |> Decimal.to_string()
        |> then(&String.replace(&1, ~r/(\d)(?=(\d{3})+(?!\d))/, "\\1,"))
      _ when is_integer(square_feet) ->
        square_feet
        |> Integer.to_string()
        |> then(&String.replace(&1, ~r/(\d)(?=(\d{3})+(?!\d))/, "\\1,"))
      _ -> "0"
    end
  end

  defp is_favorite(property_id, user_id) do
    Blester.Realtor.is_favorite(property_id, user_id)
  end

  @default_filters %{
    property_type: "all",
    min_price: "",
    max_price: "",
    bedrooms: "all",
    bathrooms: "all",
    city: "all",
    state: "all",
    status: "all"
  }
end
