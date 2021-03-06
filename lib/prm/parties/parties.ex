defmodule PRM.Parties do
  @moduledoc """
  The boundary for the Parties system.
  """
  use PRM.Search

  import Ecto.{Query, Changeset}, warn: false

  alias PRM.Repo
  alias PRM.Parties.Party
  alias PRM.Parties.PartySearch
  alias PRM.Parties.PartyUser
  alias PRM.Parties.PartyUsersSearch
  alias PRM.Meta.Phone
  alias PRM.Meta.Document

  @fields_party ~W(
    first_name
    second_name
    last_name
    birth_date
    gender
    tax_id
    inserted_by
    updated_by
  )

  @fields_required_party ~W(
    first_name
    last_name
    birth_date
    gender
    tax_id
    inserted_by
    updated_by
  )a

  def list_parties(params) do
    %PartySearch{}
    |> party_changeset(params)
    |> search(params, Party, 50)
    |> preload_users()
  end

  def get_search_query(Party = entity, %{phone_number: number} = changes) do
    params =
      changes
      |> Map.delete(:phone_number)
      |> Map.to_list()

    phone_number = [%{"number" => number}]

    from e in entity,
      where: ^params,
      where: fragment("? @> ?", e.phones, ^phone_number)
  end

  def get_search_query(entity, changes), do: super(entity, changes)

  def get_party!(id), do: Party |> Repo.get!(id) |> Repo.preload(:users)

  def create_party(attrs \\ %{}, user_id) do
    %Party{}
    |> party_changeset(attrs)
    |> Repo.insert_and_log(user_id)
    |> preload_users()
  end

  def update_party(%Party{} = party, attrs, user_id) do
    party
    |> party_changeset(attrs)
    |> Repo.update_and_log(user_id)
    |> preload_users()
  end

  defp preload_users({:ok, party}), do: {:ok, Repo.preload(party, :users)}
  defp preload_users({:error, _} = error), do: error
  defp preload_users({parties, paging}), do: {Repo.preload(parties, :users), paging}
  defp preload_users(err), do: err

  def change_party(%Party{} = party) do
    party_changeset(party, %{})
  end

  defp party_changeset(%PartySearch{} = party, attrs) do
    fields =  ~W(
      first_name
      second_name
      last_name
      birth_date
      tax_id
      phone_number
    )
    cast(party, attrs, fields)
  end

  defp party_changeset(%Party{} = party, attrs) do
    party
    |> cast(attrs, @fields_party)
    |> cast_embed(:documents, with: &Document.changeset/2)
    |> cast_embed(:phones, with: &Phone.changeset/2)
    |> validate_required(@fields_required_party)
  end

  def list_party_users(params) do
    %PartyUsersSearch{}
    |> party_user_changeset(params)
    |> search(params, PartyUser, 50)
  end

  def get_party_user!(id), do: Repo.get!(PartyUser, id)

  def create_party_user(attrs \\ %{}, user_id) do
    %PartyUser{}
    |> party_user_changeset(attrs)
    |> Repo.insert_and_log(user_id)
  end

  def update_party_user(%PartyUser{} = party_user, attrs, user_id) do
    party_user
    |> party_user_changeset(attrs)
    |> Repo.update_and_log(user_id)
  end

  def change_party_user(%PartyUser{} = party_user) do
    party_user_changeset(party_user, %{})
  end

  defp party_user_changeset(%PartyUser{} = party_user, attrs) do
    fields = ~W(
      user_id
      party_id
    )a

    party_user
    |> cast(attrs, fields)
    |> validate_required(fields)
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:party_id)
  end

  defp party_user_changeset(%PartyUsersSearch{} = party, attrs) do
    fields = ~W(
      user_id
      party_id
    )
    cast(party, attrs, fields)
  end
end
