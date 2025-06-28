defmodule Blester.Repo do
  use AshPostgres.Repo, otp_app: :blester

  def min_pg_version do
    %Version{major: 12, minor: 0, patch: 0}
  end

  def installed_extensions do
    ["citext", "ash-functions"]
  end
end
