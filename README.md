# TamedWilds

Tamed Wilds is a simple text-based online RPG. It is inspired by games like
Farm RPG and ARK: Survival Evolved. The aim is to create a game as fun
as ARK, but without requiring so much time to play.

This project is still in an early stage and not yet hosted on a public server.

Current features include:

- Exploring the wilds and gather resources
- Fighting creatures that you find during exploration
- Tame creatures to fight alongside you
    - Taming features a taming effectiveness mechanic similar to the one of ARK
- Level up your character and your creatures
    - The creatures leveling system is heavily inspired by the one of ARK which
      rewards finding the best possible wild creature to tame
- Camp with buildings
- Crafting system

## Planned Features

Some features that I plan to add:

- Multiple locations to explore
    - Each location features different creatures and resources
    - Locations may have unique features (e.g., underwater location with an
      oxygen mechanic, desert location with a hydration and heat stroke
      mechanic)
- Expand the camp
    - Add more buildings
        - Forge
        - Fields
        - ...
    - Make buildings require a certain character level or level of another
      building
    - Make building require time instead of being instant
- Expand character mechanics
    - Add equipment
    - Add crafting for equipment and finding blueprints
- Expand creature mechanics
    - More utilization of tamed creatures
        - Send your creatures to farm resources for you
        - Use creatures to help with all kinds of functions in your camp
        - Level up the bond to tamed creatures by exploring and fighting with
          them
        - Breeding and mutations
    - Herbivores/Carnivores
- Village
    - Quests
    - Professions that focus on different things
- More player interaction
    - Tribes
        - Tribe inventory to which tribe members can contribute
        - Tribe buildings that use items from tribe inventory
        - Tribe quests and events
        - Tribes get experience from players activities
        - Bonuses for tribe members based on tribe level
        - Competition with other tribes
    - Global Chat
    - Events and leaderboards
- All kinds of new game mechanics
    - Plant trees
        - Find seeds while exploring
    - Bees
        - Get bonuses based on the crops and trees at your camp

## Development

Tamed Wilds currently uses Phoenix and server-side renders HTML templates. This
provides an easy way to prototype and explore features. In the future, Phoenix
LiveView or Inertia may be used to make pages more interactive, without adding
too much complexity of an SPA, since this requires that the SPA has deep
knowledge about the game's mechanics.

To start the server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
