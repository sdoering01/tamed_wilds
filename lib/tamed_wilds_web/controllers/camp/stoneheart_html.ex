defmodule TamedWildsWeb.Camp.StoneheartHTML do
  use TamedWildsWeb, :html

  alias TamedWilds.GameResources, as: Res
  alias TamedWilds.Creatures.{Creature, CreatureLevel}

  embed_templates "stoneheart_html/*"
end
