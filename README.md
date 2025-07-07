# Blester

A Phoenix application built with the Ash Framework.

## Prerequisites

Before you begin, ensure you have the following installed on your local machine:

*   Elixir & Mix
*   Node.js & npm
*   Docker

## Getting Started

Follow these steps to get your development environment set up and running.

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd blester
```

### 2. Start the Database

This project requires a PostgreSQL database. You can easily run one using Docker:

```bash
docker run --name blester-postgres -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres
```

This command starts a PostgreSQL container named `blester-postgres` and makes it available on `localhost:5432`.

### 3. Install Dependencies

Install the Elixir and JavaScript dependencies:

```bash
# Install Elixir dependencies
mix deps.get

# Install Node.js dependencies
npm install --prefix assets
```

### 4. Set Up the Database

Create the database and run the initial migrations using the custom Ash task:

```bash
mix ash.setup
```

### 5. Start the Phoenix Server

Now you can start the Phoenix server:

```bash
mix phx.server
```

Your application should now be running at `http://localhost:4000`.

## Learn more

  * Official Phoenix website: https://www.phoenixframework.org/
  * Phoenix Guides: https://hexdocs.pm/phoenix/overview.html
  * Ash Framework: https://ash-hq.org/
  * AshPostgres: https://hexdocs.pm/ash_postgres/
