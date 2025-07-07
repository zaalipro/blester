defmodule Blester.Shop do
  use Ash.Domain

  resources do
    resource Blester.Shop.Product
    resource Blester.Shop.CartItem
    resource Blester.Shop.Order
    resource Blester.Shop.OrderItem
    resource Blester.Shop.Category
  end

  @moduledoc """
  Unified context for shop-related operations (products, cart, orders, categories).
  """
  alias Blester.Shop.Product
  alias Blester.Shop.CartItem
  alias Blester.Shop.Order
  alias Blester.Shop.OrderItem
  alias Blester.Shop.Category
  require Ash.Query
  require Logger

  # --- Product Functions ---
  @spec list_products_paginated(integer(), integer(), String.t(), String.t()) :: {:ok, {[Product.t()], integer()}} | {:error, term()}
  def list_products_paginated(limit, offset, search \\ "", category \\ "") do
    base_query = Product
    |> Ash.Query.filter(is_active: true)
    |> Ash.Query.load(:category)

    search_filters = if search != "", do: [{:name, search}], else: []

    additional_filters =
      if category != "" do
        case Category |> Ash.Query.filter(name: category) |> Ash.read_one() do
          {:ok, %Category{id: category_id}} -> [{:category_id, category_id}]
          _ -> []
        end
      else
        []
      end

    filters = search_filters ++ additional_filters
    filters = Enum.reject(filters, fn {_field, value} -> value == "" or value == "all" end)
    filters = Enum.into(filters, %{})
    filtered_query = if map_size(filters) > 0, do: Ash.Query.filter(base_query, filters), else: base_query
    total_count =
      filtered_query
      |> Ash.count()
      |> case do
        {:ok, count} -> count
        _ -> 0
      end
    paginated_query = filtered_query
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.Query.limit(limit)
    |> Ash.Query.offset(offset)
    case Ash.read(paginated_query) do
      {:ok, results} -> {:ok, {results, total_count}}
      _ -> {:error, :query_failed}
    end
  end

  @spec get_categories() :: [String.t()]
  def get_categories do
    Category
    |> Ash.read()
    |> case do
      {:ok, categories} ->
        categories
        |> Enum.map(& &1.name)
        |> Enum.uniq()
        |> Enum.sort()
      _ ->
        []
    end
  end

  # --- Cart Functions ---
  @spec add_to_cart(String.t(), String.t(), integer()) :: {:ok, CartItem.t()} | {:error, term()}
  def add_to_cart(user_id, product_id, quantity \\ 1) do
    existing_item = CartItem
    |> Ash.Query.filter(user_id: user_id, product_id: product_id)
    |> Ash.read_one()
    case existing_item do
      {:ok, item} when not is_nil(item) ->
        new_quantity = item.quantity + quantity
        item
        |> Ash.Changeset.for_update(:update, %{quantity: new_quantity})
        |> Ash.update()
      _ ->
        CartItem
        |> Ash.Changeset.for_create(:create, %{
          user_id: user_id,
          product_id: product_id,
          quantity: quantity
        })
        |> Ash.create()
    end
  end

  @spec update_cart_item_quantity(String.t(), integer()) :: {:ok, CartItem.t()} | {:error, term()}
  def update_cart_item_quantity(cart_item_id, quantity) do
    CartItem
    |> Ash.Query.filter(id: cart_item_id)
    |> Ash.read_one()
    |> case do
      {:ok, item} ->
        if quantity <= 0 do
          Ash.destroy(item)
        else
          item
          |> Ash.Changeset.for_update(:update, %{quantity: quantity})
          |> Ash.update()
        end
      {:error, _} ->
        {:error, :cart_item_not_found}
    end
  end

  @spec remove_from_cart(String.t()) :: :ok | {:error, :cart_item_not_found}
  def remove_from_cart(cart_item_id) do
    CartItem
    |> Ash.Query.filter(id: cart_item_id)
    |> Ash.read_one()
    |> case do
      {:ok, item} ->
        Ash.destroy(item)
      {:error, _} ->
        {:error, :cart_item_not_found}
    end
  end

  @spec clear_cart(String.t()) :: :ok | {:error, :failed_to_clear_cart}
  def clear_cart(user_id) do
    CartItem
    |> Ash.Query.filter(user_id: user_id)
    |> Ash.read()
    |> case do
      {:ok, items} ->
        Enum.each(items, &Ash.destroy/1)
        {:ok, :cart_cleared}
      _ ->
        {:error, :failed_to_clear_cart}
    end
  end

  @spec get_user_cart(String.t()) :: [CartItem.t()]
  def get_user_cart(user_id) do
    CartItem
    |> Ash.Query.filter(user_id: user_id)
    |> Ash.Query.load(:product)
    |> Ash.read!()
  end

  @spec get_cart_count(String.t()) :: integer()
  def get_cart_count(user_id) do
    CartItem
    |> Ash.Query.filter(user_id: user_id)
    |> Ash.count()
    |> case do
      {:ok, count} -> count
      _ -> 0
    end
  end

  # --- Order Functions ---
  @spec create_order(String.t(), map()) :: {:ok, Order.t()} | {:error, term()}
  def create_order(user_id, attrs) do
    order_number = generate_order_number()
    order_attrs = Map.merge(attrs, %{user_id: user_id, order_number: order_number})
    Order
    |> Ash.Changeset.for_create(:create, order_attrs)
    |> Ash.create()
  end

  @spec create_order_item(String.t(), String.t(), integer(), Decimal.t()) :: {:ok, OrderItem.t()} | {:error, term()}
  def create_order_item(order_id, product_id, quantity, unit_price) do
    total_price = Decimal.mult(unit_price, quantity)
    OrderItem
    |> Ash.Changeset.for_create(:create, %{
      order_id: order_id,
      product_id: product_id,
      quantity: quantity,
      unit_price: unit_price,
      total_price: total_price
    })
    |> Ash.create()
  end

  @spec get_order(String.t()) :: {:ok, Order.t()} | {:error, term()}
  def get_order(id) do
    Order
    |> Ash.Query.filter(id: id)
    |> Ash.Query.load([:order_items, :user])
    |> Ash.read_one()
  end

  @spec get_user_orders(String.t()) :: {:ok, [Order.t()]} | {:error, term()}
  def get_user_orders(user_id) do
    Order
    |> Ash.Query.filter(user_id: user_id)
    |> Ash.Query.load([:order_items])
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.read()
  end

  @spec count_orders() :: {:ok, integer()} | {:error, term()}
  def count_orders do
    Order
    |> Ash.count()
  end

  @spec get_recent_orders(integer()) :: {:ok, [Order.t()]} | {:error, term()}
  def get_recent_orders(limit) do
    Order
    |> Ash.Query.load([:user])
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.Query.limit(limit)
    |> Ash.read()
  end

  @spec update_order_status(String.t(), String.t()) :: {:ok, Order.t()} | {:error, term()}
  def update_order_status(id, status) do
    Order
    |> Ash.Query.filter(id: id)
    |> Ash.read_one()
    |> case do
      {:ok, record} ->
        record
        |> Ash.Changeset.for_update(:update, %{status: status})
        |> Ash.update()
      {:error, _} ->
        {:error, :order_not_found}
    end
  end

  defp generate_order_number do
    "ORD-" <> :crypto.strong_rand_bytes(6) |> Base.encode16() |> binary_part(0, 12)
  end

  # --- Category Functions ---
  @spec create_category(map()) :: {:ok, Category.t()} | {:error, term()}
  def create_category(attrs) do
    attrs = for {key, val} <- attrs, into: %{} do
      case key do
        key when is_binary(key) -> {String.to_existing_atom(key), val}
        key when is_atom(key) -> {key, val}
      end
    end
    Category
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  @spec get_categories() :: {:ok, [Category.t()]} | {:error, term()}
  def get_categories do
    Category
    |> Ash.read()
  end

  @spec get_product(String.t()) :: {:ok, any()} | {:error, term()}
  def get_product(_id), do: {:error, :not_implemented}

  @spec add_to_cart(String.t(), String.t(), integer()) :: {:ok, any()} | {:error, term()}
  def add_to_cart(_user_id, _product_id, _quantity), do: {:error, :not_implemented}

  @spec update_cart_item_quantity(String.t(), integer()) :: {:ok, any()} | {:error, term()}
  def update_cart_item_quantity(_item_id, _quantity), do: {:error, :not_implemented}

  @spec remove_from_cart(String.t()) :: {:ok, any()} | {:error, term()}
  def remove_from_cart(_item_id), do: {:error, :not_implemented}

  @spec clear_cart(String.t()) :: {:ok, integer()} | {:error, term()}
  def clear_cart(_user_id), do: {:ok, 0}

  @spec list_products_paginated_admin(integer(), integer(), String.t(), String.t()) :: {:ok, {list(), integer()}} | {:error, term()}
  def list_products_paginated_admin(_per_page, _offset, _search, _category), do: {:ok, {[], 0}}

  @spec delete_product(String.t()) :: {:ok, any()} | {:error, term()}
  def delete_product(_id), do: {:error, :not_implemented}

  @spec create_product(map()) :: {:ok, any()} | {:error, term()}
  def create_product(_params), do: {:error, :not_implemented}

  @spec update_product(String.t(), map()) :: {:ok, any()} | {:error, term()}
  def update_product(_id, _params), do: {:error, :not_implemented}
end
