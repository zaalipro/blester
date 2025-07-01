defmodule Blester.AccountsProductCategoryFilterTest do
  use ExUnit.Case, async: true
  alias Blester.Accounts

  setup do
    # Create categories
    {:ok, cat1} = Accounts.create_category(%{"name" => "Coffee"})
    {:ok, cat2} = Accounts.create_category(%{"name" => "Tea"})

    # Create products
    {:ok, prod1} = Accounts.create_product(%{
      "name" => "Colombian Coffee",
      "description" => "Rich coffee",
      "price" => Decimal.new("10.00"),
      "image_url" => "http://example.com/coffee.jpg",
      "stock_quantity" => 10,
      "sku" => "COF-001",
      "is_active" => true,
      "status" => "active",
      "category_id" => cat1.id
    })
    {:ok, prod2} = Accounts.create_product(%{
      "name" => "Green Tea",
      "description" => "Fresh tea",
      "price" => Decimal.new("5.00"),
      "image_url" => "http://example.com/tea.jpg",
      "stock_quantity" => 20,
      "sku" => "TEA-001",
      "is_active" => true,
      "status" => "active",
      "category_id" => cat2.id
    })
    {:ok, cat1: cat1, cat2: cat2, prod1: prod1, prod2: prod2}
  end

  test "filter products by category name returns correct products", %{cat1: cat1, cat2: cat2, prod1: prod1, prod2: prod2} do
    {:ok, {products_coffee, _}} = Accounts.list_products_paginated(10, 0, "", cat1.name)
    {:ok, {products_tea, _}} = Accounts.list_products_paginated(10, 0, "", cat2.name)

    assert Enum.any?(products_coffee, &(&1.id == prod1.id))
    refute Enum.any?(products_coffee, &(&1.id == prod2.id))
    assert Enum.any?(products_tea, &(&1.id == prod2.id))
    refute Enum.any?(products_tea, &(&1.id == prod1.id))
  end

  test "filter products by non-existent category returns no products" do
    {:ok, {products, _}} = Accounts.list_products_paginated(10, 0, "", "NonExistent")
    assert products == []
  end
end
