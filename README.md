# Stressed Syllables

This is an application where you give it some English text, and it will tell you where the stressed syllables are.

The application is functional, but currently "pre-launch" (pending polishing and handling of a bunch more edge cases). This README will be updated with useful information soon.

## Setup

Assuming you have Elixir, pip and virtualenv installed

```
mix deps.get
cd assets && npm install && cd -
cd priv/spacy && ./setup.sh && cd -
```

and run with

```
# Master
MASTER=true mix phx.server
# Replica
mix phx.server
```

## Type checking

Type checking can be done by running `mix dialyzer`. There may be some spurious warnings at the moment.

## Testing

Tests can be run with `mix test <file>`
