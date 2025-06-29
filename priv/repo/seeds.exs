# Add sample products for the shop
alias Blester.Accounts

# Sample products data
products_data = [
  %{
    name: "Wireless Bluetooth Headphones",
    description: "Premium wireless headphones with noise cancellation and 30-hour battery life. Perfect for music lovers and professionals.",
    price: Decimal.new("89.99"),
    image_url: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop",
    category: "Electronics",
    stock_quantity: 50,
    sku: "WH-001",
    is_active: true
  },
  %{
    name: "Smart Fitness Watch",
    description: "Advanced fitness tracker with heart rate monitoring, GPS, and water resistance. Track your workouts and health metrics.",
    price: Decimal.new("199.99"),
    image_url: "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&h=400&fit=crop",
    category: "Electronics",
    stock_quantity: 30,
    sku: "SW-002",
    is_active: true
  },
  %{
    name: "Organic Cotton T-Shirt",
    description: "Comfortable and sustainable cotton t-shirt made from 100% organic materials. Available in multiple colors.",
    price: Decimal.new("24.99"),
    image_url: "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=400&fit=crop",
    category: "Clothing",
    stock_quantity: 100,
    sku: "TS-003",
    is_active: true
  },
  %{
    name: "Stainless Steel Water Bottle",
    description: "Eco-friendly water bottle made from food-grade stainless steel. Keeps drinks cold for 24 hours or hot for 12 hours.",
    price: Decimal.new("34.99"),
    image_url: "https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=400&h=400&fit=crop",
    category: "Home & Garden",
    stock_quantity: 75,
    sku: "WB-004",
    is_active: true
  },
  %{
    name: "Wireless Charging Pad",
    description: "Fast wireless charging pad compatible with all Qi-enabled devices. Sleek design with LED indicator.",
    price: Decimal.new("49.99"),
    image_url: "https://images.unsplash.com/photo-1586953208448-b95a79798f07?w=400&h=400&fit=crop",
    category: "Electronics",
    stock_quantity: 40,
    sku: "WC-005",
    is_active: true
  },
  %{
    name: "Leather Wallet",
    description: "Handcrafted genuine leather wallet with multiple card slots and RFID protection. Classic design for everyday use.",
    price: Decimal.new("59.99"),
    image_url: "https://images.unsplash.com/photo-1627123424574-724758594e93?w=400&h=400&fit=crop",
    category: "Accessories",
    stock_quantity: 60,
    sku: "LW-006",
    is_active: true
  },
  %{
    name: "Portable Bluetooth Speaker",
    description: "Waterproof portable speaker with 360-degree sound and 20-hour battery life. Perfect for outdoor activities.",
    price: Decimal.new("79.99"),
    image_url: "https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=400&h=400&fit=crop",
    category: "Electronics",
    stock_quantity: 35,
    sku: "BS-007",
    is_active: true
  },
  %{
    name: "Yoga Mat",
    description: "Non-slip yoga mat made from eco-friendly materials. Perfect thickness for comfort and stability during practice.",
    price: Decimal.new("39.99"),
    image_url: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&h=400&fit=crop",
    category: "Sports",
    stock_quantity: 80,
    sku: "YM-008",
    is_active: true
  },
  %{
    name: "Ceramic Coffee Mug Set",
    description: "Set of 4 beautiful ceramic coffee mugs with modern design. Microwave and dishwasher safe.",
    price: Decimal.new("29.99"),
    image_url: "https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=400&h=400&fit=crop",
    category: "Home & Garden",
    stock_quantity: 90,
    sku: "CM-009",
    is_active: true
  },
  %{
    name: "Sunglasses",
    description: "Polarized sunglasses with UV400 protection and lightweight frame. Stylish design for outdoor activities.",
    price: Decimal.new("69.99"),
    image_url: "https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=400&h=400&fit=crop",
    category: "Accessories",
    stock_quantity: 45,
    sku: "SG-010",
    is_active: true
  }
]

# Create products
Enum.each(products_data, fn product_data ->
  Accounts.create_product(product_data)
end)
