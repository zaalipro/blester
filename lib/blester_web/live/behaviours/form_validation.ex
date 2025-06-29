defmodule BlesterWeb.LiveBehaviours.FormValidation do
  @moduledoc """
  Behaviour for LiveView components that need form validation.
  """

  @callback validate_form(map()) :: map()
  @callback format_errors(any()) :: map()

  defmacro __using__(_opts) do
    quote do
      @behaviour BlesterWeb.LiveBehaviours.FormValidation

      import BlesterWeb.LiveValidations

      @impl true
      def handle_info(:clear_flash, socket) do
        {:noreply, clear_flash(socket)}
      end

      defp add_flash_timer(socket, message_type, message) do
        Process.send_after(self(), :clear_flash, 3000)
        put_flash(socket, message_type, message)
      end

      defoverridable [validate_form: 1, format_errors: 1]
    end
  end
end
