import Ecto.Query

# Add sample products for the shop
alias Blester.Accounts
alias Blester.Repo

# Helper to fetch user by email
get_user_by_email = fn email ->
  case Repo.one(Ecto.Query.from(u in Blester.Accounts.User, where: u.email == ^email, select: u)) do
    nil -> nil
    user -> user
  end
end

# Create or fetch admin user
admin_user = %{
  first_name: "Admin",
  last_name: "User",
  email: "admin@blester.com",
  password: "admin123",
  role: "admin",
  country: "US"
}

admin = case Accounts.create_user(admin_user) do
  {:ok, user} ->
    IO.puts("Admin user created: #{user.email}")
    user
  {:error, changeset} ->
    IO.puts("Failed to create admin user: #{inspect(changeset.errors)}. Trying to fetch existing user.")
    get_user_by_email.(admin_user.email)
end

# Create or fetch agent user
agent_user = %{
  first_name: "Sarah",
  last_name: "Johnson",
  email: "sarah.johnson@realtor.com",
  password: "agent123",
  role: "agent",
  country: "US"
}

agent = case Accounts.create_user(agent_user) do
  {:ok, user} ->
    IO.puts("Agent user created: #{user.email}")
    user
  {:error, changeset} ->
    IO.puts("Failed to create agent user: #{inspect(changeset.errors)}. Trying to fetch existing user.")
    get_user_by_email.(agent_user.email)
end

# Create or fetch owner user
owner_user = %{
  first_name: "Michael",
  last_name: "Smith",
  email: "michael.smith@email.com",
  password: "owner123",
  role: "user",
  country: "US"
}

owner = case Accounts.create_user(owner_user) do
  {:ok, user} ->
    IO.puts("Owner user created: #{user.email}")
    user
  {:error, changeset} ->
    IO.puts("Failed to create owner user: #{inspect(changeset.errors)}. Trying to fetch existing user.")
    get_user_by_email.(owner_user.email)
end

# Only create properties if we have the required users
if agent && owner do
  # Create properties data
  properties_data = [
    %{
      title: "Modern Downtown Condo",
      description: "Beautiful 2-bedroom condo in the heart of downtown. Features modern appliances, hardwood floors, and stunning city views. Perfect for young professionals or small families. Building includes gym, pool, and 24/7 security.",
      price: Decimal.new("450000"),
      bedrooms: 2,
      bathrooms: 2,
      square_feet: 1200,
      address: "123 Main Street",
      city: "New York",
      state: "NY",
      zip_code: "10001",
      property_type: "Condo",
      listing_date: ~U[2024-01-15 10:00:00Z],
      images: [
        "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&h=600&fit=crop",
        "https://images.unsplash.com/photo-1560448075-bb485b067938?w=800&h=600&fit=crop",
        "https://images.unsplash.com/photo-1560448204-6032e02f0f0a?w=800&h=600&fit=crop"
      ],
      virtual_tour_url: "https://example.com/virtual-tour-1",
      latitude: Decimal.new("40.7128"),
      longitude: Decimal.new("-74.0060"),
      amenities: ["Gym", "Pool", "Security", "Parking", "Balcony"],
      agent_id: agent.id,
      owner_id: owner.id,
      status: "active"
    },
    %{
      title: "Family Home with Garden",
      description: "Spacious 4-bedroom family home with a beautiful garden and backyard. Located in a quiet neighborhood with excellent schools nearby. Features updated kitchen, finished basement, and 2-car garage.",
      price: Decimal.new("750000"),
      bedrooms: 4,
      bathrooms: 3,
      square_feet: 2800,
      address: "456 Oak Avenue",
      city: "Los Angeles",
      state: "CA",
      zip_code: "90210",
      property_type: "House",
      listing_date: ~U[2024-01-20 14:30:00Z],
      images: [
        "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800&h=600&fit=crop",
        "https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800&h=600&fit=crop",
        "https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800&h=600&fit=crop"
      ],
      virtual_tour_url: "https://example.com/virtual-tour-2",
      latitude: Decimal.new("34.0522"),
      longitude: Decimal.new("-118.2437"),
      amenities: ["Garden", "Garage", "Basement", "Fireplace", "Central AC"],
      agent_id: agent.id,
      owner_id: owner.id,
      status: "active"
    },
    %{
      title: "Luxury Penthouse Suite",
      description: "Exclusive penthouse with panoramic city views. Features high-end finishes, custom kitchen, and private terrace. Building amenities include concierge service, rooftop pool, and private dining room.",
      price: Decimal.new("1200000"),
      bedrooms: 3,
      bathrooms: 3,
      square_feet: 2200,
      address: "789 Park Avenue",
      city: "New York",
      state: "NY",
      zip_code: "10022",
      property_type: "Apartment",
      listing_date: ~U[2024-01-25 09:15:00Z],
      images: [
        "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800&h=600&fit=crop",
        "https://images.unsplash.com/photo-1560448204-6032e02f0f0a?w=800&h=600&fit=crop",
        "https://images.unsplash.com/photo-1560448075-bb485b067938?w=800&h=600&fit=crop"
      ],
      virtual_tour_url: "https://example.com/virtual-tour-3",
      latitude: Decimal.new("40.7589"),
      longitude: Decimal.new("-73.9851"),
      amenities: ["Concierge", "Rooftop Pool", "Private Terrace", "Wine Cellar", "Home Theater"],
      agent_id: agent.id,
      owner_id: owner.id,
      status: "active"
    },
    %{
      title: "Cozy Townhouse",
      description: "Charming 3-bedroom townhouse in a family-friendly community. Features open floor plan, updated appliances, and private backyard. Close to shopping, restaurants, and public transportation.",
      price: Decimal.new("550000"),
      bedrooms: 3,
      bathrooms: 2,
      square_feet: 1800,
      address: "321 Elm Street",
      city: "Chicago",
      state: "IL",
      zip_code: "60601",
      property_type: "Townhouse",
      listing_date: ~U[2024-02-01 11:45:00Z],
      images: [
        "https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800&h=600&fit=crop",
        "https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800&h=600&fit=crop",
        "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800&h=600&fit=crop"
      ],
      virtual_tour_url: "https://example.com/virtual-tour-4",
      latitude: Decimal.new("41.8781"),
      longitude: Decimal.new("-87.6298"),
      amenities: ["Backyard", "Garage", "Fireplace", "Hardwood Floors", "Updated Kitchen"],
      agent_id: agent.id,
      owner_id: owner.id,
      status: "active"
    },
    %{
      title: "Investment Property - Multi-Family",
      description: "Excellent investment opportunity! 4-unit apartment building with consistent rental income. Each unit has 2 bedrooms and 1 bathroom. Property is well-maintained and fully occupied.",
      price: Decimal.new("850000"),
      bedrooms: 8,
      bathrooms: 4,
      square_feet: 3200,
      address: "654 Pine Street",
      city: "Miami",
      state: "FL",
      zip_code: "33101",
      property_type: "Commercial",
      listing_date: ~U[2024-02-05 16:20:00Z],
      images: [
        "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&h=600&fit=crop",
        "https://images.unsplash.com/photo-1560448075-bb485b067938?w=800&h=600&fit=crop",
        "https://images.unsplash.com/photo-1560448204-6032e02f0f0a?w=800&h=600&fit=crop"
      ],
      virtual_tour_url: "https://example.com/virtual-tour-5",
      latitude: Decimal.new("25.7617"),
      longitude: Decimal.new("-80.1918"),
      amenities: ["Parking", "Laundry", "Storage", "Security", "Maintenance"],
      agent_id: agent.id,
      owner_id: owner.id,
      status: "active"
    },
    %{
      title: "Waterfront Villa",
      description: "Stunning waterfront villa with private dock and boat access. Features 5 bedrooms, gourmet kitchen, and expansive outdoor living space. Perfect for those who love water activities and entertaining.",
      price: Decimal.new("1500000"),
      bedrooms: 5,
      bathrooms: 4,
      square_feet: 4200,
      address: "987 Beach Road",
      city: "Miami",
      state: "FL",
      zip_code: "33139",
      property_type: "House",
      listing_date: ~U[2024-02-10 13:10:00Z],
      images: [
        "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&h=600&fit=crop",
        "https://images.unsplash.com/photo-1560448075-bb485b067938?w=800&h=600&fit=crop",
        "https://images.unsplash.com/photo-1560448204-6032e02f0f0a?w=800&h=600&fit=crop"
      ],
      virtual_tour_url: "https://example.com/virtual-tour-6",
      latitude: Decimal.new("25.7617"),
      longitude: Decimal.new("-80.1918"),
      amenities: ["Private Dock", "Boat Access", "Pool", "Gourmet Kitchen", "Outdoor Living"],
      agent_id: agent.id,
      owner_id: owner.id,
      status: "active"
    }
  ]

  # Create properties
  Enum.each(properties_data, fn property_data ->
    case Accounts.create_property(property_data) do
      {:ok, property} ->
        IO.puts("Property created: #{property.title}")
      {:error, changeset} ->
        IO.puts("Failed to create property #{property_data.title}: #{inspect(changeset.errors)}")
    end
  end)
else
  IO.puts("Skipping property creation - required users not created successfully")
end

# Create sample products for the shop
products_data = [
  %{
    name: "Premium Coffee Beans",
    description: "High-quality Arabica coffee beans from Colombia. Rich flavor with notes of chocolate and caramel.",
    price: Decimal.new("24.99"),
    image_url: "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=400&h=400&fit=crop",
    category: "Coffee",
    stock_quantity: 50,
    sku: "COF-001",
    is_active: true,
    status: "active"
  },
  %{
    name: "Organic Tea Collection",
    description: "Assorted organic teas including green, black, and herbal varieties. Perfect for tea enthusiasts.",
    price: Decimal.new("18.50"),
    image_url: "https://images.unsplash.com/photo-1464983953574-0892a716854b?w=400&h=400&fit=crop",
    category: "Tea",
    stock_quantity: 30,
    sku: "TEA-001",
    is_active: true,
    status: "active"
  },
  %{
    name: "Artisan Bread Mix",
    description: "Premium bread mix for making delicious homemade bread. Includes all necessary ingredients.",
    price: Decimal.new("12.99"),
    image_url: "https://images.unsplash.com/photo-1519864600265-abb23847ef2c?w=400&h=400&fit=crop",
    category: "Baking",
    stock_quantity: 25,
    sku: "BRD-001",
    is_active: true,
    status: "active"
  },
  %{
    name: "Gourmet Chocolate Truffles",
    description: "Handcrafted chocolate truffles in assorted flavors. Perfect gift or treat for chocolate lovers.",
    price: Decimal.new("32.00"),
    image_url: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&h=400&fit=crop",
    category: "Chocolate",
    stock_quantity: 20,
    sku: "CHOC-001",
    is_active: true,
    status: "active"
  },
  %{
    name: "Organic Honey",
    description: "Pure organic honey sourced from local beekeepers. Natural sweetener with health benefits.",
    price: Decimal.new("15.99"),
    image_url: "https://images.unsplash.com/photo-1465101046530-73398c7f28ca?w=400&h=400&fit=crop",
    category: "Sweeteners",
    stock_quantity: 40,
    sku: "HNY-001",
    is_active: true,
    status: "active"
  }
]

# Create products
Enum.each(products_data, fn product_data ->
  case Accounts.create_product(product_data) do
    {:ok, product} ->
      IO.puts("Product created: #{product.name}")
    {:error, changeset} ->
      IO.puts("Failed to create product #{product_data.name}: #{inspect(changeset.errors)}")
  end
end)

# Create sample blog posts
if admin && agent do
  posts_data = [
    %{
      title: "Welcome to Blester",
      content: "Welcome to our new platform! We're excited to bring you the best in real estate, shopping, and community.",
      author_id: admin.id
    },
    %{
      title: "Real Estate Market Trends 2024",
      content: "The real estate market is showing interesting trends this year. We'll explore what's happening and what to expect.",
      author_id: admin.id
    },
    %{
      title: "Tips for First-Time Homebuyers",
      content: "Buying your first home can be overwhelming. Here are some essential tips to help you navigate the process successfully.",
      author_id: agent.id
    }
  ]

  # Create posts
  Enum.each(posts_data, fn post_data ->
    case Accounts.create_post(post_data) do
      {:ok, post} ->
        IO.puts("Post created: #{post.title}")
      {:error, changeset} ->
        IO.puts("Failed to create post #{post_data.title}: #{inspect(changeset.errors)}")
    end
  end)
else
  IO.puts("Skipping blog post creation - required users not created successfully")
end

IO.puts("Seeding completed!")
