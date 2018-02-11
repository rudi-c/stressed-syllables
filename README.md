# Stressed Syllables

This is an application where you give it some English text, and it will tell you where the stressed syllables are. This is meant to be a convenient tool for non-native speakers to learn this subtle aspect of the English language. It's also helpful for both native and non-native speakers to prepare for presentations, as proper articulation of stressed syllables can make a speech sound more eloquent.

This uses the **Phoenix Framework** in **Elixir** to serve requests by getting data from Merriam-Webster, and using a bit of NLP with the **Spacy** library to improve result quality.

The `pre-mnesia` branch is currently deployed at [stressedsyllables.com](http://stressedsyllables.com)

## Setup

Assuming you have Elixir, Phoenix, pip and virtualenv installed

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

## Implementation details

- Data is obtained by scraping Merriam-Webster for stress information for every word in the user's request.
- We need to get the part-of-speech of the word, inferred from the sentence using NLP, to choose the correct definition from the Merriam-Webster (some words in English will have different stresses depending on whether it's a noun or a verb, such as **con**duct vs con**duct**).
- There's a separate Python process running to do the NLP, and an Elixir process wraps the Python process.
- The application can run on multiple servers using a master-replica transaction log model. New words are always written to master, which sends a feed of updates to the replicas' caches. If a new replica connects, it'll request the entire state from master.
- The cache is persisted to disk as a transaction log in plain text, and read by master on startup.
- Requests are always received by master, but the word to process words and scrape Merriam-Webster is done by both the master and replicas in a round-robin fashion.

## Project status

The application is currently functional for personal use, though not quite ready as actual "product". I worked on this as a side-project to learn Elixir and because I wanted to have it to help fine-tune presentations, but I don't have the motivation to finish it right now. My day-to-day job have been more focused on front-end and graphics, I'll probably get back to this when I do more backend.

Main things to do include:
- Various code quality cleanup/use proper Elixir practices (e.g. name processes, putting GenServer initialization logic in `init` instead of `start_link`, etc)
- Finish using Mnesia instead of plaintext for data persistence
- Supervisors and other things to make the application robust against failures
- Consider switching over to Dictionary.com, their data seems better than Merriam-Webster
- Provide time estimates for request completion using WebSockets -- this application can't handle large loads right now since it's limited by how many requests I can send at once to Merriam-Webster without getting rate-limited
