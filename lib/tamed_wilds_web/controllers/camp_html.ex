defmodule TamedWildsWeb.CampHTML do
  use TamedWildsWeb, :html

  alias TamedWilds.GameResources, as: Res

  attr :is_link, :boolean, required: true
  attr :href, :string, required: true
  slot :inner_block, required: true
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the link or div"

  def maybe_link(assigns) do
    ~H"""
    <%= if @is_link do %>
      <.link href={@href} {@rest}>
        <%= render_slot(@inner_block) %>
      </.link>
    <% else %>
      <div {@rest}>
        <%= render_slot(@inner_block) %>
      </div>
    <% end %>
    """
  end

  def route_for_building(building) do
    case building.res_id do
      1 -> ~p"/camp/stoneheart"
      2 -> ~p"/camp/campfire"
    end
  end

  embed_templates "camp_html/*"
end
