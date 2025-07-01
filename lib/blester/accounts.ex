defmodule Blester.Accounts do
  use Ash.Domain

  require Ash.Query

  resources do
    resource Blester.Accounts.User
    resource Blester.Accounts.Post
    resource Blester.Accounts.Comment
    resource Blester.Accounts.Product
    resource Blester.Accounts.CartItem
    resource Blester.Accounts.Order
    resource Blester.Accounts.OrderItem
    resource Blester.Accounts.Property
    resource Blester.Accounts.Favorite
    resource Blester.Accounts.Inquiry
    resource Blester.Accounts.Viewing
  end

  # Generic pagination helper
  defp paginate_query(query, limit, offset, search_filters \\ [], additional_filters \\ []) do
    # Apply search filters
    search_query = Enum.reduce(search_filters, query, fn {field, search}, acc ->
      if search != "" and search != "all" do
        Ash.Query.filter(acc, [{field, [ilike: "%#{search}%"]}])
      else
        acc
      end
    end)

    # Apply additional filters
    final_query = Enum.reduce(additional_filters, search_query, fn {field, value}, acc ->
      if value != "" and value != "all" do
        Ash.Query.filter(acc, [{field, ilike: value}])
      else
        acc
      end
    end)

    # Get total count
    total_count =
      final_query
      |> Ash.count()
      |> case do
        {:ok, count} -> count
        _ -> 0
      end

    # Get paginated results
    paginated_query = final_query
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.Query.limit(limit)
    |> Ash.Query.offset(offset)

    case Ash.read(paginated_query) do
      {:ok, results} ->
        {:ok, {results, total_count}}
      _ ->
        {:error, :query_failed}
    end
  end

  # Generic CRUD helpers
  defp update_resource(resource, id, attrs, error_atom) do
    resource
    |> Ash.Query.filter(id: id)
    |> Ash.read_one()
    |> case do
      {:ok, record} ->
        record
        |> Ash.Changeset.for_update(:update, attrs)
        |> Ash.update()
      {:error, _} ->
        {:error, error_atom}
    end
  end

  defp delete_resource(resource, id, error_atom) do
    resource
    |> Ash.Query.filter(id: id)
    |> Ash.read_one()
    |> case do
      {:ok, record} ->
        Ash.destroy(record)
      {:error, _} ->
        {:error, error_atom}
    end
  end

  # In Ash 3.x, we can call Ash functions directly on resources

  def get_user_by_email(email) do
    Blester.Accounts.User
    |> Ash.Query.filter(email: email)
    |> Ash.read_one()
  end

  def create_user(attrs) do
    # Convert string keys to atoms for consistency
    attrs = for {key, val} <- attrs, into: %{} do
      case key do
        key when is_binary(key) -> {String.to_existing_atom(key), val}
        key when is_atom(key) -> {key, val}
      end
    end

    # Hash the password before creating the user
    attrs = Map.put(attrs, :hashed_password, Bcrypt.hash_pwd_salt(attrs.password))
    attrs = Map.delete(attrs, :password)

    Blester.Accounts.User
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  def authenticate_user(email, password) do
    case get_user_by_email(email) do
      {:ok, user} ->
        if Bcrypt.verify_pass(password, user.hashed_password) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
      {:error, _} ->
        {:error, :invalid_credentials}
    end
  end

  def get_user(id) do
    Blester.Accounts.User
    |> Ash.Query.filter(id: id)
    |> Ash.read_one()
  end

  # Blog functions
  def create_post(attrs) do
    # Convert string keys to atoms for consistency
    attrs = for {key, val} <- attrs, into: %{} do
      case key do
        key when is_binary(key) -> {String.to_existing_atom(key), val}
        key when is_atom(key) -> {key, val}
      end
    end

    Blester.Accounts.Post
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  def get_post(id) do
    Blester.Accounts.Post
    |> Ash.Query.filter(id: id)
    |> Ash.Query.load([:author, comments: [:author]])
    |> Ash.read_one()
  end

  def list_posts do
    Blester.Accounts.Post
    |> Ash.Query.load([:author, comments: [:author]])
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.read()
  end

  def list_posts_paginated(limit, offset, search \\ "") do
    # Get total count with search filter
    total_count_query = Blester.Accounts.Post
    |> Ash.Query.load([:author, comments: [:author]])

    total_count_query = if search != "" do
      total_count_query
      |> Ash.Query.filter(title: search)
    else
      total_count_query
    end

    total_count = total_count_query
    |> Ash.count()
    |> case do
      {:ok, count} -> count
      _ -> 0
    end

    # Get paginated posts with search filter
    posts_query = Blester.Accounts.Post
    |> Ash.Query.load([:author, comments: [:author]])
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.Query.limit(limit)
    |> Ash.Query.offset(offset)

    posts_query = if search != "" do
      posts_query
      |> Ash.Query.filter(title: search)
    else
      posts_query
    end

    case Ash.read(posts_query) do
      {:ok, posts} ->
        {:ok, {posts, total_count}}
      _ ->
        {:error, :query_failed}
    end
  end

  def update_post(id, attrs) do
    # Convert string keys to atoms for consistency
    attrs = for {key, val} <- attrs, into: %{} do
      case key do
        key when is_binary(key) -> {String.to_existing_atom(key), val}
        key when is_atom(key) -> {key, val}
      end
    end

    Blester.Accounts.Post
    |> Ash.Query.filter(id: id)
    |> Ash.read_one()
    |> case do
      {:ok, post} ->
        post
        |> Ash.Changeset.for_update(:update, attrs)
        |> Ash.update()
      {:error, _} ->
        {:error, :post_not_found}
    end
  end

  def delete_post(id) do
    Blester.Accounts.Post
    |> Ash.Query.filter(id: id)
    |> Ash.read_one()
    |> case do
      {:ok, post} ->
        Ash.destroy(post)
      {:error, _} ->
        {:error, :post_not_found}
    end
  end

  def create_comment(attrs) do
    # Convert string keys to atoms for consistency
    attrs = for {key, val} <- attrs, into: %{} do
      case key do
        key when is_binary(key) -> {String.to_existing_atom(key), val}
        key when is_atom(key) -> {key, val}
      end
    end

    Blester.Accounts.Comment
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  def get_comment(id) do
    Blester.Accounts.Comment
    |> Ash.Query.filter(id: id)
    |> Ash.Query.load([:author, :post])
    |> Ash.read_one()
  end

  def get_comments_for_post(post_id) do
    Blester.Accounts.Comment
    |> Ash.Query.filter(post_id: post_id)
    |> Ash.Query.load([:author])
    |> Ash.Query.sort(inserted_at: :asc)
    |> Ash.read()
  end

  def update_comment(id, attrs) do
    # Convert string keys to atoms for consistency
    attrs = for {key, val} <- attrs, into: %{} do
      case key do
        key when is_binary(key) -> {String.to_existing_atom(key), val}
        key when is_atom(key) -> {key, val}
      end
    end

    Blester.Accounts.Comment
    |> Ash.Query.filter(id: id)
    |> Ash.read_one()
    |> case do
      {:ok, comment} ->
        comment
        |> Ash.Changeset.for_update(:update, attrs)
        |> Ash.update()
      {:error, _} ->
        {:error, :comment_not_found}
    end
  end

  def delete_comment(id) do
    Blester.Accounts.Comment
    |> Ash.Query.filter(id: id)
    |> Ash.read_one()
    |> case do
      {:ok, comment} ->
        Ash.destroy(comment)
      {:error, _} ->
        {:error, :comment_not_found}
    end
  end

  # Shop functions
  def create_product(attrs) do
    # Convert string keys to atoms for consistency
    attrs = for {key, val} <- attrs, into: %{} do
      case key do
        key when is_binary(key) -> {String.to_existing_atom(key), val}
        key when is_atom(key) -> {key, val}
      end
    end

    Blester.Accounts.Product
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  def get_product(id) do
    Blester.Accounts.Product
    |> Ash.Query.filter(id: id)
    |> Ash.read_one()
  end

  def list_products do
    Blester.Accounts.Product
    |> Ash.Query.filter(is_active: true)
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.read()
  end

  def list_products_paginated(limit, offset, search \\ "", category \\ "") do
    base_query = Blester.Accounts.Product
    |> Ash.Query.filter(is_active: true)

    search_filters = if search != "", do: [{:name, search}], else: []
    additional_filters = if category != "", do: [{:category, category}], else: []

    paginate_query(base_query, limit, offset, search_filters, additional_filters)
  end

  def get_categories do
    Blester.Accounts.Product
    |> Ash.Query.filter(is_active: true)
    |> Ash.Query.select([:category])
    |> Ash.read()
    |> case do
      {:ok, products} ->
        products
        |> Enum.map(& &1.category)
        |> Enum.uniq()
        |> Enum.sort()
      _ ->
        []
    end
  end

  def add_to_cart(user_id, product_id, quantity \\ 1) do
    # Check if item already exists in cart
    existing_item = Blester.Accounts.CartItem
    |> Ash.Query.filter(user_id: user_id, product_id: product_id)
    |> Ash.read_one()

    case existing_item do
      {:ok, item} when not is_nil(item) ->
        # Update quantity
        new_quantity = item.quantity + quantity
        item
        |> Ash.Changeset.for_update(:update, %{quantity: new_quantity})
        |> Ash.update()
      _ ->
        # Create new cart item
        Blester.Accounts.CartItem
        |> Ash.Changeset.for_create(:create, %{
          user_id: user_id,
          product_id: product_id,
          quantity: quantity
        })
        |> Ash.create()
    end
  end

  def get_cart_items(user_id) do
    Blester.Accounts.CartItem
    |> Ash.Query.filter(user_id: user_id)
    |> Ash.Query.load([:product])
    |> Ash.read()
  end

  def update_cart_item_quantity(cart_item_id, quantity) do
    Blester.Accounts.CartItem
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

  def remove_from_cart(cart_item_id) do
    Blester.Accounts.CartItem
    |> Ash.Query.filter(id: cart_item_id)
    |> Ash.read_one()
    |> case do
      {:ok, item} ->
        Ash.destroy(item)
      {:error, _} ->
        {:error, :cart_item_not_found}
    end
  end

  def clear_cart(user_id) do
    Blester.Accounts.CartItem
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

  def create_order(user_id, attrs) do
    # Generate order number
    order_number = generate_order_number()

    order_attrs = Map.merge(attrs, %{
      user_id: user_id,
      order_number: order_number
    })

    Blester.Accounts.Order
    |> Ash.Changeset.for_create(:create, order_attrs)
    |> Ash.create()
  end

  def create_order_item(order_id, product_id, quantity, unit_price) do
    total_price = Decimal.mult(unit_price, quantity)

    Blester.Accounts.OrderItem
    |> Ash.Changeset.for_create(:create, %{
      order_id: order_id,
      product_id: product_id,
      quantity: quantity,
      unit_price: unit_price,
      total_price: total_price
    })
    |> Ash.create()
  end

  def get_order(id) do
    Blester.Accounts.Order
    |> Ash.Query.filter(id: id)
    |> Ash.Query.load([:order_items, :user])
    |> Ash.read_one()
  end

  def get_user_orders(user_id) do
    Blester.Accounts.Order
    |> Ash.Query.filter(user_id: user_id)
    |> Ash.Query.load([:order_items])
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.read()
  end

  def get_user_cart(user_id) do
    Blester.Accounts.CartItem
    |> Ash.Query.filter(user_id: user_id)
    |> Ash.Query.load(:product)
    |> Ash.read!()
  end

  def get_cart_count(user_id) do
    Blester.Accounts.CartItem
    |> Ash.Query.filter(user_id: user_id)
    |> Ash.count()
    |> case do
      {:ok, count} -> count
      _ -> 0
    end
  end

  def generate_order_number do
    "ORD-" <> :crypto.strong_rand_bytes(6) |> Base.encode16() |> binary_part(0, 12)
  end

  def place_order(order_params, cart_items) do
    # Create the order
    with {:ok, order} <-
           Blester.Accounts.Order
           |> Ash.Changeset.for_create(:create, order_params)
           |> Ash.create() do
      # Create order items
      Enum.each(cart_items, fn item ->
        Blester.Accounts.OrderItem
        |> Ash.Changeset.for_create(:create, %{
          order_id: order.id,
          product_id: item.product.id,
          quantity: item.quantity,
          unit_price: item.product.price,
          total_price: Decimal.mult(item.product.price, item.quantity)
        })
        |> Ash.create()
      end)
      # Clear the cart
      Enum.each(cart_items, fn item ->
        Blester.Accounts.CartItem
        |> Ash.destroy(item)
      end)
      {:ok, order}
    else
      error -> error
    end
  end

  # Admin functions
  def count_products do
    Blester.Accounts.Product
    |> Ash.count()
  end

  def count_orders do
    Blester.Accounts.Order
    |> Ash.count()
  end

  def count_users do
    Blester.Accounts.User
    |> Ash.count()
  end

  def get_recent_orders(limit) do
    Blester.Accounts.Order
    |> Ash.Query.load([:user])
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.Query.limit(limit)
    |> Ash.read()
  end

  def update_product(id, attrs) do
    update_resource(Blester.Accounts.Product, id, attrs, :product_not_found)
  end

  def delete_product(id) do
    delete_resource(Blester.Accounts.Product, id, :product_not_found)
  end

  def list_products_paginated_admin(limit, offset, search \\ "", category \\ "") do
    base_query = Blester.Accounts.Product

    search_filters = if search != "", do: [{:name, search}], else: []
    additional_filters = if category != "" and category != "all", do: [{:category, category}], else: []

    paginate_query(base_query, limit, offset, search_filters, additional_filters)
  end

  def list_orders_paginated(limit, offset, search \\ "", status \\ "") do
    base_query = Blester.Accounts.Order
    |> Ash.Query.load([:user])

    search_filters = if search != "", do: [{:user, [first_name: search]}], else: []
    additional_filters = if status != "" and status != "all", do: [{:status, status}], else: []

    paginate_query(base_query, limit, offset, search_filters, additional_filters)
  end

  def get_order_with_items(id) do
    Blester.Accounts.Order
    |> Ash.Query.filter(id: id)
    |> Ash.Query.load([:order_items, :user, order_items: [:product]])
    |> Ash.read_one()
  end

  def update_order_status(id, status) do
    update_resource(Blester.Accounts.Order, id, %{status: status}, :order_not_found)
  end

  def list_users_paginated(limit, offset, search \\ "", role \\ "") do
    base_query = Blester.Accounts.User

    search_filters = if search != "", do: [{:first_name, search}, {:last_name, search}, {:email, search}], else: []
    additional_filters = if role != "" and role != "all", do: [{:role, role}], else: []

    paginate_query(base_query, limit, offset, search_filters, additional_filters)
  end

  def update_user_role(id, role) do
    update_resource(Blester.Accounts.User, id, %{role: role}, :user_not_found)
  end

  # Property functions
  def create_property(attrs) do
    # Convert string keys to atoms for consistency
    attrs = for {key, val} <- attrs, into: %{} do
      case key do
        key when is_binary(key) -> {String.to_existing_atom(key), val}
        key when is_atom(key) -> {key, val}
      end
    end

    Blester.Accounts.Property
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  def get_property(id) do
    Blester.Accounts.Property
    |> Ash.Query.filter(id: id)
    |> Ash.Query.load([:agent, :owner])
    |> Ash.read_one()
  end

  def list_properties do
    Blester.Accounts.Property
    |> Ash.Query.load([:agent, :owner])
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.read()
  end

  def update_property(id, attrs) do
    update_resource(Blester.Accounts.Property, id, attrs, :property_not_found)
  end

  def delete_property(id) do
    delete_resource(Blester.Accounts.Property, id, :property_not_found)
  end

  def list_properties_paginated(limit, offset, search \\ "", filters \\ %{}) do
    base_query = Blester.Accounts.Property
    |> Ash.Query.filter(status: "active")
    |> Ash.Query.sort(inserted_at: :desc)

    # Apply search
    base_query = if search != "" do
      base_query
      |> Ash.Query.filter([
        or: [
          [title: [ilike: "%#{search}%"]],
          [description: [ilike: "%#{search}%"]],
          [address: [ilike: "%#{search}%"]],
          [city: [ilike: "%#{search}%"]]
        ]
      ])
    else
      base_query
    end

    # Apply filters
    base_query = apply_property_filters(base_query, filters)

    # Get total count
    total_count = case Ash.count(base_query) do
      {:ok, count} -> count
      _ -> 0
    end

    # Get paginated results
    properties = base_query
    |> Ash.Query.limit(limit)
    |> Ash.Query.offset(offset)
    |> Ash.Query.load([:agent, :owner])
    |> case do
      {:ok, results} -> results
      _ -> []
    end

    {:ok, {properties, total_count}}
  end

  defp apply_property_filters(query, filters) do
    Enum.reduce(filters, query, fn {key, value}, acc ->
      case {key, value} do
        {"property_type", value} when value != "all" and value != "" ->
          Ash.Query.filter(acc, property_type: value)

        {"min_price", value} when value != "" ->
          case Decimal.parse(value) do
            {:ok, price} -> Ash.Query.filter(acc, price: [gte: price])
            _ -> acc
          end

        {"max_price", value} when value != "" ->
          case Decimal.parse(value) do
            {:ok, price} -> Ash.Query.filter(acc, price: [lte: price])
            _ -> acc
          end

        {"bedrooms", value} when value != "all" and value != "" ->
          case Integer.parse(value) do
            {beds, _} -> Ash.Query.filter(acc, bedrooms: beds)
            _ -> acc
          end

        {"bathrooms", value} when value != "all" and value != "" ->
          case Integer.parse(value) do
            {baths, _} -> Ash.Query.filter(acc, bathrooms: baths)
            _ -> acc
          end

        {"city", value} when value != "all" and value != "" ->
          Ash.Query.filter(acc, city: value)

        {"state", value} when value != "all" and value != "" ->
          Ash.Query.filter(acc, state: value)

        {"status", value} when value != "all" and value != "" ->
          Ash.Query.filter(acc, status: value)

        _ -> acc
      end
    end)
  end

  # Favorite functions
  def create_favorite(user_id, property_id) do
    Blester.Accounts.Favorite
    |> Ash.Changeset.for_create(:create, %{
      user_id: user_id,
      property_id: property_id
    })
    |> Ash.create()
  end

  def remove_favorite(user_id, property_id) do
    Blester.Accounts.Favorite
    |> Ash.Query.filter(user_id: user_id, property_id: property_id)
    |> Ash.read_one()
    |> case do
      {:ok, favorite} ->
        Ash.destroy(favorite)
      _ ->
        {:error, :favorite_not_found}
    end
  end

  def is_favorite(user_id, property_id) do
    Blester.Accounts.Favorite
    |> Ash.Query.filter(user_id: user_id, property_id: property_id)
    |> Ash.read_one()
    |> case do
      {:ok, _favorite} -> true
      _ -> false
    end
  end

  def get_user_favorites(user_id) do
    Blester.Accounts.Favorite
    |> Ash.Query.filter(user_id: user_id)
    |> Ash.Query.load([:property])
    |> Ash.read()
  end

  # Inquiry functions
  def create_inquiry(attrs) do
    # Convert string keys to atoms for consistency
    attrs = for {key, val} <- attrs, into: %{} do
      case key do
        key when is_binary(key) -> {String.to_existing_atom(key), val}
        key when is_atom(key) -> {key, val}
      end
    end

    Blester.Accounts.Inquiry
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  def get_inquiry(id) do
    Blester.Accounts.Inquiry
    |> Ash.Query.filter(id: id)
    |> Ash.Query.load([:user, :property, :agent])
    |> Ash.read_one()
  end

  def list_user_inquiries(user_id) do
    Blester.Accounts.Inquiry
    |> Ash.Query.filter(user_id: user_id)
    |> Ash.Query.load([:property, :agent])
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.read()
  end

  def list_agent_inquiries(agent_id) do
    Blester.Accounts.Inquiry
    |> Ash.Query.filter(agent_id: agent_id)
    |> Ash.Query.load([:user, :property])
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.read()
  end

  def update_inquiry_status(id, status) do
    update_resource(Blester.Accounts.Inquiry, id, %{status: status}, :inquiry_not_found)
  end

  # Viewing functions
  def create_viewing(attrs) do
    # Convert string keys to atoms for consistency
    attrs = for {key, val} <- attrs, into: %{} do
      case key do
        key when is_binary(key) -> {String.to_existing_atom(key), val}
        key when is_atom(key) -> {key, val}
      end
    end

    Blester.Accounts.Viewing
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  def get_viewing(id) do
    Blester.Accounts.Viewing
    |> Ash.Query.filter(id: id)
    |> Ash.Query.load([:user, :property, :agent])
    |> Ash.read_one()
  end

  def list_user_viewings(user_id) do
    Blester.Accounts.Viewing
    |> Ash.Query.filter(user_id: user_id)
    |> Ash.Query.load([:property, :agent])
    |> Ash.Query.sort(scheduled_date: :asc)
    |> Ash.read()
  end

  def list_agent_viewings(agent_id) do
    Blester.Accounts.Viewing
    |> Ash.Query.filter(agent_id: agent_id)
    |> Ash.Query.load([:user, :property])
    |> Ash.Query.sort(scheduled_date: :asc)
    |> Ash.read()
  end

  def update_viewing_status(id, status) do
    update_resource(Blester.Accounts.Viewing, id, %{status: status}, :viewing_not_found)
  end
end
