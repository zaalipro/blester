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
  end

  # In Ash 3.x, we can call Ash functions directly on resources

  def get_user_by_email(email) do
    Blester.Accounts.User
    |> Ash.Query.filter(email: email)
    |> Ash.read_one()
  end

  def create_user(attrs) do
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
    Blester.Accounts.Post
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  def get_post(id) do
    Blester.Accounts.Post
    |> Ash.Query.filter(id: id)
    |> Ash.Query.load([:author, :comments])
    |> Ash.read_one()
  end

  def list_posts do
    Blester.Accounts.Post
    |> Ash.Query.load([:author, :comments])
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.read()
  end

  def list_posts_paginated(limit, offset) do
    # Get total count
    total_count =
      Blester.Accounts.Post
      |> Ash.count()
      |> case do
        {:ok, count} -> count
        _ -> 0
      end

    # Get paginated posts
    posts_query =
      Blester.Accounts.Post
      |> Ash.Query.load([:author, :comments])
      |> Ash.Query.sort(inserted_at: :desc)
      |> Ash.Query.limit(limit)
      |> Ash.Query.offset(offset)

    case Ash.read(posts_query) do
      {:ok, posts} ->
        {:ok, {posts, total_count}}
      _ ->
        {:error, :query_failed}
    end
  end

  def update_post(id, attrs) do
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
    # Build base query
    base_query = Blester.Accounts.Product
    |> Ash.Query.filter(is_active: true)

    # Add search filter (case-insensitive)
    search_query = if search != "" do
      base_query
      |> Ash.Query.filter(name: [ilike: "%#{search}%"])
    else
      base_query
    end

    # Add category filter
    final_query = if category != "" do
      search_query
      |> Ash.Query.filter(category: category)
    else
      search_query
    end

    # Get total count
    total_count =
      final_query
      |> Ash.count()
      |> case do
        {:ok, count} -> count
        _ -> 0
      end

    # Get paginated products
    products_query = final_query
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.Query.limit(limit)
    |> Ash.Query.offset(offset)

    case Ash.read(products_query) do
      {:ok, products} ->
        {:ok, {products, total_count}}
      _ ->
        {:error, :query_failed}
    end
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
    order_number = "ORD-#{System.system_time(:millisecond)}"

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
end
