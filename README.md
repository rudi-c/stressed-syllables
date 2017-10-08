# Stressed Syllables

This is an application where you give it some English text, and it will tell you where the stressed syllables are.

The application is functional, but currently "pre-launch" (pending polishing and handling of a bunch more edge cases). This README will be updated with useful information soon.

## Setup

Assuming you have Elixir installed, and Postgres installed and running
(see Elixir & Phoenix [setup guide](https://hexdocs.pm/phoenix/up_and_running.html))

```
mix deps.get
cd assets && npm install && cd -
cd priv/spacy && ./setup.sh && cd -
```

and run with

```
mix phoenix.server
```