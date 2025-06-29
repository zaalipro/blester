defmodule BlesterWeb.RealtorLive.Show do
  use BlesterWeb, :live_view
  require Ash.Query
  alias Blester.Accounts

  @impl true
  def mount(%{"id" => property_id}, _session, socket) do
    # Get current user info from socket assigns (set by plugs)
    current_user = socket.assigns[:current_user]
    current_user_id = socket.assigns[:current_user_id]

    case get_property(property_id) do
      {:ok, property} ->
        socket = assign(socket,
          property: property,
          current_image_index: 0,
          inquiry_form: %{
            message: "",
            inquiry_type: "viewing"
          },
          inquiry_types: [
            {"Viewing Request", "viewing"},
            {"Make an Offer", "offer"},
            {"General Question", "question"}
          ],
          current_user: current_user,
          current_user_id: current_user_id
        )
        {:ok, socket}

      _ ->
        {:ok,
          socket
          |> put_flash(:error, "Property not found")
          |> push_navigate(to: "/properties")
        }
    end
  end

  @impl true
  def handle_params(%{"id" => property_id}, _url, socket) do
    case get_property(property_id) do
      {:ok, property} ->
        {:noreply, assign(socket, property: property)}
      _ ->
        {:noreply,
          socket
          |> put_flash(:error, "Property not found")
          |> push_navigate(to: "/properties")
        }
    end
  end

  @impl true
  def handle_event("toggle_favorite", _params, socket) do
    case socket.assigns.current_user do
      nil ->
        {:noreply, put_flash(socket, :error, "Please log in to save favorites")}

      user ->
        case toggle_favorite(user.id, socket.assigns.property.id) do
          {:ok, _} ->
            {:noreply, put_flash(socket, :info, "Favorite updated")}
          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to update favorite")}
        end
    end
  end

  @impl true
  def handle_event("change_image", %{"index" => index}, socket) do
    index = String.to_integer(index)
    {:noreply, assign(socket, current_image_index: index)}
  end

  @impl true
  def handle_event("submit_inquiry", %{"inquiry" => inquiry_params}, socket) do
    case socket.assigns.current_user do
      nil ->
        {:noreply, put_flash(socket, :error, "Please log in to submit an inquiry")}

      user ->
        case create_inquiry(inquiry_params, user.id, socket.assigns.property) do
          {:ok, _inquiry} ->
            {:noreply,
              socket
              |> put_flash(:info, "Inquiry submitted successfully! We'll get back to you soon.")
              |> assign(inquiry_form: %{message: "", inquiry_type: "viewing"})
            }
          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to submit inquiry")}
        end
    end
  end

  @impl true
  def handle_event("schedule_viewing", _params, socket) do
    case socket.assigns.current_user do
      nil ->
        {:noreply, put_flash(socket, :error, "Please log in to schedule a viewing")}

      _user ->
        # This would typically open a modal or navigate to a scheduling page
        {:noreply, put_flash(socket, :info, "Viewing scheduling feature coming soon!")}
    end
  end

  defp get_property(property_id) do
    Accounts.Property
    |> Ash.Query.filter(id: property_id)
    |> Ash.Query.load([:agent, :owner, :amenities])
    |> Ash.read_one()
  end

  defp toggle_favorite(user_id, property_id) do
    # Check if favorite exists
    existing_favorite = Accounts.Favorite
    |> Ash.Query.filter(user_id: user_id, property_id: property_id)
    |> Ash.read_one()

    case existing_favorite do
      {:ok, favorite} ->
        # Remove favorite
        Ash.destroy(favorite)

      _ ->
        # Add favorite
        Accounts.Favorite
        |> Ash.Changeset.for_create(:create, %{
          user_id: user_id,
          property_id: property_id
        })
        |> Ash.create()
    end
  end

  defp create_inquiry(inquiry_params, user_id, property) do
    Accounts.Inquiry
    |> Ash.Changeset.for_create(:create, %{
      message: inquiry_params["message"],
      inquiry_type: inquiry_params["inquiry_type"],
      user_id: user_id,
      property_id: property.id,
      agent_id: property.agent_id
    })
    |> Ash.create()
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
    if user_id do
      Accounts.Favorite
      |> Ash.Query.filter(user_id: user_id, property_id: property_id)
      |> Ash.read_one()
      |> case do
        {:ok, _favorite} -> true
        _ -> false
      end
    else
      false
    end
  end

  defp format_date(date) do
    Calendar.strftime(date, "%B %d, %Y")
  end

  defp get_property_status_color(status) do
    case status do
      "active" -> "bg-green-100 text-green-800"
      "pending" -> "bg-yellow-100 text-yellow-800"
      "sold" -> "bg-red-100 text-red-800"
      "inactive" -> "bg-gray-100 text-gray-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end
end
